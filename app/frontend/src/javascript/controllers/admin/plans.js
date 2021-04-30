/* eslint-disable
    camelcase,
    handle-callback-err,
    no-return-assign,
    no-undef,
    no-unused-expressions,
    no-unused-vars,
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

/* COMMON CODE */

class PlanController {
  constructor ($scope, groups, prices, partners, CSRF, _t) {
    // protection against request forgery
    CSRF.setMetaTags();

    // groups list
    $scope.groups = groups
      .filter(function (g) { return (g.slug !== 'admins') && !g.disabled; })
      .map(e => Object.assign({}, e, { category: 'app.shared.plan.groups', id: `${e.id}` }));
    $scope.groups.push({ id: 'all', name: 'app.shared.plan.transversal_all_groups', category: 'app.shared.plan.all' });

    // dynamically translate a label if needed
    $scope.translateLabel = function (group, prop) {
      return group[prop] && group[prop].match(/^app\./) ? _t(group[prop]) : group[prop];
    };

    // users with role 'partner', notifiable for a partner plan
    $scope.partners = partners.users;

    // Subscriptions prices, machines prices and training prices, per groups
    $scope.group_pricing = prices;

    /**
     * For use with 'ng-class', returns the CSS class name for the uploads previews.
     * The preview may show a placeholder or the content of the file depending on the upload state.
     * @param v {*} any attribute, will be tested for truthiness (see JS evaluation rules)
     */
    $scope.fileinputClass = function (v) {
      if (v) {
        return 'fileinput-exists';
      } else {
        return 'fileinput-new';
      }
    };

    /**
     * Mark the provided file for deletion
     * @param file {Object}
     */
    $scope.deleteFile = function (file) {
      if ((file != null) && (file.id != null)) {
        return file._destroy = true;
      }
    };

    /**
     * Check and limit
     * @param content
     */
    $scope.limitDescriptionSize = function (content) {
      alert(content);
    };
  }
}

/**
 * Controller used in the plan creation form
 */
Application.Controllers.controller('NewPlanController', ['$scope', '$uibModal', 'groups', 'prices', 'partners', 'CSRF', '$state', 'growl', '_t',
  function ($scope, $uibModal, groups, prices, partners, CSRF, $state, growl, _t) {
    /* PUBLIC SCOPE */

    // current form is used to create a new plan
    $scope.mode = 'creation';

    // prices bindings
    $scope.prices = {
      training: {},
      machine: {}
    };

    // form inputs bindings
    $scope.plan = {
      type: null,
      group_id: null,
      interval: null,
      intervalCount: 0,
      amount: null,
      is_rolling: false,
      partnerId: null,
      partnerContact: null,
      ui_weight: 0,
      monthly_payment: false
    };

    // API URL where the form will be posted
    $scope.actionUrl = '/api/plans/';

    // HTTP method for the rest API
    $scope.method = 'POST';

    /**
     * Checks if the partner contact is a valid data. Used in the form validation process
     * @returns {boolean}
     */
    $scope.partnerIsValid = function () { return ($scope.plan.type === 'Plan') || ($scope.plan.partnerId || ($scope.plan.partnerContact && $scope.plan.partnerContact.email)); };

    /**
     * Open a modal dialog allowing the admin to create a new partner user
     */
    $scope.openPartnerNewModal = function (subscription) {
      const modalInstance = $uibModal.open({
        animation: true,
        templateUrl: '/shared/_partner_new_modal.html',
        size: 'lg',
        controller: ['$scope', '$uibModalInstance', 'User', function ($scope, $uibModalInstance, User) {
          $scope.partner = {};

          $scope.ok = function () {
            User.save(
              {},
              { user: $scope.partner },
              function (user) {
                $scope.partner.id = user.id;
                $scope.partner.name = `${user.first_name} ${user.last_name}`;
                $uibModalInstance.close($scope.partner);
              },
              function (error) {
                growl.error(_t('app.admin.plans.new.unable_to_save_this_user_check_that_there_isnt_an_already_a_user_with_the_same_name'));
                console.error(error);
              }
            );
          };
          $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };
        }]
      });
      // once the form was validated successfully ...
      return modalInstance.result.then(function (partner) {
        $scope.partners.push(partner);
        return $scope.plan.partnerId = partner.id;
      });
    };

    /**
     * This will update the monthly_payment value when the user toggles the switch button
     * @param checked {Boolean}
     */
    $scope.toggleMonthlyPayment = function (checked) {
      toggle('monthly_payment', checked);
    };

    /**
     * This will update the is_rolling value when the user toggles the switch button
     * @param checked {Boolean}
     */
    $scope.toggleIsRolling = function (checked) {
      toggle('is_rolling', checked);
    };

    /**
     * Display some messages and redirect the user, once the form was submitted, depending on the result status
     * (failed/succeeded).
     * @param content {Object}
     */
    $scope.afterSubmit = function (content) {
      if ((content.id == null) && (content.plan_ids == null)) {
        return growl.error(_t('app.admin.plans.new.unable_to_create_the_subscription_please_try_again'));
      } else {
        growl.success(_t('app.admin.plans.new.successfully_created_subscriptions_dont_forget_to_redefine_prices'));
        if (content.plan_ids != null) {
          return $state.go('app.admin.pricing');
        } else {
          if (content.id != null) {
            return $state.go('app.admin.plans.edit', { id: content.id });
          }
        }
      }
    };

    /* PRIVATE SCOPE */
    const initialize = function () {
      $scope.$watch(scope => scope.plan.interval,
        (newValue, oldValue) => {
          if (newValue === 'week') { $scope.plan.monthly_payment = false; }
        }
      );
    };

    /**
     * Asynchronously updates the given property with the new provided value
     * @param property {string}
     * @param value {*}
     */
    const toggle = function (property, value) {
      setTimeout(() => {
        $scope.plan[property] = value;
        $scope.$apply();
      }, 50);
    };

    initialize();
    return new PlanController($scope, groups, prices, partners, CSRF, _t);
  }
]);

/**
 * Controller used in the plan edition form
 */
Application.Controllers.controller('EditPlanController', ['$scope', 'groups', 'plans', 'planPromise', 'machines', 'spaces', 'prices', 'partners', 'CSRF', '$state', '$stateParams', 'growl', '$filter', '_t', 'Plan',
  function ($scope, groups, plans, planPromise, machines, spaces, prices, partners, CSRF, $state, $stateParams, growl, $filter, _t, Plan) {
  /* PUBLIC SCOPE */

    // List of spaces
    $scope.spaces = spaces;

    // List of plans
    $scope.plans = plans;

    // List of machines
    $scope.machines = machines;

    // List of groups
    $scope.allGroups = groups;

    // current form is used for edition mode
    $scope.mode = 'edition';

    // edited plan data
    $scope.plan = Object.assign({}, planPromise, { group_id: `${planPromise.group_id}` });
    if ($scope.plan.type === null) { $scope.plan.type = 'Plan'; }
    if ($scope.plan.disabled) { $scope.plan.disabled = 'true'; }

    // API URL where the form will be posted
    $scope.actionUrl = `/api/plans/${$stateParams.id}`;

    // HTTP method for the rest API
    $scope.method = 'PATCH';

    $scope.selectedGroup = function () {
      const group = $scope.groups.filter(g => g.id === $scope.plan.group_id);
      return $scope.translateLabel(group[0], 'name');
    };

    /**
     * If a parent plan was set ($scope.plan.parent), the prices will be copied from this parent plan into
     * the current plan prices list. Otherwise, the current plan prices will be erased.
     */
    $scope.copyPricesFromPlan = function () {
      if ($scope.plan.parent) {
        return Plan.get({ id: $scope.plan.parent }, function (parentPlan) {
          Array.from(parentPlan.prices).map(function (parentPrice) {
            return (function () {
              const result = [];
              for (const childKey in $scope.plan.prices) {
                const childPrice = $scope.plan.prices[childKey];
                if ((childPrice.priceable_type === parentPrice.priceable_type) && (childPrice.priceable_id === parentPrice.priceable_id)) {
                  $scope.plan.prices[childKey].amount = parentPrice.amount;
                  break;
                } else {
                  result.push(undefined);
                }
              }
              return result;
            })();
          });
        }
        );

        // if no plan were selected, unset every prices
      } else {
        return (function () {
          const result = [];
          for (const key in $scope.plan.prices) {
            const price = $scope.plan.prices[key];
            result.push($scope.plan.prices[key].amount = 0);
          }
          return result;
        })();
      }
    };

    /**
     * Display some messages once the form was submitted, depending on the result status (failed/succeeded)
     * @param content {Object}
     */
    $scope.afterSubmit = function (content) {
      if ((content.id == null) && (content.plan_ids == null)) {
        return growl.error(_t('app.admin.plans.edit.unable_to_save_subscription_changes_please_try_again'));
      } else {
        growl.success(_t('app.admin.plans.edit.subscription_successfully_changed'));
        return $state.go('app.admin.pricing');
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
     * Retrieve the machine from its ID
     * @param machine_id {number} machine identifier
     * @returns {Object} Machine
     */
    $scope.getMachine = function (machine_id) {
      for (const machine of Array.from($scope.machines)) {
        if (machine.id === machine_id) {
          return machine;
        }
      }
    };

    /**
     * Retrieve the space from its ID
     * @param space_id {number} space identifier
     * @returns {Object} Space
     */
    $scope.getSpace = function (space_id) {
      for (const space of Array.from($scope.spaces)) {
        if (space.id === space_id) {
          return space;
        }
      }
    };

    // Using the PlansController
    return new PlanController($scope, groups, prices, partners, CSRF, _t);
  }
]);
