/* eslint-disable
    handle-callback-err,
    no-return-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

/**
 * Controller used in the prices edition page
 */
Application.Controllers.controller('EditPricingController', ['$scope', '$state', '$uibModal', '$filter', 'TrainingsPricing', 'Credit', 'Pricing', 'Plan', 'Coupon', 'plans', 'groups', 'growl', 'machinesPricesPromise', 'Price', 'dialogs', 'trainingsPricingsPromise', 'trainingsPromise', 'machineCreditsPromise', 'machinesPromise', 'trainingCreditsPromise', 'couponsPromise', 'spacesPromise', 'spacesPricesPromise', 'spacesCreditsPromise', 'settingsPromise', '_t', 'Member', 'uiTourService',
  function ($scope, $state, $uibModal, $filter, TrainingsPricing, Credit, Pricing, Plan, Coupon, plans, groups, growl, machinesPricesPromise, Price, dialogs, trainingsPricingsPromise, trainingsPromise, machineCreditsPromise, machinesPromise, trainingCreditsPromise, couponsPromise, spacesPromise, spacesPricesPromise, spacesCreditsPromise, settingsPromise, _t, Member, uiTourService) {
    /* PUBLIC SCOPE */

    // List of machines prices (not considering any plan)
    $scope.machinesPrices = machinesPricesPromise;

    // List of trainings pricing
    $scope.trainingsPricings = trainingsPricingsPromise;

    // List of available subscriptions plans (eg. student/month, PME/year ...)
    $scope.plans = plans;
    $scope.enabledPlans = plans.filter(function (p) { return !p.disabled; });

    // List of groups (eg. normal, student ...)
    $scope.groups = groups.filter(function (g) { return g.slug !== 'admins'; });
    $scope.enabledGroups = groups.filter(function (g) { return (g.slug !== 'admins') && !g.disabled; });

    // Associate free machine hours with subscriptions
    $scope.machineCredits = machineCreditsPromise;

    // Array of associations (plan <-> training)
    $scope.trainingCredits = trainingCreditsPromise;

    // Associate a plan with all its trainings ids
    $scope.trainingCreditsGroups = {};

    // List of trainings
    $scope.trainings = trainingsPromise.filter(function (t) { return !t.disabled; });

    // List of machines
    $scope.machines = machinesPromise;
    $scope.enabledMachines = machinesPromise.filter(function (m) { return !m.disabled; });

    // List of coupons
    $scope.coupons = couponsPromise;
    $scope.couponsPage = 1;

    // List of spaces
    $scope.spaces = spacesPromise;
    $scope.enabledSpaces = spacesPromise.filter(function (s) { return !s.disabled; });

    // Associate free space hours with subscriptions
    $scope.spaceCredits = spacesCreditsPromise;

    // List of spaces prices (not considering any plan)
    $scope.spacesPrices = spacesPricesPromise;

    // The plans list ordering. Default: by group
    $scope.orderPlans = 'group_id';

    // Status of the drop-down menu in Credits tab
    $scope.status =
    { isopen: false };

    // Default: we show only enabled plans
    $scope.planFiltering = 'enabled';

    // Default duration for the slots
    $scope.slotDuration = parseInt(settingsPromise.slot_duration, 10);

    // Available options for filtering plans by status
    $scope.filterDisabled = [
      'enabled',
      'disabled',
      'all'
    ];

    // Default: we do not filter coupons
    $scope.filter = {
      coupon: 'all'
    };

    // Available status for filtering coupons
    $scope.couponStatus = [
      'all',
      'disabled',
      'expired',
      'sold_out',
      'active'
    ];

    // default tab: plans list
    $scope.tabs = { active: 0 };

    /**
     * Retrieve a training price from all the trainings prices
     * @param trainingsPricings {Array<Object>} all trainings prices
     * @param trainingId {number}
     * @param groupId {number}
     * @returns {float}
     */
    $scope.findTrainingsPricing = function (trainingsPricings, trainingId, groupId) {
      for (const trainingsPricing of Array.from(trainingsPricings)) {
        if ((trainingsPricing.training_id === trainingId) && (trainingsPricing.group_id === groupId)) {
          return trainingsPricing;
        }
      }
    };

    /**
     * Update the price of a training for the given parameters
     * @param data {float} the new price
     * @param trainingsPricing {Object} the training pricing to update
     * @returns {Promise|string}
     */
    $scope.updateTrainingsPricing = function (data, trainingsPricing) {
      if (data != null) {
        return TrainingsPricing.update({ id: trainingsPricing.id }, { trainings_pricing: { amount: data } }).$promise;
      } else {
        return _t('app.admin.pricing.please_specify_a_number');
      }
    };

    /**
     * Retrieve a plan from its given identifier and returns it
     * @param id {number} plan ID
     * @returns {Object} Plan, inherits from $resource
     */
    $scope.getPlanFromId = function (id) {
      for (const plan of Array.from($scope.plans)) {
        if (plan.id === parseInt(id)) {
          return plan;
        }
      }
    };

    /**
     * Retrieve a group from its given identifier and returns it
     * @param id {number} group ID
     * @returns {Object} Group, inherits from $resource
     */
    $scope.getGroupFromId = function (groups, id) {
      for (const group of Array.from(groups)) {
        if (group.id === parseInt(id)) {
          return group;
        }
      }
    };

    /**
     * Returns a human readable string of named trainings, according to the provided array.
     * $scope.trainings may contains the full list of training. The returned string will only contains the trainings
     * whom ID are given in the provided parameter
     * @param trainings {Array<number>} trainings IDs array
     */
    $scope.showTrainings = function (trainings) {
      if (!angular.isArray(trainings) || !(trainings.length > 0)) {
        return _t('app.admin.pricing.none');
      }

      const selected = [];
      angular.forEach($scope.trainings, function (t) {
        if (trainings.indexOf(t.id) >= 0) {
          return selected.push(t.name);
        }
      });
      if (selected.length) { return selected.join(' | '); } else { return _t('app.admin.pricing.none'); }
    };

    /**
     * Validation callback when editing training's credits. Save the changes.
     * @param newdata {Object} training and associated plans
     * @param planId {number|string} plan id
     */
    $scope.saveTrainingCredits = function (newdata, planId) {
    // save the number of credits
      Plan.update(
        { id: planId },
        { training_credit_nb: newdata.training_credits }
        , angular.noop() // do nothing in case of success
        , function (error) {
          growl.error(_t('app.admin.pricing.an_error_occurred_while_saving_the_number_of_credits'));
          console.error(error);
        }
      );

      // save the associated trainings
      return angular.forEach($scope.trainingCreditsGroups, function (original, key) {
        if (parseInt(key) === parseInt(planId)) { // we've got the original data
          if (original.join('_') !== newdata.training_ids.join('_')) { // if any changes
          // iterate through the previous credits to remove
            angular.forEach(original, function (oldTrainingId) {
              if (newdata.training_ids.indexOf(oldTrainingId) === -1) {
                const tc = findTrainingCredit(oldTrainingId, planId);
                if (tc) {
                  return tc.$delete({}
                    , function () {
                      $scope.trainingCredits.splice($scope.trainingCredits.indexOf(tc), 1);
                      return $scope.trainingCreditsGroups[planId].splice($scope.trainingCreditsGroups[planId].indexOf(tc.id), 1);
                    }
                    , function (error) {
                      growl.error(_t('app.admin.pricing.an_error_occurred_while_deleting_credit_with_the_TRAINING', { TRAINING: tc.creditable.name }));
                      console.error(error);
                    });
                } else {
                  return growl.error(_t('app.admin.pricing.an_error_occurred_unable_to_find_the_credit_to_revoke'));
                }
              }
            });

            // iterate through the new credits to add
            return angular.forEach(newdata.training_ids, function (newTrainingId) {
              if (original.indexOf(newTrainingId) === -1) {
                return Credit.save({
                  credit: {
                    creditable_id: newTrainingId,
                    creditable_type: 'Training',
                    plan_id: planId
                  }
                }
                , function (newTc) { // success
                  $scope.trainingCredits.push(newTc);
                  return $scope.trainingCreditsGroups[newTc.plan_id].push(newTc.creditable_id);
                }
                , function (error) { // failed
                  const training = getTrainingFromId(newTrainingId);
                  growl.error(_t('app.admin.pricing.an_error_occurred_while_creating_credit_with_the_TRAINING', { TRAINING: training.name }));
                  return console.error(error);
                });
              }
            });
          }
        }
      });
    };

    /**
     * Cancel the current training credit modification
     * @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
     */
    $scope.cancelTrainingCredit = function (rowform) { rowform.$cancel(); };

    /**
     * Create a new empty entry in the $scope.machineCredits array
     * @param e {Object} see https://docs.angularjs.org/guide/expression#-event-
     */
    $scope.addMachineCredit = function (e) {
      e.preventDefault();
      e.stopPropagation();
      $scope.inserted =
      { creditable_type: 'Machine' };
      $scope.machineCredits.push($scope.inserted);
      return $scope.status.isopen = !$scope.status.isopen;
    };

    /**
     * In the Credits tab, return the name of the machine/space associated with the given credit
     * @param credit {Object} credit object, inherited from $resource
     * @returns {String}
     */
    $scope.showCreditableName = function (credit) {
      let selected = _t('app.admin.pricing.not_set');
      if (credit && credit.creditable_id) {
        const object = $scope.getCreditable(credit);
        selected = object.name;
        if (credit.creditable_type === 'Machine') {
          selected += ` ( id. ${object.id} )`;
        }
      }
      return selected;
    };

    /**
     * In the Credits tab, return the machine/space associated with the given credit
     * @param credit {Object} credit object, inherited from $resource
     * @returns {Object}
     */
    $scope.getCreditable = function (credit) {
      let selected;
      if (credit && credit.creditable_id) {
        if (credit.creditable_type === 'Machine') {
          angular.forEach($scope.machines, function (m) {
            if (m.id === credit.creditable_id) {
              return selected = m;
            }
          });
        } else if (credit.creditable_type === 'Space') {
          angular.forEach($scope.spaces, function (s) {
            if (s.id === credit.creditable_id) {
              return selected = s;
            }
          });
        }
      }
      return selected;
    };

    /**
     * Validation callback when editing machine's credits. Save the changes.
     * This will prevent the creation of two credits associating the same machine and plan.
     * @param data {Object} machine, associated plan and number of credit hours.
     * @param [id] {number} credit id for edition, create a new credit object if not provided
     */
    $scope.saveMachineCredit = function (data, id) {
      for (const mc of Array.from($scope.machineCredits)) {
        if ((mc.plan_id === data.plan_id) && (mc.creditable_id === data.creditable_id) && ((id === null) || (mc.id !== id))) {
          growl.error(_t('app.admin.pricing.error_a_credit_linking_this_machine_with_that_subscription_already_exists'));
          if (!id) {
            $scope.machineCredits.pop();
          }
          return false;
        }
      }

      if (id != null) {
        return Credit.update({ id }, { credit: data }, function () { growl.success(_t('app.admin.pricing.changes_have_been_successfully_saved')); });
      } else {
        data.creditable_type = 'Machine';
        return Credit.save(
          { credit: data }
          , function (resp) {
            $scope.machineCredits[$scope.machineCredits.length - 1].id = resp.id;
            return growl.success(_t('app.admin.pricing.credit_was_successfully_saved'));
          }
          , function (err) {
            $scope.machineCredits.pop();
            growl.error(_t('app.admin.pricing.error_creating_credit'));
            console.error(err);
          });
      }
    };

    /**
     * Removes the newly inserted but not saved machine credit / Cancel the current machine credit modification
     * @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
     * @param index {number} credit index in the $scope.machineCredits array
     */
    $scope.cancelMachineCredit = function (rowform, index) {
      if ($scope.machineCredits[index].id != null) {
        return rowform.$cancel();
      } else {
        return $scope.machineCredits.splice(index, 1);
      }
    };

    /**
     *  Deletes the machine credit at the specified index
     * @param index {number} machine credit index in the $scope.machineCredits array
     */
    $scope.removeMachineCredit = function (index) {
      Credit.delete($scope.machineCredits[index]);
      $scope.machineCredits.splice(index, 1);
    };

    /**
     * Create a new empty entry in the $scope.spaceCredits array
     * @param e {Object} see https://docs.angularjs.org/guide/expression#-event-
     */
    $scope.addSpaceCredit = function (e) {
      e.preventDefault();
      e.stopPropagation();
      $scope.inserted =
      { creditable_type: 'Space' };
      $scope.spaceCredits.push($scope.inserted);
      $scope.status.isopen = !$scope.status.isopen;
    };

    /**
     * Validation callback when editing space's credits. Save the changes.
     * This will prevent the creation of two credits associated with the same space and plan.
     * @param data {Object} space, associated plan and number of credit hours.
     * @param [id] {number} credit id for edition, create a new credit object if not provided
     */
    $scope.saveSpaceCredit = function (data, id) {
      for (const sc of Array.from($scope.spaceCredits)) {
        if ((sc.plan_id === data.plan_id) && (sc.creditable_id === data.creditable_id) && ((id === null) || (sc.id !== id))) {
          growl.error(_t('app.admin.pricing.error_a_credit_linking_this_space_with_that_subscription_already_exists'));
          if (!id) {
            $scope.spaceCredits.pop();
          }
          return false;
        }
      }

      if (id != null) {
        return Credit.update({ id }, { credit: data }, function () { growl.success(_t('app.admin.pricing.changes_have_been_successfully_saved')); });
      } else {
        data.creditable_type = 'Space';
        return Credit.save(
          { credit: data }
          , function (resp) {
            $scope.spaceCredits[$scope.spaceCredits.length - 1].id = resp.id;
            return growl.success(_t('app.admin.pricing.credit_was_successfully_saved'));
          }
          , function (err) {
            $scope.spaceCredits.pop();
            return growl.error(_t('app.admin.pricing.error_creating_credit'));
          });
      }
    };

    /**
     * Removes the newly inserted but not saved space credit / Cancel the current space credit modification
     * @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
     * @param index {number} credit index in the $scope.spaceCredits array
     */
    $scope.cancelSpaceCredit = function (rowform, index) {
      if ($scope.spaceCredits[index].id != null) {
        return rowform.$cancel();
      } else {
        return $scope.spaceCredits.splice(index, 1);
      }
    };

    /**
     * Deletes the space credit at the specified index
     * @param index {number} space credit index in the $scope.spaceCredits array
     */
    $scope.removeSpaceCredit = function (index) {
      Credit.delete($scope.spaceCredits[index]);
      return $scope.spaceCredits.splice(index, 1);
    };

    /**
     * If the plan does not have a type, return a default value for display purposes
     * @param type {string|undefined|null} plan's type (eg. 'partner')
     * @returns {string}
     */
    $scope.getPlanType = function (type) {
      if (type === 'PartnerPlan') {
        return _t('app.admin.pricing.partner');
      } else { return _t('app.admin.pricing.standard'); }
    };

    /**
     * Change the plans ordering criterion to the one provided
     * @param orderBy {string} ordering criterion
     */
    $scope.setOrderPlans = function (orderBy) {
      if ($scope.orderPlans === orderBy) {
        return $scope.orderPlans = `-${orderBy}`;
      } else {
        return $scope.orderPlans = orderBy;
      }
    };

    /**
     * Retrieve a price from prices array by a machineId and a groupId
     */
    $scope.findPriceBy = function (prices, machineId, groupId) {
      for (const price of Array.from(prices)) {
        if ((price.priceable_id === machineId) && (price.group_id === groupId)) {
          return price;
        }
      }
    };

    /**
     * update a price for a machine and a group, not considering any plan
     */
    $scope.updatePrice = function (data, price) {
      if (data != null) {
        return Price.update({ id: price.id }, { price: { amount: data } }).$promise;
      } else {
        return _t('app.admin.pricing.please_specify_a_number');
      }
    };

    /**
     * Delete the specified subcription plan
     * @param id {number} plan id
     */
    $scope.deletePlan = function (plans, id) {
      if (typeof id !== 'number') {
        return console.error('[EditPricingController::deletePlan] Error: invalid id parameter');
      } else {
      // open a confirmation dialog
        return dialogs.confirm(
          {
            resolve: {
              object () {
                return {
                  title: _t('app.admin.pricing.confirmation_required'),
                  msg: _t('app.admin.pricing.do_you_really_want_to_delete_this_subscription_plan')
                };
              }
            }
          },
          function () {
            // the admin has confirmed, delete the plan
            Plan.delete(
              { id },
              function (res) {
                growl.success(_t('app.admin.pricing.subscription_plan_was_successfully_deleted'));
                return $scope.plans.splice(findItemIdxById(plans, id), 1);
              },
              function (error) {
                if (error.statusText) { console.error(`[EditPricingController::deletePlan] Error: ${error.statusText}`); }
                growl.error(_t('app.admin.pricing.unable_to_delete_the_specified_subscription_an_error_occurred'));
              }
            );
          }
        );
      }
    };

    /**
     * Generate a string identifying the given plan by literal humain-readable name
     * @param plan {Object} Plan object, as recovered from GET /api/plan/:id
     * @param groups {Array} List of Groups objects, as recovered from GET /api/groups
     * @param short {boolean} If true, the generated name will contains the group slug, otherwise the group full name
     * will be included.
     * @returns {String}
     */
    $scope.humanReadablePlanName = function (plan, groups, short) { return `${$filter('humanReadablePlanName')(plan, groups, short)}`; };

    /**
     * Delete a coupon from the server's database and, in case of success, from the list in memory
     * @param coupons {Array<Object>} should be called with $scope.coupons
     * @param id {number} ID of the coupon to delete
     */
    $scope.deleteCoupon = function (coupons, id) {
      if (typeof id !== 'number') {
        return console.error('[EditPricingController::deleteCoupon] Error: invalid id parameter');
      } else {
      // open a confirmation dialog
        return dialogs.confirm({
          resolve: {
            object () {
              return {
                title: _t('app.admin.pricing.confirmation_required'),
                msg: _t('app.admin.pricing.do_you_really_want_to_delete_this_coupon')
              };
            }
          }
        }
        , function () {
        // the admin has confirmed, delete the coupon
          Coupon.delete({ id }, function (res) {
            growl.success(_t('app.admin.pricing.coupon_was_successfully_deleted'));
            return $scope.coupons.splice(findItemIdxById(coupons, id), 1);
          }

          , function (error) {
            if (error.statusText) { console.error(`[EditPricingController::deleteCoupon] Error: ${error.statusText}`); }
            if (error.status === 422) {
              return growl.error(_t('app.admin.pricing.unable_to_delete_the_specified_coupon_already_in_use'));
            } else {
              return growl.error(_t('app.admin.pricing.unable_to_delete_the_specified_coupon_an_unexpected_error_occurred'));
            }
          });
        });
      }
    };

    /**
     * Open a modal allowing to select an user and send him the details of the provided coupon
     * @param coupon {Object} The coupon to send
     */
    $scope.sendCouponToUser = function (coupon) {
      $uibModal.open({
        templateUrl: '/admin/pricing/sendCoupon.html',
        resolve: {
          coupon () { return coupon; }
        },
        size: 'md',
        controller: ['$scope', '$uibModalInstance', 'Coupon', 'coupon', '_t', function ($scope, $uibModalInstance, Coupon, coupon, _t) {
        // Member, receiver of the coupon
          $scope.ctrl =
          { member: null };

          // Details of the coupon to send
          $scope.coupon = coupon;

          // Callback to validate sending of the coupon
          $scope.ok = function () {
            Coupon.send({ coupon_code: coupon.code, user_id: $scope.ctrl.member.id }, function (res) {
              growl.success(_t('app.admin.pricing.coupon_successfully_sent_to_USER', { USER: $scope.ctrl.member.name }));
              return $uibModalInstance.close({ user_id: $scope.ctrl.member.id });
            }
            , function (err) {
              growl.error(_t('app.admin.pricing.an_error_occurred_unable_to_send_the_coupon'));
              console.error(err);
            });
          };
          // Callback to close the modal and cancel the sending process
          $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };
        }]
      });
    };

    /**
     * Load the next 10 coupons
     */
    $scope.loadMore = function () {
      $scope.couponsPage++;
      Coupon.query({ page: $scope.couponsPage, filter: $scope.filter.coupon }, function (data) {
        $scope.coupons = $scope.coupons.concat(data);
      });
    };

    /**
     * Reset the list of coupons according to the newly selected filter
     */
    $scope.updateCouponFilter = function () {
      $scope.couponsPage = 1;
      Coupon.query({ page: $scope.couponsPage, filter: $scope.filter.coupon }, function (data) {
        $scope.coupons = data;
      });
    };

    /**
     * Return the exemple price based on the configuration of the default slot duration.
     * @param type {string} 'hourly_rate' | *
     * @returns {number} price for "SLOT_DURATION" minutes.
     */
    $scope.examplePrice = function (type) {
      const hourlyRate = 10;

      if (type === 'hourly_rate') {
        return $filter('currency')(hourlyRate);
      }

      const price = (hourlyRate / 60) * $scope.slotDuration;
      return $filter('currency')(price);
    };

    /**
     * Setup the feature-tour for the admin/pricing page.
     * This is intended as a contextual help (when pressing F1)
     */
    $scope.setupPricingTour = function () {
      // get the tour defined by the ui-tour directive
      const uitour = uiTourService.getTourByName('pricing');
      uitour.createStep({
        selector: 'body',
        stepId: 'welcome',
        order: 0,
        title: _t('app.admin.tour.pricing.welcome.title'),
        content: _t('app.admin.tour.pricing.welcome.content'),
        placement: 'bottom',
        orphan: true
      });
      uitour.createStep({
        selector: '.plans-pricing .new-plan-button',
        stepId: 'new_plan',
        order: 1,
        title: _t('app.admin.tour.pricing.new_plan.title'),
        content: _t('app.admin.tour.pricing.new_plan.content'),
        placement: 'bottom'
      });
      if ($scope.$root.modules.trainings) {
        uitour.createStep({
          selector: '.plans-pricing .trainings-tab',
          stepId: 'trainings',
          order: 2,
          title: _t('app.admin.tour.pricing.trainings.title'),
          content: _t('app.admin.tour.pricing.trainings.content'),
          placement: 'bottom'
        });
      }
      uitour.createStep({
        selector: '.plans-pricing .machines-tab',
        stepId: 'machines',
        order: 3,
        title: _t('app.admin.tour.pricing.machines.title'),
        content: _t('app.admin.tour.pricing.machines.content'),
        placement: 'bottom'
      });
      if ($scope.$root.modules.spaces) {
        uitour.createStep({
          selector: '.plans-pricing .spaces-tab',
          stepId: 'spaces',
          order: 4,
          title: _t('app.admin.tour.pricing.spaces.title'),
          content: _t('app.admin.tour.pricing.spaces.content'),
          placement: 'bottom'
        });
      }
      uitour.createStep({
        selector: '.plans-pricing .credits-tab',
        stepId: 'credits',
        order: 5,
        title: _t('app.admin.tour.pricing.credits.title'),
        content: _t('app.admin.tour.pricing.credits.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: '.plans-pricing .coupons-tab',
        stepId: 'coupons',
        order: 6,
        title: _t('app.admin.tour.pricing.coupons.title'),
        content: _t('app.admin.tour.pricing.coupons.content'),
        placement: 'bottom',
        popupClass: 'shift-left-50'
      });
      uitour.createStep({
        selector: 'body',
        stepId: 'conclusion',
        order: 7,
        title: _t('app.admin.tour.conclusion.title'),
        content: _t('app.admin.tour.conclusion.content'),
        placement: 'bottom',
        orphan: true
      });
      // on step change, change the active tab if needed
      uitour.on('stepChanged', function (nextStep) {
        if (nextStep.stepId === 'new_plan') { $scope.tabs.active = 0; }
        if (nextStep.stepId === 'trainings') { $scope.tabs.active = 1; }
        if (nextStep.stepId === 'machines') { $scope.tabs.active = 2; }
        if (nextStep.stepId === 'spaces') { $scope.tabs.active = 3; }
        if (nextStep.stepId === 'credits') { $scope.tabs.active = 4; }
        if (nextStep.stepId === 'coupons') { $scope.tabs.active = 5; }
      });
      // on tour end, save the status in database
      uitour.on('ended', function () {
        if (uitour.getStatus() === uitour.Status.ON && $scope.currentUser.profile.tours.indexOf('pricing') < 0) {
          Member.completeTour({ id: $scope.currentUser.id }, { tour: 'pricing' }, function (res) {
            $scope.currentUser.profile.tours = res.tours;
          });
        }
      });
      // if the user has never seen the tour, show him now
      if (settingsPromise.feature_tour_display !== 'manual' && $scope.currentUser.profile.tours.indexOf('pricing') < 0) {
        uitour.start();
      }
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      $scope.trainingCreditsGroups = groupCreditsByPlan($scope.trainingCredits);

      // adds empty array for plan which hasn't any credits yet
      return (function () {
        const result = [];
        for (const plan of Array.from($scope.plans)) {
          if ($scope.trainingCreditsGroups[plan.id] == null) {
            result.push($scope.trainingCreditsGroups[plan.id] = []);
          } else {
            result.push(undefined);
          }
        }
        return result;
      })();
    };

    /**
     * Retrieve an item index by its ID from the given array of objects
     * @param items {Array<{id:number}>}
     * @param id {number}
     * @returns {number} item index in the provided array
     */
    const findItemIdxById = function (items, id) {
      return (items.map(function (item) { return item.id; })).indexOf(id);
    };

    /**
     * Group the given credits array into a map associating the plan ID with its associated trainings/machines
     * @return {Object} the association map
     */
    const groupCreditsByPlan = function (credits) {
      const creditsMap = {};
      angular.forEach(credits, function (c) {
        if (!creditsMap[c.plan_id]) {
          creditsMap[c.plan_id] = [];
        }
        return creditsMap[c.plan_id].push(c.creditable_id);
      });
      return creditsMap;
    };

    /**
     * Iterate through $scope.traininfCredits to find the credit matching the given criterion
     * @param trainingId {number|string} training ID
     * @param planId {number|string} plan ID
     */
    const findTrainingCredit = function (trainingId, planId) {
      trainingId = parseInt(trainingId);
      planId = parseInt(planId);

      for (const credit of Array.from($scope.trainingCredits)) {
        if ((credit.plan_id === planId) && (credit.creditable_id === trainingId)) {
          return credit;
        }
      }
    };

    /**
     * Retrieve a training from its given identifier and returns it
     * @param id {number} training ID
     * @returns {Object} Training inherited from $resource
     */
    const getTrainingFromId = function (id) {
      for (const training of Array.from($scope.trainings)) {
        if (training.id === parseInt(id)) {
          return training;
        }
      }
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);
