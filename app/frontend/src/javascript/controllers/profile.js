/* eslint-disable
    no-return-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */

'use strict';

Application.Controllers.controller('CompleteProfileController', ['$scope', '$rootScope', '$state', '$window', '_t', 'growl', 'CSRF', 'Auth', 'Member', 'settingsPromise', 'activeProviderPromise', 'groupsPromise', 'cguFile', 'memberPromise', 'Session', 'dialogs', 'AuthProvider',
  function ($scope, $rootScope, $state, $window, _t, growl, CSRF, Auth, Member, settingsPromise, activeProviderPromise, groupsPromise, cguFile, memberPromise, Session, dialogs, AuthProvider) {
  /* PUBLIC SCOPE */

    // API URL where the form will be posted
    $scope.actionUrl = `/api/members/${memberPromise.id}`;

    // Form action on the above URL
    $scope.method = 'patch';

    // genre of the application name (eg. "_le_ Fablab" or "_la_ Fabrique")
    $scope.nameGenre = settingsPromise.name_genre;

    // name of the current fablab application (eg. "Fablab de la Casemate")
    $scope.fablabName = settingsPromise.fablab_name;

    // information from the current SSO provider
    $scope.activeProvider = activeProviderPromise;

    // list of user's groups (student/standard/...)
    $scope.groups = groupsPromise;

    // current user, contains information retrieved from the SSO
    $scope.user = memberPromise;

    // disallow the user to change his password as he connect from SSO
    $scope.preventPassword = true;

    // mapping of fields to disable
    $scope.preventField = {};

    // CGU
    $scope.cgu = cguFile.custom_asset;

    // is the phone number required in _member_form?
    $scope.phoneRequired = (settingsPromise.phone_required === 'true');

    // is the address required in _member_form?
    $scope.addressRequired = (settingsPromise.address_required === 'true');

    // Angular-Bootstrap datepicker configuration for birthday
    $scope.datePicker = {
      format: Fablab.uibDateFormat,
      opened: false, // default: datePicker is not shown
      options: {
        startingDay: Fablab.weekStartingDay
      }
    };

    /**
     * Callback to diplay the datepicker as a dropdown when clicking on the input field
     * @param $event {Object} jQuery event object
     */
    $scope.openDatePicker = function ($event) {
      $event.preventDefault();
      $event.stopPropagation();
      return $scope.datePicker.opened = true;
    };

    /**
     * For use with ngUpload (https://github.com/twilson63/ngUpload).
     * Intended to be the callback when the upload is done: any raised error will be stacked in the
     * $scope.alerts array. If everything goes fine, the user's profile is updated and the user is
     * redirected to the home page
     * @param content {Object} JSON - The upload's result
     */
    $scope.submited = function (content) {
      if ((content.id == null)) {
        $scope.alerts = [];
        angular.forEach(content, function (v, k) {
          angular.forEach(v, function (err) {
            $scope.alerts.push({
              msg: k + ': ' + err,
              type: 'danger'
            });
          });
        });
      } else {
        $scope.user.profile.user_avatar = content.profile.user_avatar;
        Auth._currentUser.profile.user_avatar = content.profile.user_avatar;
        $scope.user.name = content.name;
        Auth._currentUser.name = content.name;
        $scope.user = content;
        Auth._currentUser = content;
        $rootScope.currentUser = content;
        return $state.go('app.public.home');
      }
    };

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
     * Merge the current user into the account with the given auth_token
     */
    $scope.registerAuthToken = function () {
      Member.merge({ id: $rootScope.currentUser.id }, { user: { auth_token: $scope.user.auth_token } }, function (user) {
        $scope.user = user;
        Auth._currentUser = user;
        $rootScope.currentUser = user;
        $state.go('app.public.home');
      }
      , function (err) {
        if (err.data.error) {
          growl.error(err.data.error);
        } else {
          growl.error(_t('app.logged.profile_completion.an_unexpected_error_occurred_check_your_authentication_code'));
          console.error(err);
        }
      });
    };

    /**
     * Return the email given by the SSO provider, parsed if needed
     * @return {String} E-mail of the current user
     */
    $scope.ssoEmail = function () {
      const { email } = memberPromise;
      if (email) {
        const duplicate = email.match(/^<([^>]+)>.{20}-duplicate$/);
        if (duplicate) {
          return duplicate[1];
        }
      }
      return email;
    };

    /**
     * Test if the user's mail is marked as duplicate
     * @return {boolean}
     */
    $scope.hasDuplicate = function () {
      const { email } = memberPromise;
      if (email) {
        return !(email.match(/^<([^>]+)>.{20}-duplicate$/) === null);
      }
    };

    /**
     * Ask for email confirmation and send the SSO merging token again
     * @param event {Object} jQuery event object
     */
    $scope.resendCode = function (event) {
      event.preventDefault();
      event.stopPropagation();
      dialogs.confirm(
        {
          templateUrl: '/profile/resend_code_modal.html',
          resolve: {
            object () {
              return { email: memberPromise.email };
            }
          }
        },
        function (email) {
          // Request the server to send an auth-migration email to the current user
          AuthProvider.send_code({ email },
            function (res) { growl.info(_t('app.logged.profile_completion.code_successfully_sent_again')); },
            function (err) { growl.error(err.data.error); }
          );
        }
      );
    };

    /**
     * Disconnect and re-connect the user to the SSO to force the synchronisation of the profile's data
     */
    $scope.syncProfile = function () {
      Auth.logout().then(function (oldUser) {
        Session.destroy();
        $rootScope.currentUser = null;
        $rootScope.toCheckNotifications = false;
        $scope.notifications = {
          total: 0,
          unread: 0
        };
        $window.location.href = activeProviderPromise.link_to_sso_connect;
      });
    };

    /**
     * Hide the new account messages.
     * If hidden, the page will be used only to complete the current user's profile.
     */
    $scope.hideNewAccountConfirmation = function () {
      return !$scope.activeProvider.previous_provider || $scope.activeProvider.previous_provider.id === $scope.activeProvider.id;
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      CSRF.setMetaTags();

      // init the birth date to JS object
      $scope.user.statistic_profile.birthday = $scope.user.statistic_profile.birthday ? moment($scope.user.statistic_profile.birthday).toDate() : undefined;

      // bind fields protection with sso fields
      angular.forEach(activeProviderPromise.mapping, function (map) { $scope.preventField[map] = true; });
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }

]);
