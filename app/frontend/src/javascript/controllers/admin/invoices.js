/* eslint-disable
    handle-callback-err,
    no-return-assign,
    no-undef,
    no-useless-escape,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

/**
 * Controller used in the admin invoices listing page
 */
Application.Controllers.controller('InvoicesController', ['$scope', '$state', 'Invoice', 'AccountingPeriod', 'AuthService', 'invoices', 'closedPeriods', '$uibModal', 'growl', '$filter', 'Setting', 'settings', 'stripeSecretKey', '_t', 'Member', 'uiTourService', 'Payment', 'onlinePaymentStatus',
  function ($scope, $state, Invoice, AccountingPeriod, AuthService, invoices, closedPeriods, $uibModal, growl, $filter, Setting, settings, stripeSecretKey, _t, Member, uiTourService, Payment, onlinePaymentStatus) {
  /* PRIVATE STATIC CONSTANTS */

    // number of invoices loaded each time we click on 'load more...'
    const INVOICES_PER_PAGE = 20;

    // fake stripe secret key
    const STRIPE_SK_HIDDEN = 'sk_test_hidden-hidden-hidden-hid';

    /* PUBLIC SCOPE */

    // default active tab
    $scope.tabs = {
      active: settings.invoicing_module === 'true' ? 0 : 1
    };

    // List of all invoices
    $scope.invoices = invoices;

    // Invoices filters
    $scope.searchInvoice = {
      date: null,
      name: '',
      reference: ''
    };

    // currently displayed page of invoices (search results)
    $scope.page = 1;

    // true when all invoices are loaded
    $scope.noMoreResults = false;

    // Default invoices ordering/sorting
    $scope.orderInvoice = '-reference';

    // Invoice PDF filename settings (and example)
    $scope.file = {
      prefix: settings.invoice_prefix,
      nextId: 40,
      date: moment().format('DDMMYYYY'),
      templateUrl: '/admin/invoices/settings/editPrefix.html'
    };

    // Invoices parameters
    $scope.invoice = {
      logo: null,
      reference: {
        model: '',
        help: null,
        templateUrl: '/admin/invoices/settings/editReference.html'
      },
      code: {
        model: '',
        active: true,
        templateUrl: '/admin/invoices/settings/editCode.html'
      },
      number: {
        model: '',
        help: null,
        templateUrl: '/admin/invoices/settings/editNumber.html'
      },
      VAT: {
        rate: 19.6,
        active: false,
        templateUrl: '/admin/invoices/settings/editVAT.html'
      },
      text: {
        content: ''
      },
      legals: {
        content: ''
      }
    };

    // Accounting codes
    $scope.settings = {
      journalCode: {
        name: 'accounting_journal_code',
        value: settings.accounting_journal_code
      },
      cardClientCode: {
        name: 'accounting_card_client_code',
        value: settings.accounting_card_client_code
      },
      cardClientLabel: {
        name: 'accounting_card_client_label',
        value: settings.accounting_card_client_label
      },
      walletClientCode: {
        name: 'accounting_wallet_client_code',
        value: settings.accounting_wallet_client_code
      },
      walletClientLabel: {
        name: 'accounting_wallet_client_label',
        value: settings.accounting_wallet_client_label
      },
      otherClientCode: {
        name: 'accounting_other_client_code',
        value: settings.accounting_other_client_code
      },
      otherClientLabel: {
        name: 'accounting_other_client_label',
        value: settings.accounting_other_client_label
      },
      walletCode: {
        name: 'accounting_wallet_code',
        value: settings.accounting_wallet_code
      },
      walletLabel: {
        name: 'accounting_wallet_label',
        value: settings.accounting_wallet_label
      },
      vatCode: {
        name: 'accounting_VAT_code',
        value: settings.accounting_VAT_code
      },
      vatLabel: {
        name: 'accounting_VAT_label',
        value: settings.accounting_VAT_label
      },
      subscriptionCode: {
        name: 'accounting_subscription_code',
        value: settings.accounting_subscription_code
      },
      subscriptionLabel: {
        name: 'accounting_subscription_label',
        value: settings.accounting_subscription_label
      },
      machineCode: {
        name: 'accounting_Machine_code',
        value: settings.accounting_Machine_code
      },
      machineLabel: {
        name: 'accounting_Machine_label',
        value: settings.accounting_Machine_label
      },
      trainingCode: {
        name: 'accounting_Training_code',
        value: settings.accounting_Training_code
      },
      trainingLabel: {
        name: 'accounting_Training_label',
        value: settings.accounting_Training_label
      },
      eventCode: {
        name: 'accounting_Event_code',
        value: settings.accounting_Event_code
      },
      eventLabel: {
        name: 'accounting_Event_label',
        value: settings.accounting_Event_label
      },
      spaceCode: {
        name: 'accounting_Space_code',
        value: settings.accounting_Space_code
      },
      spaceLabel: {
        name: 'accounting_Space_label',
        value: settings.accounting_Space_label
      }
    };

    // all settings
    $scope.allSettings = settings;

    // is the stripe private set?
    $scope.stripeSecretKey = (stripeSecretKey.isPresent ? STRIPE_SK_HIDDEN : '');

    // has any online payment been already made?
    $scope.onlinePaymentStatus = onlinePaymentStatus.status;

    // Placeholding date for the invoice creation
    $scope.today = moment();

    // Placeholding date for the reservation begin
    $scope.inOneWeek = moment().add(1, 'week').startOf('hour');

    // Placeholding date for the reservation end
    $scope.inOneWeekAndOneHour = moment().add(1, 'week').add(1, 'hour').startOf('hour');

    // Is shown the modal dialog to select a payment gateway
    $scope.openSelectGatewayModal = false;

    /**
     * Change the invoices ordering criterion to the one provided
     * @param orderBy {string} ordering criterion
     */
    $scope.setOrderInvoice = function (orderBy) {
      if ($scope.orderInvoice === orderBy) {
        $scope.orderInvoice = `-${orderBy}`;
      } else {
        $scope.orderInvoice = orderBy;
      }

      resetSearchInvoice();
      return invoiceSearch();
    };

    /**
     * Open a modal window asking the admin the details to refund the user about the provided invoice
     * @param invoice {Object} invoice inherited from angular's $resource
     */
    $scope.generateAvoirForInvoice = function (invoice) {
      // open modal
      const modalInstance = $uibModal.open({
        templateUrl: '/admin/invoices/avoirModal.html',
        controller: 'AvoirModalController',
        resolve: {
          invoice () { return invoice; },
          closedPeriods () { return AccountingPeriod.query().$promise; },
          lastClosingEnd () { return AccountingPeriod.lastClosingEnd().$promise; }
        }
      });

      // once done, update the invoice model and inform the admin
      return modalInstance.result.then(function (res) {
        $scope.invoices.unshift(res.avoir);
        return Invoice.get({ id: invoice.id }, function (data) {
          invoice.has_avoir = data.has_avoir;
          return growl.success(_t('app.admin.invoices.refund_invoice_successfully_created'));
        });
      });
    };

    /**
     * Generate an invoice reference sample from the parametrized model
     * @returns {string} invoice reference sample
     */
    $scope.mkReference = function () {
      let sample = $scope.invoice.reference.model;
      if (sample) {
      // invoice number per day (dd..dd)
        sample = sample.replace(/d+(?![^\[]*])/g, function (match, offset, string) { return padWithZeros(2, match.length); });
        // invoice number per month (mm..mm)
        sample = sample.replace(/m+(?![^\[]*])/g, function (match, offset, string) { return padWithZeros(12, match.length); });
        // invoice number per year (yy..yy)
        sample = sample.replace(/y+(?![^\[]*])/g, function (match, offset, string) { return padWithZeros(8, match.length); });
        // date information
        sample = sample.replace(/[YMD]+(?![^\[]*])/g, function (match, offset, string) { return $scope.today.format(match); });
        // information about online selling (X[text])
        sample = sample.replace(/X\[([^\]]+)\]/g, function (match, p1, offset, string) { return p1; });
        // information about wallet (W[text]) - does not apply here
        sample = sample.replace(/W\[([^\]]+)\]/g, '');
        // information about refunds (R[text]) - does not apply here
        sample = sample.replace(/R\[([^\]]+)\]/g, '');
        // information about payment schedules (S[text]) -does not apply here
        sample = sample.replace(/S\[([^\]]+)\]/g, '');
      }
      return sample;
    };

    /**
     * Generate an order number sample from the parametrized model
     * @returns {string} invoice reference sample
     */
    $scope.mkNumber = function () {
      let sample = $scope.invoice.number.model;
      if (sample) {
      // global order number (nn..nn)
        sample = sample.replace(/n+(?![^\[]*])/g, function (match, offset, string) { return padWithZeros(327, match.length); });
        // order number per year (yy..yy)
        sample = sample.replace(/y+(?![^\[]*])/g, function (match, offset, string) { return padWithZeros(8, match.length); });
        // order number per month (mm..mm)
        sample = sample.replace(/m+(?![^\[]*])/g, function (match, offset, string) { return padWithZeros(12, match.length); });
        // order number per day (dd..dd)
        sample = sample.replace(/d+(?![^\[]*])/g, function (match, offset, string) { return padWithZeros(2, match.length); });
        // date information
        sample = sample.replace(/[YMD]+(?![^\[]*])/g, function (match, offset, string) { return $scope.today.format(match); });
      }
      return sample;
    };

    /**
     * Open a modal dialog allowing the user to edit the invoice reference generation template
     */
    $scope.openEditReference = function () {
      const modalInstance = $uibModal.open({
        animation: true,
        templateUrl: $scope.invoice.reference.templateUrl,
        size: 'lg',
        resolve: {
          model () {
            return $scope.invoice.reference.model;
          }
        },
        controller: ['$scope', '$uibModalInstance', 'model', function ($scope, $uibModalInstance, model) {
          $scope.model = model;
          $scope.ok = function () { $uibModalInstance.close($scope.model); };
          $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };
        }]
      });

      modalInstance.result.then(function (model) {
        Setting.update({ name: 'invoice_reference' }, { value: model }, function (data) {
          $scope.invoice.reference.model = model;
          growl.success(_t('app.admin.invoices.invoice_reference_successfully_saved'));
        }
        , function (error) {
          if (error.status === 304) return;

          growl.error(_t('app.admin.invoices.an_error_occurred_while_saving_invoice_reference'));
          console.error(error);
        });
      });
    };

    /**
     * Open a modal dialog allowing the user to edit the invoice code
     */
    $scope.openEditCode = function () {
      const modalInstance = $uibModal.open({
        animation: true,
        templateUrl: $scope.invoice.code.templateUrl,
        size: 'lg',
        resolve: {
          model () {
            return $scope.invoice.code.model;
          },
          active () {
            return $scope.invoice.code.active;
          }
        },
        controller: ['$scope', '$uibModalInstance', 'model', 'active', function ($scope, $uibModalInstance, model, active) {
          $scope.codeModel = model;
          $scope.isSelected = active;

          $scope.ok = function () { $uibModalInstance.close({ model: $scope.codeModel, active: $scope.isSelected }); };
          $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };
        }]
      });

      return modalInstance.result.then(function (result) {
        Setting.update({ name: 'invoice_code-value' }, { value: result.model }, function (data) {
          $scope.invoice.code.model = result.model;
          if (result.active) {
            return growl.success(_t('app.admin.invoices.invoicing_code_succesfully_saved'));
          }
        }
        , function (error) {
          if (error.status === 304) return;

          growl.error(_t('app.admin.invoices.an_error_occurred_while_saving_the_invoicing_code'));
          console.error(error);
        });

        return Setting.update({ name: 'invoice_code-active' }, { value: result.active ? 'true' : 'false' }, function (data) {
          $scope.invoice.code.active = result.active;
          if (result.active) {
            return growl.success(_t('app.admin.invoices.code_successfully_activated'));
          } else {
            return growl.success(_t('app.admin.invoices.code_successfully_disabled'));
          }
        }
        , function (error) {
          if (error.status === 304) return;

          growl.error(_t('app.admin.invoices.an_error_occurred_while_activating_the_invoicing_code'));
          console.error(error);
        });
      });
    };

    /**
     * Open a modal dialog allowing the user to edit the invoice number
     */
    $scope.openEditInvoiceNb = function () {
      const modalInstance = $uibModal.open({
        animation: true,
        templateUrl: $scope.invoice.number.templateUrl,
        size: 'lg',
        resolve: {
          model () {
            return $scope.invoice.number.model;
          }
        },
        controller: ['$scope', '$uibModalInstance', 'model', function ($scope, $uibModalInstance, model) {
          $scope.model = model;
          $scope.ok = function () { $uibModalInstance.close($scope.model); };
          $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };
        }]
      });

      return modalInstance.result.then(function (model) {
        Setting.update({ name: 'invoice_order-nb' }, { value: model }, function (data) {
          $scope.invoice.number.model = model;
          return growl.success(_t('app.admin.invoices.order_number_successfully_saved'));
        }
        , function (error) {
          if (error.status === 304) return;

          growl.error(_t('app.admin.invoices.an_error_occurred_while_saving_the_order_number'));
          console.error(error);
        });
      });
    };

    /**
     * Open a modal dialog allowing the user to edit the VAT parameters for the invoices
     * The VAT can be disabled and its rate can be configured
     */
    $scope.openEditVAT = function () {
      const modalInstance = $uibModal.open({
        animation: true,
        templateUrl: $scope.invoice.VAT.templateUrl,
        size: 'lg',
        resolve: {
          rate () {
            return $scope.invoice.VAT.rate;
          },
          active () {
            return $scope.invoice.VAT.active;
          },
          rateHistory () {
            return Setting.get({ name: 'invoice_VAT-rate', history: true }).$promise;
          },
          activeHistory () {
            return Setting.get({ name: 'invoice_VAT-active', history: true }).$promise;
          }
        },
        controller: ['$scope', '$uibModalInstance', 'rate', 'active', 'rateHistory', 'activeHistory', function ($scope, $uibModalInstance, rate, active, rateHistory, activeHistory) {
          $scope.rate = rate;
          $scope.isSelected = active;
          $scope.history = [];

          $scope.ok = function () { $uibModalInstance.close({ rate: $scope.rate, active: $scope.isSelected }); };
          $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };

          const initialize = function () {
            rateHistory.setting.history.forEach(function (rate) {
              $scope.history.push({ date: rate.created_at, rate: rate.value, user: rate.user });
            });
            activeHistory.setting.history.forEach(function (v) {
              $scope.history.push({ date: v.created_at, enabled: v.value === 'true', user: v.user });
            });
          };

          initialize();
        }]
      });

      return modalInstance.result.then(function (result) {
        Setting.update({ name: 'invoice_VAT-rate' }, { value: result.rate + '' }, function (data) {
          $scope.invoice.VAT.rate = result.rate;
          if (result.active) {
            return growl.success(_t('app.admin.invoices.VAT_rate_successfully_saved'));
          }
        }
        , function (error) {
          if (error.status === 304) return;

          growl.error(_t('app.admin.invoices.an_error_occurred_while_saving_the_VAT_rate'));
          console.error(error);
        });

        return Setting.update({ name: 'invoice_VAT-active' }, { value: result.active ? 'true' : 'false' }, function (data) {
          $scope.invoice.VAT.active = result.active;
          if (result.active) {
            return growl.success(_t('app.admin.invoices.VAT_successfully_activated'));
          } else {
            return growl.success(_t('app.admin.invoices.VAT_successfully_disabled'));
          }
        }
        , function (error) {
          if (error.status === 304) return;

          growl.error(_t('app.admin.invoices.an_error_occurred_while_activating_the_VAT'));
          console.error(error);
        });
      });
    };

    /**
     * Open a modal dialog allowing the user to edit the prefix of the invoice file name
     */
    $scope.openEditPrefix = function () {
      const modalInstance = $uibModal.open({
        animation: true,
        templateUrl: $scope.file.templateUrl,
        size: 'lg',
        resolve: {
          model () { return $scope.file.prefix; }
        },
        controller: ['$scope', '$uibModalInstance', 'model', function ($scope, $uibModalInstance, model) {
          $scope.model = model;
          $scope.ok = function () { $uibModalInstance.close($scope.model); };
          $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };
        }]
      });

      return modalInstance.result.then(function (model) {
        Setting.update({ name: 'invoice_prefix' }, { value: model }, function (data) {
          $scope.file.prefix = model;
          return growl.success(_t('app.admin.invoices.prefix_successfully_saved'));
        }
        , function (error) {
          if (error.status === 304) return;

          growl.error(_t('app.admin.invoices.an_error_occurred_while_saving_the_prefix'));
          console.error(error);
        });
      });
    };

    /**
     * Callback to save the value of the text zone when editing is done
     */
    $scope.textEditEnd = function (event) {
      const parsed = parseHtml($scope.invoice.text.content);
      return Setting.update({ name: 'invoice_text' }, { value: parsed }, function (data) {
        $scope.invoice.text.content = parsed;
        return growl.success(_t('app.admin.invoices.text_successfully_saved'));
      }
      , function (error) {
        if (error.status === 304) return;

        growl.error(_t('app.admin.invoices.an_error_occurred_while_saving_the_text'));
        console.error(error);
      });
    };

    /**
     * Callback to save the value of the legal information zone when editing is done
     */
    $scope.legalsEditEnd = function (event) {
      const parsed = parseHtml($scope.invoice.legals.content);
      return Setting.update({ name: 'invoice_legals' }, { value: parsed }, function (data) {
        $scope.invoice.legals.content = parsed;
        return growl.success(_t('app.admin.invoices.address_and_legal_information_successfully_saved'));
      }
      , function (error) {
        if (error.status === 304) return;

        growl.error(_t('app.admin.invoices.an_error_occurred_while_saving_the_address_and_the_legal_information'));
        console.error(error);
      });
    };

    /**
     * Callback when any of the filters changes.
     * Full reload the results list
     */
    $scope.handleFilterChange = function () {
      if (searchTimeout) clearTimeout(searchTimeout);
      searchTimeout = setTimeout(function () {
        resetSearchInvoice();
        invoiceSearch();
      }, 300);
    };

    /**
     * Callback for the 'load more' button.
     * Will load the next results of the current search, if any
     */
    $scope.showNextInvoices = function () {
      $scope.page += 1;
      invoiceSearch(true);
    };

    /**
     * Open a modal allowing the user to close an accounting period and to
     * view all periods already closed.
     */
    $scope.closeAnAccountingPeriod = function () {
      // open modal
      $uibModal.open({
        templateUrl: '/admin/invoices/closePeriodModal.html',
        controller: 'ClosePeriodModalController',
        backdrop: 'static',
        keyboard: false,
        size: 'lg',
        resolve: {
          periods () { return AccountingPeriod.query().$promise; },
          lastClosingEnd () { return AccountingPeriod.lastClosingEnd().$promise; }
        }
      });
    };

    $scope.toggleExportModal = function () {
      $uibModal.open({
        templateUrl: '/admin/invoices/accountingExportModal.html',
        controller: 'AccountingExportModalController',
        size: 'xl'
      });
    };

    /**
     * Test if the given date is within a closed accounting period
     * @param date {Date} date to test
     * @returns {boolean} true if closed, false otherwise
     */
    $scope.isDateClosed = function (date) {
      for (const period of closedPeriods) {
        if (moment(date).isBetween(moment.utc(period.start_at).startOf('day'), moment.utc(period.end_at).endOf('day'), null, '[]')) {
          return true;
        }
      }
      return false;
    };

    /**
     * Callback to bulk save all settings in the page to the database with their values
     */
    $scope.save = function () {
      Setting.bulkUpdate(
        { settings: Object.values($scope.settings) },
        function () { growl.success(_t('app.admin.invoices.codes_customization_success')); },
        function (error) {
          growl.error('app.admin.invoices.unexpected_error_occurred');
          console.error(error);
        }
      );
    };

    /**
     * Return the name of the operator that creates the invoice
     */
    $scope.operatorName = function (invoice) {
      if (!invoice.operator) return '';

      return `${invoice.operator.first_name} ${invoice.operator.last_name}`;
    };

    /**
     * Open a modal dialog which ask the user to select the payment gateway to use
     * @param onlinePaymentModule {{name: String, value: String}} setting that defines the next status of the online payment module
     */
    $scope.selectPaymentGateway = function (onlinePaymentModule) {
      // if the online payment is about to be disabled, accept the change without any further question
      if (onlinePaymentModule.value === false) return true;

      // otherwise, open a modal to ask for the selection of a payment gateway
      setTimeout(() => {
        $scope.openSelectGatewayModal = true;
        $scope.$apply();
      }, 50);
      return new Promise(function (resolve, reject) {
        gatewayHandlers.resolve = resolve;
        gatewayHandlers.reject = reject;
      }).catch(() => { /* WORKAROUND: it seems we can't catch the rejection from the boolean-setting directive */ });
    };

    /**
     * This will open/close the gateway selection modal
     */
    $scope.toggleSelectGatewayModal = function () {
      setTimeout(() => {
        $scope.openSelectGatewayModal = !$scope.openSelectGatewayModal;
        $scope.$apply();
        if (!$scope.openSelectGatewayModal && gatewayHandlers.reject) {
          gatewayHandlers.reject();
          resetPromiseHandlers();
        }
      }, 50);
    };

    /**
     * Callback triggered after the gateway was successfully configured in the dedicated modal
     */
    $scope.onGatewayModalSuccess = function (updatedSettings) {
      if (gatewayHandlers.resolve) {
        gatewayHandlers.resolve(true);
        resetPromiseHandlers();
      }

      $scope.toggleSelectGatewayModal();
      $scope.allSettings.payment_gateway = updatedSettings.get('payment_gateway').value;
      if ($scope.allSettings.payment_gateway === 'stripe') {
        $scope.allSettings.stripe_public_key = updatedSettings.get('stripe_public_key').value;
        Setting.isPresent({ name: 'stripe_secret_key' }, function (res) {
          $scope.stripeSecretKey = (res.isPresent ? STRIPE_SK_HIDDEN : '');
        });
        Payment.onlinePaymentStatus(function (res) {
          $scope.onlinePaymentStatus = res.status;
        });
      }
    };

    /**
     * Callback triggered after the gateway failed to be configured
     */
    $scope.onGatewayModalError = function (errors) {
      growl.error(_t('app.admin.invoices.payment.gateway_configuration_error'));
      console.error(errors);
    };

    /**
     * Callback triggered when the PayZen currency was successfully updated
     */
    $scope.alertPayZenCurrencyUpdated = function (currency) {
      growl.success(_t('app.admin.invoices.payment.payzen.currency_updated', { CURRENCY: currency }));
    };

    /**
     * Setup the feature-tour for the admin/invoices page.
     * This is intended as a contextual help (when pressing F1)
     */
    $scope.setupInvoicesTour = function () {
      // get the tour defined by the ui-tour directive
      const uitour = uiTourService.getTourByName('invoices');
      if (AuthService.isAuthorized('admin')) {
        uitour.createStep({
          selector: 'body',
          stepId: 'welcome',
          order: 0,
          title: _t('app.admin.tour.invoices.welcome.title'),
          content: _t('app.admin.tour.invoices.welcome.content'),
          placement: 'bottom',
          orphan: true
        });
      } else {
        uitour.createStep({
          selector: 'body',
          stepId: 'welcome_manager',
          order: 0,
          title: _t('app.admin.tour.invoices.welcome_manager.title'),
          content: _t('app.admin.tour.invoices.welcome_manager.content'),
          placement: 'bottom',
          orphan: true
        });
      }
      if (settings.invoicing_module === 'true' && $scope.invoices.length > 0) {
        uitour.createStep({
          selector: '.invoices-management .invoices-list',
          stepId: 'list',
          order: 1,
          title: _t('app.admin.tour.invoices.list.title'),
          content: _t('app.admin.tour.invoices.list.content'),
          placement: 'top'
        });
        uitour.createStep({
          selector: '.invoices-management .invoices-list .chained-indicator',
          stepId: 'chained',
          order: 2,
          title: _t('app.admin.tour.invoices.chained.title'),
          content: _t('app.admin.tour.invoices.chained.content'),
          placement: 'right'
        });
        uitour.createStep({
          selector: '.invoices-management .invoices-list .download-button',
          stepId: 'download',
          order: 3,
          title: _t('app.admin.tour.invoices.download.title'),
          content: _t('app.admin.tour.invoices.download.content'),
          placement: 'left'
        });
        uitour.createStep({
          selector: '.invoices-management .invoices-list .refund-button',
          stepId: 'refund',
          order: 4,
          title: _t('app.admin.tour.invoices.refund.title'),
          content: _t('app.admin.tour.invoices.refund.content'),
          placement: 'left'
        });
      }
      if (settings.invoicing_module === 'true') {
        uitour.createStep({
          selector: '.invoices-management .payment-schedules-list',
          stepId: 'payment-schedules',
          order: 5,
          title: _t('app.admin.tour.invoices.payment-schedules.title'),
          content: _t('app.admin.tour.invoices.payment-schedules.content'),
          placement: 'bottom'
        });
      }
      if (AuthService.isAuthorized('admin')) {
        uitour.createStep({
          selector: '.invoices-management .invoices-settings',
          stepId: 'settings',
          order: 6,
          title: _t('app.admin.tour.invoices.settings.title'),
          content: _t('app.admin.tour.invoices.settings.content'),
          placement: 'bottom'
        });
        uitour.createStep({
          selector: '.invoices-management .accounting-codes-tab',
          stepId: 'codes',
          order: 7,
          title: _t('app.admin.tour.invoices.codes.title'),
          content: _t('app.admin.tour.invoices.codes.content'),
          placement: 'bottom'
        });
        uitour.createStep({
          selector: '.heading .export-accounting-button',
          stepId: 'export',
          order: 8,
          title: _t('app.admin.tour.invoices.export.title'),
          content: _t('app.admin.tour.invoices.export.content'),
          placement: 'bottom'
        });
        uitour.createStep({
          selector: '.invoices-management .payment-settings',
          stepId: 'payment',
          order: 9,
          title: _t('app.admin.tour.invoices.payment.title'),
          content: _t('app.admin.tour.invoices.payment.content'),
          placement: 'bottom',
          popupClass: 'shift-left-50'
        });
        uitour.createStep({
          selector: '.heading .close-accounting-periods-button',
          stepId: 'periods',
          order: 10,
          title: _t('app.admin.tour.invoices.periods.title'),
          content: _t('app.admin.tour.invoices.periods.content'),
          placement: 'bottom',
          popupClass: 'shift-left-50'
        });
      }
      uitour.createStep({
        selector: 'body',
        stepId: 'conclusion',
        order: 11,
        title: _t('app.admin.tour.conclusion.title'),
        content: _t('app.admin.tour.conclusion.content'),
        placement: 'bottom',
        orphan: true
      });
      // on step change, change the active tab if needed
      uitour.on('stepChanged', function (nextStep) {
        if (nextStep.stepId === 'list' || nextStep.stepId === 'refund') {
          $scope.tabs.active = 0;
        }
        if (nextStep.stepId === 'settings') {
          $scope.tabs.active = 1;
        }
        if (nextStep.stepId === 'codes' || nextStep.stepId === 'export') {
          $scope.tabs.active = 2;
        }
        if (nextStep.stepId === 'payment') {
          $scope.tabs.active = 3;
        }
        if (nextStep.stepId === 'payment-schedules') {
          $scope.tabs.active = 4;
        }
      });
      // on tour end, save the status in database
      uitour.on('ended', function () {
        if (uitour.getStatus() === uitour.Status.ON && $scope.currentUser.profile.tours.indexOf('invoices') < 0) {
          Member.completeTour({ id: $scope.currentUser.id }, { tour: 'invoices' }, function (res) {
            $scope.currentUser.profile.tours = res.tours;
          });
        }
      });
      // if the user has never seen the tour, show him now
      if (settings.feature_tour_display !== 'manual' && $scope.currentUser.profile.tours.indexOf('invoices') < 0) {
        uitour.start();
      }
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      if (!invoices[0] || (invoices[0].maxInvoices <= $scope.invoices.length)) {
        $scope.noMoreResults = true;
      }

      // retrieve settings from the DB through the API
      $scope.invoice.legals.content = settings.invoice_legals;
      $scope.invoice.text.content = settings.invoice_text;
      $scope.invoice.VAT.rate = parseFloat(settings['invoice_VAT-rate']);
      $scope.invoice.VAT.active = (settings['invoice_VAT-active'] === 'true');
      $scope.invoice.number.model = settings['invoice_order-nb'];
      $scope.invoice.code.model = settings['invoice_code-value'];
      $scope.invoice.code.active = (settings['invoice_code-active'] === 'true');
      $scope.invoice.reference.model = settings.invoice_reference;
      $scope.invoice.logo = {
        filetype: 'image/png',
        filename: 'logo.png',
        base64: settings.invoice_logo
      };

      // Watch the logo, when a change occurs, save it
      $scope.$watch('invoice.logo', function () {
        if ($scope.invoice.logo && $scope.invoice.logo.filesize) {
          return Setting.update(
            { name: 'invoice_logo' },
            { value: $scope.invoice.logo.base64 },
            function (data) { growl.success(_t('app.admin.invoices.logo_successfully_saved')); },
            function (error) {
              if (error.status === 304) return;

              growl.error(_t('app.admin.invoices.an_error_occurred_while_saving_the_logo'));
              console.error(error);
            }
          );
        }
      });

      // Clean before the controller is destroyed
      $scope.$on('$destroy', function () {
        if (gatewayHandlers.reject) {
          gatewayHandlers.reject();
          resetPromiseHandlers();
        }
      });
    };

    /**
     * Will temporize the search query to prevent overloading the API
     */
    let searchTimeout = null;

    /**
     * We must delay the save of the 'payment gateway' parameter, until the gateway is configured.
     * To do so, we use a promise, with the resolve/reject callback stored here
     * @see https://stackoverflow.com/q/26150232
     */
    const gatewayHandlers = {
      resolve: null,
      reject: null
    };

    /**
     * Output the given integer with leading zeros. If the given value is longer than the given
     * length, it will be truncated.
     * @param value {number} the integer to pad
     * @param length {number} the length of the resulting string.
     */
    const padWithZeros = function (value, length) { return (1e15 + value + '').slice(-length); };

    /**
     * Reset the promise handlers (reject/resolve) to their initial value.
     * This will prevent an already resolved promise to be triggered again.
     */
    const resetPromiseHandlers = function () {
      gatewayHandlers.resolve = null;
      gatewayHandlers.reject = null;
    };

    /**
     * Remove every unsupported html tag from the given html text (like <p>, <span>, ...).
     * The supported tags are <b>, <u>, <i> and <br>.
     * @param html {string} single line html text
     * @return {string} multi line simplified html text
     */
    const parseHtml = function (html) {
      return html.replace(/<\/?(\w+)((\s+\w+(\s*=\s*(?:".*?"|'.*?'|[^'">\s]+))?)+\s*|\s*)\/?>/g, function (match, p1, offset, string) {
        if (['b', 'u', 'i', 'br'].includes(p1)) {
          return match;
        } else {
          return '';
        }
      });
    };

    /**
     * Reinitialize the context of invoices' search to display new results set
     */
    const resetSearchInvoice = function () {
      $scope.page = 1;
      return $scope.noMoreResults = false;
    };

    /**
     * Run a search query with the current parameters set concerning invoices, then affect or concat the results
     * to $scope.invoices
     * @param [concat] {boolean} if true, the result will be append to $scope.invoices instead of being affected
     */
    const invoiceSearch = function (concat) {
      Invoice.list({
        query: {
          number: $scope.searchInvoice.reference,
          customer: $scope.searchInvoice.name,
          date: $scope.searchInvoice.date,
          order_by: $scope.orderInvoice,
          page: $scope.page,
          size: INVOICES_PER_PAGE
        }
      }, function (invoices) {
        if (concat) {
          $scope.invoices = $scope.invoices.concat(invoices);
        } else {
          $scope.invoices = invoices;
        }

        if (!invoices[0] || (invoices[0].maxInvoices <= $scope.invoices.length)) {
          return $scope.noMoreResults = true;
        }
      });
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

/**
 * Controller used in the invoice refunding modal window
 */
Application.Controllers.controller('AvoirModalController', ['$scope', '$uibModalInstance', 'invoice', 'closedPeriods', 'lastClosingEnd', 'Invoice', 'growl', '_t',
  function ($scope, $uibModalInstance, invoice, closedPeriods, lastClosingEnd, Invoice, growl, _t) {
    /* PUBLIC SCOPE */

    // invoice linked to the current refund
    $scope.invoice = invoice;

    // Associative array containing invoice_item ids associated with boolean values
    $scope.partial = {};

    // Default refund parameters
    $scope.avoir = {
      invoice_id: invoice.id,
      subscription_to_expire: false,
      invoice_items_ids: []
    };

    // End date of last closed accounting period or date of first invoice
    $scope.lastClosingEnd = moment.utc(lastClosingEnd.last_end_date).toDate();

    // Possible refunding methods
    $scope.avoirModes = [
      { name: _t('app.admin.invoices.none'), value: 'none' },
      { name: _t('app.admin.invoices.by_cash'), value: 'cash' },
      { name: _t('app.admin.invoices.by_cheque'), value: 'cheque' },
      { name: _t('app.admin.invoices.by_transfer'), value: 'transfer' },
      { name: _t('app.admin.invoices.by_wallet'), value: 'wallet' }
    ];

    // If a subscription was took with the current invoice, should it be canceled or not
    $scope.subscriptionExpireOptions = {};
    $scope.subscriptionExpireOptions[_t('app.shared.buttons.yes')] = true;
    $scope.subscriptionExpireOptions[_t('app.shared.buttons.no')] = false;

    // AngularUI-Bootstrap datepicker parameters to define when to refund
    $scope.datePicker = {
      format: Fablab.uibDateFormat,
      opened: false, // default: datePicker is not shown
      options: {
        startingDay: Fablab.weekStartingDay
      }
    };

    /**
     * Callback to open the datepicker
     */
    $scope.openDatePicker = function ($event) {
      $event.preventDefault();
      $event.stopPropagation();
      $scope.datePicker.opened = true;
    };

    /**
     * Validate the refunding and generate a refund invoice
     */
    $scope.ok = function () {
      // check that at least 1 element of the invoice is refunded
      $scope.avoir.invoice_items_ids = [];
      for (const itemId in $scope.partial) {
        if (Object.prototype.hasOwnProperty.call($scope.partial, itemId)) {
          const refundItem = $scope.partial[itemId];
          if (refundItem) {
            $scope.avoir.invoice_items_ids.push(parseInt(itemId));
          }
        }
      }

      if ($scope.avoir.invoice_items_ids.length === 0) {
        return growl.error(_t('app.admin.invoices.you_must_select_at_least_one_element_to_create_a_refund'));
      } else {
        return Invoice.save(
          { avoir: $scope.avoir },
          function (avoir) { // success
            $uibModalInstance.close({ avoir, invoice: $scope.invoice });
          },
          function (err) { // failed
            growl.error(_t('app.admin.invoices.unable_to_create_the_refund'));
          }
        );
      }
    };

    /**
     * Cancel the refund, dismiss the modal window
     */
    $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };

    /**
     * Test if the given date is within a closed accounting period
     * @param date {Date} date to test
     * @returns {boolean} true if closed, false otherwise
     */
    $scope.isDateClosed = function (date) {
      for (const period of closedPeriods) {
        if (moment(date).isBetween(moment.utc(period.start_at).startOf('day'), moment.utc(period.end_at).endOf('day'), null, '[]')) {
          return true;
        }
      }
      return false;
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
    // if the invoice was paid with stripe, allow refunding through stripe
      Invoice.get({ id: invoice.id }, function (data) {
        $scope.invoice = data;
        // default : all elements of the invoice are refund
        return Array.from(data.items).map(function (item) {
          return ($scope.partial[item.id] = (typeof item.avoir_item_id !== 'number'));
        });
      });

      if (invoice.online_payment) {
        return $scope.avoirModes.push({ name: _t('app.admin.invoices.online_payment'), value: 'card' });
      }
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

/**
 * Controller used in the modal window allowing an admin to close an accounting period
 */
Application.Controllers.controller('ClosePeriodModalController', ['$scope', '$uibModalInstance', '$window', '$sce', 'Invoice', 'AccountingPeriod', 'periods', 'lastClosingEnd', 'dialogs', 'growl', '_t',
  function ($scope, $uibModalInstance, $window, $sce, Invoice, AccountingPeriod, periods, lastClosingEnd, dialogs, growl, _t) {
    const YESTERDAY = moment.utc({ h: 0, m: 0, s: 0, ms: 0 }).subtract(1, 'day').toDate();
    const LAST_CLOSING = moment.utc(lastClosingEnd.last_end_date).toDate();
    const MAX_END = moment.utc(lastClosingEnd.last_end_date).add(1, 'year').subtract(1, 'day').toDate();

    /* PUBLIC SCOPE */

    // date pickers values are bound to these variables
    $scope.period = {
      start_at: LAST_CLOSING,
      end_at: moment(YESTERDAY).isBefore(MAX_END) ? YESTERDAY : MAX_END
    };

    // any form errors will come here
    $scope.errors = {};

    // will match any error about invoices
    $scope.invoiceErrorRE = /^invoice_(.+)$/;

    // existing closed periods, provided by the API
    $scope.accountingPeriods = periods;

    // closing a period may take a long time so we need to prevent the user from double-clicking the close button while processing
    $scope.pendingCreation = false;

    // AngularUI-Bootstrap datepickers parameters to define the period to close
    $scope.datePicker = {
      format: Fablab.uibDateFormat,
      // default: datePicker are not shown
      startOpened: false,
      endOpened: false,
      minDate: LAST_CLOSING,
      maxDate: moment(YESTERDAY).isBefore(MAX_END) ? YESTERDAY : MAX_END,
      options: {
        startingDay: Fablab.weekStartingDay
      }
    };

    /**
     * Callback to open the datepicker
     */
    $scope.toggleDatePicker = function ($event) {
      $event.preventDefault();
      $event.stopPropagation();
      $scope.datePicker.endOpened = !$scope.datePicker.endOpened;
    };

    /**
     * Validate the close period creation
     */
    $scope.ok = function () {
      dialogs.confirm(
        {
          resolve: {
            object () {
              return {
                title: _t('app.admin.invoices.confirmation_required'),
                msg: $sce.trustAsHtml(
                  _t(
                    'app.admin.invoices.confirm_close_START_END',
                    { START: moment.utc($scope.period.start_at).format('LL'), END: moment.utc($scope.period.end_at).format('LL') }
                  ) +
                  '<br/><br/><strong>' +
                  _t('app.admin.invoices.period_must_match_fiscal_year') +
                  '</strong><br/><br/>' +
                  _t('app.admin.invoices.this_may_take_a_while')
                )
              };
            }
          }
        },
        function () { // creation confirmed
          $scope.pendingCreation = true;
          AccountingPeriod.save(
            {
              accounting_period: {
                start_at: moment.utc($scope.period.start_at).toDate(),
                end_at: moment.utc($scope.period.end_at).endOf('day').toDate()
              }
            },
            function (resp) {
              $scope.pendingCreation = false;
              growl.success(_t(
                'app.admin.invoices.period_START_END_closed_success',
                { START: moment.utc(resp.start_at).format('LL'), END: moment.utc(resp.end_at).format('LL') }
              ));
              $uibModalInstance.close(resp);
            },
            function (error) {
              $scope.pendingCreation = false;
              growl.error(_t('app.admin.invoices.failed_to_close_period'));
              $scope.errors = error.data;
            }
          );
        }
      );
    };

    /**
     * Just dismiss the modal window
     */
    $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };

    /**
     * Trigger the API call to download the JSON archive of the closed accounting period
     */
    $scope.downloadArchive = function (period) {
      $window.location.href = `/api/accounting_periods/${period.id}/archive`;
    };
  }
]);

Application.Controllers.controller('AccountingExportModalController', ['$scope', '$uibModalInstance', 'Invoice', 'Export', 'CSRF', 'growl', '_t',
  function ($scope, $uibModalInstance, Invoice, Export, CSRF, growl, _t) {
  // Retrieve Anti-CSRF tokens from cookies
    CSRF.setMetaTags();

    const SETTINGS = {
      acd: {
        format: 'csv',
        encoding: 'ISO-8859-1',
        separator: ';',
        dateFormat: '%d/%m/%Y',
        labelMaxLength: 50,
        decimalSeparator: ',',
        exportInvoicesAtZero: false,
        columns: ['journal_code', 'date', 'account_code', 'account_label', 'piece', 'line_label', 'debit_origin', 'credit_origin', 'debit_euro', 'credit_euro', 'lettering']
      }
    };

    /* PUBLIC SCOPE */

    // API URL where the form will be posted
    $scope.actionUrl = '/api/accounting/export';

    // Form action on the above URL
    $scope.method = 'post';

    // Anti-CSRF token to inject into the download form
    $scope.csrfToken = angular.element('meta[name="csrf-token"]')[0].content;

    // API request body to generate the export
    $scope.query = null;

    // binding to radio button "export to"
    $scope.exportTarget = {
      software: null,
      startDate: null,
      endDate: null,
      settings: null
    };

    // AngularUI-Bootstrap datepicker parameters to define export dates range
    $scope.datePicker = {
      format: Fablab.uibDateFormat,
      opened: { // default: datePickers are not shown
        start: false,
        end: false
      },
      options: {
        startingDay: Fablab.weekStartingDay
      }
    };

    // Date of the first invoice
    $scope.firstInvoice = null;

    /**
   * Validate the export
   */
    $scope.ok = function () {
      const statusQry = mkQuery();
      $scope.query = statusQry;

      Export.status(statusQry).then(function (res) {
        if (!res.data.exists) {
          growl.success(_t('app.admin.invoices.export_is_running'));
        }
        $uibModalInstance.close(res);
      });
    };

    /**
   * Callback to open/close one of the datepickers
   * @param event {Object} see https://docs.angularjs.org/guide/expression#-event-
   * @param picker {string} start | end
   */
    $scope.toggleDatePicker = function (event, picker) {
      event.preventDefault();
      $scope.datePicker.opened[picker] = !$scope.datePicker.opened[picker];
    };

    /**
   * Will fill the export settings, according to the selected software
   * @param software {String} must be one of SETTINGS.*
   */
    $scope.fillSettings = function (software) {
      $scope.exportTarget.settings = SETTINGS[software];
    };

    /**
   * Just dismiss the modal window
   */
    $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };

    /* PRIVATE SCOPE */

    /**
   * Kind of constructor: these actions will be realized first when the controller is loaded
   */
    const initialize = function () {
      // Get info about the very first invoice on the system
      Invoice.first(function (data) {
        $scope.firstInvoice = data.date;
        $scope.exportTarget.startDate = data.date;
        $scope.exportTarget.endDate = moment().toISOString();
      });
    };

    /**
   * Prepare the query for the export API
   * @returns {{extension: *, query: *, category: string, type: *, key: *}}
   */
    const mkQuery = function () {
      return {
        category: 'accounting',
        type: $scope.exportTarget.software,
        extension: $scope.exportTarget.settings.format,
        key: $scope.exportTarget.settings.separator,
        query: JSON.stringify({
          columns: $scope.exportTarget.settings.columns,
          encoding: $scope.exportTarget.settings.encoding,
          date_format: $scope.exportTarget.settings.dateFormat,
          start_date: moment.utc($scope.exportTarget.startDate).startOf('day').toISOString(),
          end_date: moment.utc($scope.exportTarget.endDate).endOf('day').toISOString(),
          label_max_length: $scope.exportTarget.settings.labelMaxLength,
          decimal_separator: $scope.exportTarget.settings.decimalSeparator,
          export_invoices_at_zero: $scope.exportTarget.settings.exportInvoicesAtZero
        })
      };
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }]);
