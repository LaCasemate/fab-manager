/* eslint-disable
    handle-callback-err,
    no-return-assign,
    no-self-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

/* COMMON CODE */

/**
 * Provides a set of common properties and methods to the $scope parameter. They are used
 * in the various members' admin controllers.
 *
 * Provides :
 *  - $scope.groups = [{Group}]
 *  - $scope.trainings = [{Training}]
 *  - $scope.plans = []
 *  - $scope.datePicker = {}
 *  - $scope.submited(content)
 *  - $scope.cancel()
 *  - $scope.fileinputClass(v)
 *  - $scope.openDatePicker($event)
 *  - $scope.openSubscriptionDatePicker($event)
 *
 * Requires :
 *  - $state (Ui-Router) [ 'app.admin.members' ]
 */
class MembersController {
  constructor ($scope, $state, Group, Training) {
    // Retrieve the profiles groups (e.g. students ...)
    Group.query(function (groups) { $scope.groups = groups.filter(function (g) { return (g.slug !== 'admins') && !g.disabled; }); });

    // Retrieve the list of available trainings
    Training.query().$promise.then(function (data) {
      $scope.trainings = data.map(function (d) {
        return ({
          id: d.id,
          name: d.name,
          disabled: d.disabled
        });
      });
    });

    // Default parameters for AngularUI-Bootstrap datepicker
    $scope.datePicker = {
      format: Fablab.uibDateFormat,
      opened: false, // default: datePicker is not shown
      subscription_date_opened: false,
      options: {
        startingDay: Fablab.weekStartingDay
      }
    };

    /**
     * Shows the birthday datepicker
     * @param $event {Object} jQuery event object
     */
    $scope.openDatePicker = function ($event) {
      $event.preventDefault();
      $event.stopPropagation();
      return $scope.datePicker.opened = true;
    };

    /**
     * Shows the end of subscription datepicker
     * @param $event {Object} jQuery event object
     */
    $scope.openSubscriptionDatePicker = function ($event) {
      $event.preventDefault();
      $event.stopPropagation();
      return $scope.datePicker.subscription_date_opened = true;
    };

    /**
     * For use with ngUpload (https://github.com/twilson63/ngUpload).
     * Intended to be the callback when an upload is done: any raised error will be stacked in the
     * $scope.alerts array. If everything goes fine, the user is redirected to the members listing page.
     * @param content {Object} JSON - The result of the upload
     */
    $scope.submited = function (content) {
      if ((content.id == null)) {
        $scope.alerts = [];
        return angular.forEach(content, function (v, k) {
          angular.forEach(v, function (err) {
            $scope.alerts.push({
              msg: k + ': ' + err,
              type: 'danger'
            });
          });
        });
      } else {
        return $state.go('app.admin.members');
      }
    };

    /**
     * Changes the admin's view to the members list page
     */
    $scope.cancel = function () { $state.go('app.admin.members'); };

    /**
     * For use with 'ng-class', returns the CSS class name for the uploads previews.
     * The preview may show a placeholder, or the content of the file depending on the upload state.
     * @param v {*} any attribute, will be tested for truthiness (see JS evaluation rules)
     */
    $scope.fileinputClass = function (v) {
      if (v) {
        return 'fileinput-exists';
      } else {
        return 'fileinput-new';
      }
    };
  }
}

/**
 * Controller used in the members/groups management page
 */
Application.Controllers.controller('AdminMembersController', ['$scope', '$sce', '$uibModal', 'membersPromise', 'adminsPromise', 'partnersPromise', 'managersPromise', 'growl', 'Admin', 'AuthService', 'dialogs', '_t', 'Member', 'Export', 'User', 'uiTourService', 'settingsPromise',
  function ($scope, $sce, $uibModal, membersPromise, adminsPromise, partnersPromise, managersPromise, growl, Admin, AuthService, dialogs, _t, Member, Export, User, uiTourService, settingsPromise) {
  /* PRIVATE STATIC CONSTANTS */

    // number of users loaded each time we click on 'load more...'
    const USERS_PER_PAGE = 20;

    /* PUBLIC SCOPE */

    // members list
    $scope.members = membersPromise;

    $scope.member = {
    // Members plain-text filtering. Default: not filtered
      searchText: '',
      // Members ordering/sorting. Default: not sorted
      order: 'id',
      // the currently displayed page of members
      page: 1,
      // true when all members where loaded
      noMore: false,
      // default filter for members
      memberFilter: 'all',
      // options for members filtering
      memberFilters: [
        'all',
        'not_confirmed',
        'inactive_for_3_years'
      ]
    };

    // admins list
    $scope.admins = adminsPromise.admins.filter(function (m) { return m.id !== Fablab.adminSysId; });

    // Admins ordering/sorting. Default: not sorted
    $scope.orderAdmin = null;

    // partners list
    $scope.partners = partnersPromise.users;

    // Partners ordering/sorting. Default: not sorted
    $scope.orderPartner = null;

    // managers list
    $scope.managers = managersPromise.users;

    // Managers ordering/sorting. Default: not sorted
    $scope.orderManager = null;

    // default tab: members list
    $scope.tabs = { active: 0, sub: 0 };

    /**
     * Change the members ordering criterion to the one provided
     * @param orderBy {string} ordering criterion
     */
    $scope.setOrderMember = function (orderBy) {
      if ($scope.member.order === orderBy) {
        $scope.member.order = `-${orderBy}`;
      } else {
        $scope.member.order = orderBy;
      }

      resetSearchMember();
      return memberSearch();
    };

    /**
     * Change the admins ordering criterion to the one provided
     * @param orderAdmin {string} ordering criterion
     */
    $scope.setOrderAdmin = function (orderAdmin) {
      if ($scope.orderAdmin === orderAdmin) {
        return $scope.orderAdmin = `-${orderAdmin}`;
      } else {
        return $scope.orderAdmin = orderAdmin;
      }
    };

    /**
     * Change the partners ordering criterion to the one provided
     * @param orderPartner {string} ordering criterion
     */
    $scope.setOrderPartner = function (orderPartner) {
      if ($scope.orderPartner === orderPartner) {
        return $scope.orderPartner = `-${orderPartner}`;
      } else {
        return $scope.orderPartner = orderPartner;
      }
    };

    /**
     * Change the managers ordering criterion to the one provided
     * @param orderManager {string} ordering criterion
     */
    $scope.setOrderManager = function (orderManager) {
      if ($scope.orderManager === orderManager) {
        return $scope.orderManager = `-${orderManager}`;
      } else {
        return $scope.orderManager = orderManager;
      }
    };

    /**
     * Open a modal dialog allowing the admin to create a new partner user
     */
    $scope.openPartnerNewModal = function () {
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
      });
    };

    /**
     * Ask for confirmation then delete the specified user
     * @param memberId {number} identifier of the user to delete
     */
    $scope.deleteMember = function (memberId) {
      dialogs.confirm(
        {
          resolve: {
            object () {
              return {
                title: _t('app.admin.members.confirmation_required'),
                msg: $sce.trustAsHtml(_t('app.admin.members.confirm_delete_member') + '<br/><br/>' + _t('app.admin.members.this_may_take_a_while_please_wait'))
              };
            }
          }
        },
        function () { // cancel confirmed
          Member.delete(
            { id: memberId },
            function () {
              $scope.members.splice(findItemIdxById($scope.members, memberId), 1);
              return growl.success(_t('app.admin.members.member_successfully_deleted'));
            },
            function (error) {
              growl.error(_t('app.admin.members.unable_to_delete_the_member'));
              console.error(error);
            }
          );
        }
      );
    };

    /**
     * Ask for confirmation then delete the specified administrator
     * @param admins {Array} full list of administrators
     * @param admin {Object} administrator to delete
     */
    $scope.destroyAdmin = function (admins, admin) {
      dialogs.confirm(
        {
          resolve: {
            object () {
              return {
                title: _t('app.admin.members.confirmation_required'),
                msg: $sce.trustAsHtml(_t('app.admin.members.do_you_really_want_to_delete_this_administrator_this_cannot_be_undone') + '<br/><br/>' + _t('app.admin.members.this_may_take_a_while_please_wait'))
              };
            }
          }
        },
        function () { // cancel confirmed
          Admin.delete(
            { id: admin.id },
            function () {
              admins.splice(findItemIdxById(admins, admin.id), 1);
              return growl.success(_t('app.admin.members.administrator_successfully_deleted'));
            },
            function (error) {
              growl.error(_t('app.admin.members.unable_to_delete_the_administrator'));
              console.error(error);
            }
          );
        }
      );
    };

    /**
     * Ask for confirmation then delete the specified partner
     * @param partners {Array} full list of partners
     * @param partner {Object} partner to delete
     */
    $scope.destroyPartner = function (partners, partner) {
      dialogs.confirm(
        {
          resolve: {
            object () {
              return {
                title: _t('app.admin.members.confirmation_required'),
                msg: $sce.trustAsHtml(_t('app.admin.members.delete_this_partner') + '<br/><br/>' + _t('app.admin.members.this_may_take_a_while_please_wait'))
              };
            }
          }
        },
        function () { // cancel confirmed
          User.delete(
            { id: partner.id },
            function () {
              partners.splice(findItemIdxById(partners, partner.id), 1);
              return growl.success(_t('app.admin.members.partner_successfully_deleted'));
            },
            function (error) {
              growl.error(_t('app.admin.members.unable_to_delete_the_partner'));
              console.error(error);
            }
          );
        }
      );
    };

    /**
     * Ask for confirmation then delete the specified manager
     * @param managers {Array} full list of managers
     * @param manager {Object} manager to delete
     */
    $scope.destroyManager = function (managers, manager) {
      dialogs.confirm(
        {
          resolve: {
            object () {
              return {
                title: _t('app.admin.members.confirmation_required'),
                msg: $sce.trustAsHtml(_t('app.admin.members.delete_this_manager') + '<br/><br/>' + _t('app.admin.members.this_may_take_a_while_please_wait'))
              };
            }
          }
        },
        function () { // cancel confirmed
          User.delete(
            { id: manager.id },
            function () {
              managers.splice(findItemIdxById(managers, manager.id), 1);
              return growl.success(_t('app.admin.members.manager_successfully_deleted'));
            },
            function (error) {
              growl.error(_t('app.admin.members.unable_to_delete_the_manager'));
              console.error(error);
            }
          );
        }
      );
    };

    /**
     * Callback for the 'load more' button.
     * Will load the next results of the current search, if any
     */
    $scope.showNextMembers = function () {
      $scope.member.page += 1;
      return memberSearch(true);
    };

    /**
     * Callback when the search field content changes: reload the search results
     */
    $scope.updateTextSearch = function () {
      if (searchTimeout) clearTimeout(searchTimeout);
      searchTimeout = setTimeout(function () {
        resetSearchMember();
        memberSearch();
      }, 300);
    };

    /**
     * Callback when the member filter changes: reload the search results
     */
    $scope.updateMemberFilter = function () {
      resetSearchMember();
      memberSearch();
    };

    /**
     * Callback to alert the admin that the export request was acknowledged and is
     * processing right now.
     */
    $scope.alertExport = function (type) {
      Export.status({ category: 'users', type }).then(function (res) {
        if (!res.data.exists) {
          return growl.success(_t('app.admin.members.export_is_running_you_ll_be_notified_when_its_ready'));
        }
      });
    };

    /**
     * Set up the feature-tour for the admin/members page.
     * This is intended as a contextual help (when pressing F1)
     */
    $scope.setupMembersTour = function () {
      // get the tour defined by the ui-tour directive
      const uitour = uiTourService.getTourByName('members');
      uitour.createStep({
        selector: 'body',
        stepId: 'welcome',
        order: 0,
        title: _t('app.admin.tour.members.welcome.title'),
        content: _t('app.admin.tour.members.welcome.content'),
        placement: 'bottom',
        orphan: true
      });
      uitour.createStep({
        selector: '.members-management .members-list',
        stepId: 'list',
        order: 1,
        title: _t('app.admin.tour.members.list.title'),
        content: _t('app.admin.tour.members.list.content'),
        placement: 'top'
      });
      uitour.createStep({
        selector: '.members-management .search-members',
        stepId: 'search',
        order: 2,
        title: _t('app.admin.tour.members.search.title'),
        content: _t('app.admin.tour.members.search.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: '.members-management .filter-members',
        stepId: 'filter',
        order: 3,
        title: _t('app.admin.tour.members.filter.title'),
        content: _t('app.admin.tour.members.filter.content'),
        placement: 'bottom'
      });
      if ($scope.members.length > 0) {
        uitour.createStep({
          selector: '.members-management .members-list .buttons',
          stepId: 'actions',
          order: 4,
          title: _t('app.admin.tour.members.actions.title'),
          content: _t('app.admin.tour.members.actions.content'),
          placement: 'left'
        });
      }
      if (AuthService.isAuthorized('admin')) {
        uitour.createStep({
          selector: '.members-management .exports-buttons',
          stepId: 'exports',
          order: 5,
          title: _t('app.admin.tour.members.exports.title'),
          content: _t('app.admin.tour.members.exports.content'),
          placement: 'bottom'
        });
        uitour.createStep({
          selector: '.heading .import-members',
          stepId: 'import',
          order: 6,
          title: _t('app.admin.tour.members.import.title'),
          content: _t('app.admin.tour.members.import.content'),
          placement: 'left'
        });
      }
      uitour.createStep({
        selector: '.members-management .admins-tab',
        stepId: 'admins',
        order: 7,
        title: _t('app.admin.tour.members.admins.title'),
        content: _t('app.admin.tour.members.admins.content'),
        placement: 'bottom'
      });
      if (AuthService.isAuthorized('admin')) {
        uitour.createStep({
          selector: '.members-management .groups-tab',
          stepId: 'groups',
          order: 8,
          title: _t('app.admin.tour.members.groups.title'),
          content: _t('app.admin.tour.members.groups.content'),
          placement: 'bottom'
        });
        uitour.createStep({
          selector: '.members-management .labels-tab',
          stepId: 'labels',
          order: 9,
          title: _t('app.admin.tour.members.labels.title'),
          content: _t('app.admin.tour.members.labels.content'),
          placement: 'bottom'
        });
        uitour.createStep({
          selector: '.members-management .sso-tab',
          stepId: 'sso',
          order: 10,
          title: _t('app.admin.tour.members.sso.title'),
          content: _t('app.admin.tour.members.sso.content'),
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
        if (nextStep.stepId === 'list' || nextStep.stepId === 'import') {
          $scope.tabs.active = 0;
          $scope.tabs.sub = 0;
        }
        if (nextStep.stepId === 'admins') {
          $scope.tabs.active = 0;
          $scope.tabs.sub = 1;
        }
        if (nextStep.stepId === 'groups') {
          $scope.tabs.active = 1;
        }
        if (nextStep.stepId === 'labels') {
          $scope.tabs.active = 2;
        }
        if (nextStep.stepId === 'sso') {
          $scope.tabs.active = 3;
        }
      });
      // on tour end, save the status in database
      uitour.on('ended', function () {
        if (uitour.getStatus() === uitour.Status.ON && $scope.currentUser.profile.tours.indexOf('members') < 0) {
          Member.completeTour({ id: $scope.currentUser.id }, { tour: 'members' }, function (res) {
            $scope.currentUser.profile.tours = res.tours;
          });
        }
      });
      // if the user has never seen the tour, show him now
      if (settingsPromise.feature_tour_display !== 'manual' && $scope.currentUser.profile.tours.indexOf('members') < 0) {
        uitour.start();
      }
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      if (!membersPromise[0] || (membersPromise[0].maxMembers <= $scope.members.length)) {
        return $scope.member.noMore = true;
      }
    };

    /**
     * Will temporize the search query to prevent overloading the API
     */
    let searchTimeout = null;

    /**
     * Iterate through the provided array and return the index of the requested item
     * @param items {Array} full list of users with the 'admin' role
     * @param id {Number} id of the item to retrieve in the list
     * @returns {Number} index of the requested item, in the provided array
     */
    const findItemIdxById = function (items, id) {
      return (items.map(function (item) { return item.id; })).indexOf(id);
    };

    /**
     * Reinitialize the context of the search to display new results set
     */
    const resetSearchMember = function () {
      $scope.member.noMore = false;
      $scope.member.page = 1;
    };

    /**
     * Run a search query with the current parameters set ($scope.member[searchText,order,page])
     * and affect or append the result in $scope.members, depending on the concat parameter
     * @param [concat] {boolean} if true, the result will be appended to $scope.members instead of being replaced
     */
    const memberSearch = function (concat) {
      Member.list({
        query: {
          search: $scope.member.searchText,
          order_by: $scope.member.order,
          filter: $scope.member.memberFilter,
          page: $scope.member.page,
          size: USERS_PER_PAGE
        }
      }, function (members) {
        if (concat) {
          $scope.members = $scope.members.concat(members);
        } else {
          $scope.members = members;
        }

        if (!members[0] || (members[0].maxMembers <= $scope.members.length)) {
          return $scope.member.noMore = true;
        }
      });
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

/**
 * Controller used in the member edition page
 */
Application.Controllers.controller('EditMemberController', ['$scope', '$state', '$stateParams', 'Member', 'Training', 'dialogs', 'growl', 'Group', 'Subscription', 'CSRF', 'memberPromise', 'tagsPromise', '$uibModal', 'Plan', '$filter', '_t', 'walletPromise', 'transactionsPromise', 'activeProviderPromise', 'Wallet', 'settingsPromise',
  function ($scope, $state, $stateParams, Member, Training, dialogs, growl, Group, Subscription, CSRF, memberPromise, tagsPromise, $uibModal, Plan, $filter, _t, walletPromise, transactionsPromise, activeProviderPromise, Wallet, settingsPromise) {
  /* PUBLIC SCOPE */

    // API URL where the form will be posted
    $scope.actionUrl = `/api/members/${$stateParams.id}`;

    // Form action on the above URL
    $scope.method = 'patch';

    // List of tags joinable with user
    $scope.tags = tagsPromise;

    // The user to edit
    $scope.user = memberPromise;

    // Should the password be modified?
    $scope.password = { change: false };

    // is the phone number required in _member_form?
    $scope.phoneRequired = (settingsPromise.phone_required === 'true');

    // is the address required in _member_form?
    $scope.addressRequired = (settingsPromise.address_required === 'true');

    // the user subscription
    if (($scope.user.subscribed_plan != null) && ($scope.user.subscription != null)) {
      $scope.subscription = $scope.user.subscription;
    } else {
      Plan.query({ group_id: $scope.user.group_id }, function (plans) {
        $scope.plans = plans;
        return Array.from($scope.plans).map(function (plan) {
          return (plan.nameToDisplay = $filter('humanReadablePlanName')(plan));
        });
      });
    }

    // Available trainings list
    $scope.trainings = [];

    // Profiles types (student/standard/...)
    $scope.groups = [];

    // the user wallet
    $scope.wallet = walletPromise;

    // user wallet transactions
    $scope.transactions = transactionsPromise;

    // used in wallet partial template to identify parent view
    $scope.view = 'member_edit';

    // current active authentication provider
    $scope.activeProvider = activeProviderPromise;

    /**
     * Open a modal dialog asking for confirmation to change the role of the given user
     * @returns {*}
     */
    $scope.changeUserRole = function () {
      const modalInstance = $uibModal.open({
        animation: true,
        templateUrl: '/admin/members/change_role_modal.html',
        size: 'lg',
        resolve: {
          user () { return $scope.user; }
        },
        controller: ['$scope', '$uibModalInstance', 'Member', 'user', '_t', function ($scope, $uibModalInstance, Member, user, _t) {
          $scope.user = user;

          $scope.role = user.role;

          $scope.roles = [
            { key: 'admin', label: _t('app.admin.members_edit.admin') },
            { key: 'manager', label: _t('app.admin.members_edit.manager'), notAnOption: (user.role === 'admin') },
            { key: 'member', label: _t('app.admin.members_edit.member'), notAnOption: (user.role === 'admin' || user.role === 'manager') }
          ];

          $scope.ok = function () {
            Member.updateRole(
              { id: $scope.user.id },
              { role: $scope.role },
              function (_res) {
                growl.success(_t('app.admin.members_edit.role_changed', { OLD: _t(`app.admin.members_edit.${user.role}`), NEW: _t(`app.admin.members_edit.${$scope.role}`) }));
                return $uibModalInstance.close(_res);
              },
              function (error) {
                growl.error(_t('app.admin.members_edit.error_while_changing_role'));
                console.error(error);
              }
            );
          };

          $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };
        }]
      });
      // once the form was validated successfully ...
      return modalInstance.result.then(function (user) {
        // remove the user for the old list add to the new
      });
    };

    /**
     * Open a modal dialog, allowing the admin to extend the current user's subscription (freely or not)
     * @param subscription {Object} User's subscription object
     * @param free {boolean} True if the extent is offered, false otherwise
     */
    $scope.updateSubscriptionModal = function (subscription, free) {
      const modalInstance = $uibModal.open({
        animation: true,
        templateUrl: '/admin/subscriptions/expired_at_modal.html',
        size: 'lg',
        controller: ['$scope', '$uibModalInstance', 'Subscription', function ($scope, $uibModalInstance, Subscription) {
          $scope.new_expired_at = angular.copy(subscription.expired_at);
          $scope.free = free;
          $scope.datePicker = {
            opened: false,
            format: Fablab.uibDateFormat,
            options: {
              startingDay: Fablab.weekStartingDay
            },
            minDate: new Date()
          };

          $scope.openDatePicker = function (ev) {
            ev.preventDefault();
            ev.stopPropagation();
            return $scope.datePicker.opened = true;
          };

          $scope.ok = function () {
            Subscription.update(
              { id: subscription.id },
              { subscription: { expired_at: $scope.new_expired_at, free } },
              function (_subscription) {
                growl.success(_t('app.admin.members_edit.you_successfully_changed_the_expiration_date_of_the_user_s_subscription'));
                return $uibModalInstance.close(_subscription);
              },
              function (error) {
                growl.error(_t('app.admin.members_edit.a_problem_occurred_while_saving_the_date'));
                console.error(error);
              }
            );
          };

          $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };
        }]
      });
      // once the form was validated successfully ...
      return modalInstance.result.then(function (subscription) { $scope.subscription.expired_at = subscription.expired_at; });
    };

    /**
     * Open a modal dialog allowing the admin to set a subscription for the given user.
     * @param user {Object} User object, user currently reviewed, as recovered from GET /api/members/:id
     * @param plans {Array} List of plans, available for the currently reviewed user, as recovered from GET /api/plans
     */
    $scope.createSubscriptionModal = function (user, plans) {
      const modalInstance = $uibModal.open({
        animation: true,
        templateUrl: '/admin/subscriptions/create_modal.html',
        size: 'lg',
        controller: ['$scope', '$uibModalInstance', 'Subscription', function ($scope, $uibModalInstance, Subscription) {
          // selected user
          $scope.user = user;

          // available plans for the selected user
          $scope.plans = plans;

          // default parameters for the new subscription
          $scope.subscription = {
            payment_schedule: false,
            payment_method: 'check'
          };

          /**
           * Generate a string identifying the given plan by literal human-readable name
           * @param plan {Object} Plan object, as recovered from GET /api/plan/:id
           * @param groups {Array} List of Groups objects, as recovered from GET /api/groups
           * @param short {boolean} If true, the generated name will contain the group slug, otherwise the group full name
           * will be included.
           * @returns {String}
           */
          $scope.humanReadablePlanName = function (plan, groups, short) { return `${$filter('humanReadablePlanName')(plan, groups, short)}`; };

          /**
           * Check if the currently selected plan can be paid with a payment schedule or not
           * @return {boolean}
           */
          $scope.allowMonthlySchedule = function () {
            if (!$scope.subscription) return false;

            const plan = plans.find(p => p.id === $scope.subscription.plan_id);
            return plan && plan.monthly_payment;
          };

          /**
           * Triggered by the <switch> component.
           * We must use a setTimeout to workaround the react integration.
           * @param checked {Boolean}
           */
          $scope.toggleSchedule = function (checked) {
            setTimeout(() => {
              $scope.subscription.payment_schedule = checked;
              $scope.$apply();
            }, 50);
          };

          /**
           * Modal dialog validation callback
           */
          $scope.ok = function () {
            $scope.subscription.user_id = user.id;
            return Subscription.save({ }, { subscription: $scope.subscription }, function (_subscription) {
              growl.success(_t('app.admin.members_edit.subscription_successfully_purchased'));
              $uibModalInstance.close(_subscription);
              return $state.reload();
            }
            , function (error) {
              growl.error(_t('app.admin.members_edit.a_problem_occurred_while_taking_the_subscription'));
              console.error(error);
            });
          };

          /**
           * Modal dialog cancellation callback
           */
          $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };
        }]
      });
      // once the form was validated successfully ...
      return modalInstance.result.then(function (subscription) { $scope.subscription = subscription; });
    };

    $scope.createWalletCreditModal = function (user, wallet) {
      const modalInstance = $uibModal.open({
        animation: true,
        templateUrl: '/wallet/credit_modal.html',
        controller: ['$scope', '$uibModalInstance', 'Wallet', function ($scope, $uibModalInstance, Wallet) {
        // default: do not generate a refund invoice
          $scope.generate_avoir = false;

          // date of the generated refund invoice
          $scope.avoir_date = null;

          // optional description shown on the refund invoice
          $scope.description = '';

          // default configuration for the avoir date selector widget
          $scope.datePicker = {
            format: Fablab.uibDateFormat,
            opened: false,
            options: {
              startingDay: Fablab.weekStartingDay
            }
          };

          /**
           * Callback to open/close the date picker
           */
          $scope.toggleDatePicker = function ($event) {
            $event.preventDefault();
            $event.stopPropagation();
            return $scope.datePicker.opened = !$scope.datePicker.opened;
          };

          /**
           * Modal dialog validation callback
           */
          $scope.ok = function () {
            Wallet.credit(
              { id: wallet.id },
              {
                amount: $scope.amount,
                avoir: $scope.generate_avoir,
                avoir_date: $scope.avoir_date,
                avoir_description: $scope.description
              },
              function (_wallet) {
                growl.success(_t('app.shared.wallet.wallet_credit_successfully'));
                return $uibModalInstance.close(_wallet);
              },
              function (error) {
                growl.error(_t('app.shared.wallet.a_problem_occurred_for_wallet_credit'));
                console.error(error);
              }
            );
          };

          /**
           * Modal dialog cancellation callback
           */
          $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };
        }
        ]
      });
      // once the form was validated successfully...
      return modalInstance.result.then(function (wallet) {
        $scope.wallet = wallet;
        return Wallet.transactions({ id: wallet.id }, function (transactions) { $scope.transactions = transactions; });
      });
    };

    /**
     * To use as callback in Array.prototype.filter to get only enabled plans
     */
    $scope.filterDisabledPlans = function (plan) { return !plan.disabled; };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      CSRF.setMetaTags();

      // init the birthdate to JS object
      $scope.user.statistic_profile.birthday = moment($scope.user.statistic_profile.birthday).toDate();

      // the user subscription
      if (($scope.user.subscribed_plan != null) && ($scope.user.subscription != null)) {
        $scope.subscription = $scope.user.subscription;
      } else {
        Plan.query({ group_id: $scope.user.group_id }, function (plans) {
          $scope.plans = plans;
          return Array.from($scope.plans).map(function (plan) {
            return (plan.nameToDisplay = `${plan.base_name} - ${plan.interval}`);
          });
        });
      }

      // Using the MembersController
      return new MembersController($scope, $state, Group, Training);
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

/**
 * Controller used in the member's creation page (admin view)
 */
Application.Controllers.controller('NewMemberController', ['$scope', '$state', '$stateParams', 'Member', 'Training', 'Group', 'CSRF', 'settingsPromise',
  function ($scope, $state, $stateParams, Member, Training, Group, CSRF, settingsPromise) {
    CSRF.setMetaTags();

    /* PUBLIC SCOPE */

    // API URL where the form will be posted
    $scope.actionUrl = '/api/members';

    // Form action on the above URL
    $scope.method = 'post';

    // Should the password be set manually or generated?
    $scope.password = { change: false };

    // is the phone number required in _member_form?
    $scope.phoneRequired = (settingsPromise.phone_required === 'true');

    // is the address required to sign-up?
    $scope.addressRequired = (settingsPromise.address_required === 'true');

    // Default member's profile parameters
    $scope.user = {
      plan_interval: '',
      invoicing_profile: {},
      statistic_profile: {}
    };

    // Callback when the admin check/uncheck the box telling that the new user is an organization.
    // Disable or enable the organization fields in the form, accordingly
    $scope.toggleOrganization = function () {
      if ($scope.user.organization) {
        if (!$scope.user.invoicing_profile) { $scope.user.invoicing_profile = {}; }
        $scope.user.invoicing_profile.organization = {};
      } else {
        $scope.user.invoicing_profile.organization = undefined;
      }
    };

    // Using the MembersController
    return new MembersController($scope, $state, Group, Training);
  }
]);

/**
 * Controller used in the member's import page: import from CSV (admin view)
 */
Application.Controllers.controller('ImportMembersController', ['$scope', '$state', 'Group', 'Training', 'CSRF', 'tags', 'growl',
  function ($scope, $state, Group, Training, CSRF, tags, growl) {
    CSRF.setMetaTags();

    /* PUBLIC SCOPE */

    // API URL where the form will be posted
    $scope.actionUrl = '/api/imports/members';

    // Form action on the above URL
    $scope.method = 'post';

    // List of all tags
    $scope.tags = tags;

    /*
     * Callback run after the form was submitted
     * @param content {*} The result provided by the server, may be an Import object, or an error message
     */
    $scope.onImportResult = function (content) {
      if (content.id) {
        $state.go('app.admin.members_import_result', { id: content.id });
      } else {
        growl.error(JSON.stringify(content));
      }
    };

    // Using the MembersController
    return new MembersController($scope, $state, Group, Training);
  }
]);

/**
 * Controller used in the member's import results page (admin view)
 */
Application.Controllers.controller('ImportMembersResultController', ['$scope', '$state', 'Import', 'importItem',
  function ($scope, $state, Import, importItem) {
    /* PUBLIC SCOPE */

    // Current import as saved in database
    $scope.import = importItem;

    // Current import results
    $scope.results = null;

    /**
     * Changes the view of the admin to the members import page
     */
    $scope.cancel = function () { $state.go('app.admin.members_import'); };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      $scope.results = JSON.parse($scope.import.results);
      if (!$scope.results) {
        setTimeout(function () {
          Import.get({ id: $scope.import.id }, function (data) {
            $scope.import = data;
            initialize();
          });
        }, 5000);
      }
    };

    // !!! MUST BE CALLED AT THE END of the controller
    initialize();
  }
]);

/**
 * Controller used in the admin creation page (admin view)
 */
Application.Controllers.controller('NewAdminController', ['$state', '$scope', 'Admin', 'growl', '_t', 'settingsPromise',
  function ($state, $scope, Admin, growl, _t, settingsPromise) {
  // default admin profile
    let getGender;
    $scope.admin = {
      statistic_profile_attributes: {
        gender: true
      },
      profile_attributes: {},
      invoicing_profile_attributes: {}
    };

    // Default parameters for AngularUI-Bootstrap datepicker
    $scope.datePicker = {
      format: Fablab.uibDateFormat,
      opened: false,
      options: {
        startingDay: Fablab.weekStartingDay
      }
    };

    // is the phone number required in _admin_form?
    $scope.phoneRequired = (settingsPromise.phone_required === 'true');

    // is the address required in _admin_form?
    $scope.addressRequired = (settingsPromise.address_required === 'true');

    /**
   * Shows the birthday datepicker
   */
    $scope.openDatePicker = function () { $scope.datePicker.opened = true; };

    /**
   * Send the new admin, currently stored in $scope.admin, to the server for database saving
   */
    $scope.saveAdmin = function () {
      Admin.save(
        {},
        { admin: $scope.admin },
        function () {
          growl.success(_t('app.admin.admins_new.administrator_successfully_created_he_will_receive_his_connection_directives_by_email', { GENDER: getGender($scope.admin) }));
          return $state.go('app.admin.members');
        }
        , function (error) {
          growl.error(_t('app.admin.admins_new.failed_to_create_admin') + JSON.stringify(error.data ? error.data : error));
          console.error(error);
        }
      );
    };

    /* PRIVATE SCOPE */

    /**
   * Return an enumerable meaningful string for the gender of the provider user
   * @param user {Object} Database user record
   * @return {string} 'male' or 'female'
   */
    return getGender = function (user) {
      if (user.statistic_profile_attributes) {
        if (user.statistic_profile_attributes.gender) { return 'male'; } else { return 'female'; }
      } else { return 'other'; }
    };
  }

]);

/**
 * Controller used in the manager's creation page (admin view)
 */
Application.Controllers.controller('NewManagerController', ['$state', '$scope', 'User', 'groupsPromise', 'tagsPromise', 'growl', '_t',
  function ($state, $scope, User, groupsPromise, tagsPromise, growl, _t) {
  // default admin profile
    $scope.manager = {
      statistic_profile_attributes: {
        gender: true
      },
      profile_attributes: {},
      invoicing_profile_attributes: {}
    };

    // Default parameters for AngularUI-Bootstrap datepicker
    $scope.datePicker = {
      format: Fablab.uibDateFormat,
      opened: false,
      options: {
        startingDay: Fablab.weekStartingDay
      }
    };

    // list of all groups
    $scope.groups = groupsPromise.filter(function (g) { return (g.slug !== 'admins') && !g.disabled; });

    // list of all tags
    $scope.tags = tagsPromise;

    /**
   * Shows the birthday datepicker
   */
    $scope.openDatePicker = function () { $scope.datePicker.opened = true; };

    /**
   * Send the new manager, currently stored in $scope.manager, to the server for database saving
   */
    $scope.saveManager = function () {
      User.save(
        {},
        { manager: $scope.manager },
        function () {
          growl.success(_t('app.admin.manager_new.manager_successfully_created', { GENDER: getGender($scope.manager) }));
          return $state.go('app.admin.members');
        }
        , function (error) {
          growl.error(_t('app.admin.admins_new.failed_to_create_manager') + JSON.stringify(error.data ? error.data : error));
          console.error(error);
        }
      );
    };

    /* PRIVATE SCOPE */

    /**
   * Return an enumerable meaningful string for the gender of the provider user
   * @param user {Object} Database user record
   * @return {string} 'male' or 'female'
   */
    const getGender = function (user) {
      if (user.statistic_profile_attributes) {
        if (user.statistic_profile_attributes.gender) { return 'male'; } else { return 'female'; }
      } else { return 'other'; }
    };
  }

]);
