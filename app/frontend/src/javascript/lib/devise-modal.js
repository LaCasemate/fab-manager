'use strict';
// TODO remove unused?
(function (angular) {
  const deviseModal = angular.module('DeviseModal', [
    'Devise',
    'ui.bootstrap'
  ]);
  deviseModal.run([
    '$uibModal',
    '$http',
    'Auth',
    '$rootScope',
    function ($uibModal, $http, Auth, $rootScope) {
      var promise = null;
      function reset () {
        promise = null;
      }
      function partial (fn, arg) {
        return function () {
          return fn.call(this, arg);
        };
      }
      $rootScope.$on('devise:unauthorized', function (event, response, deferred) {
        function retryRequestAfterLogin () {
          return promise.then(function () {
            return $http(response.config);
          }).then(deferred.resolve, partial(deferred.reject, response));
        }
        if (!promise) {
          promise = $uibModal.open({
            templateUrl: '/shared/deviseModal.html',
            controller: ['$scope', '$uibModalInstance', function ($scope, $uibModalInstance) {
              const user = $scope.user = {};
              $scope.login = function () {
                $uibModalInstance.close(user);
              };
              $scope.dismiss = function () {
                $uibModalInstance.dismiss('cancel');
              };
            }]
          }).result.finally(reset).then(Auth.login);
        }
        retryRequestAfterLogin();
      });
    }
  ]);
  deviseModal.run([
    '$templateCache',
    function ($templateCache) {
      'use strict';
      $templateCache.put('deviseModal.html', '<div id=loginModal><div class=modal-header><button type=button class=close ng-click=dismiss()>x</button><h3>Have an Account?</h3></div><div class=modal-body><div class=well><form name=loginForm><div class=form-group ng-class="{\'has-error\': emailError}"><label class=control-label>Email</label><input type=email name=email class=form-control ng-model=user.email required=required ng-blur="emailError = !!loginForm.email.$error.email" ng-focus="emailError = false"></div><div class=form-group><label class=control-label for=password>Password</label><input type=password name=password class=form-control ng-model=user.password required=required></div><button class="btn btn-primary" ng-click=login()>Login</button></form></div></div></div>');
    }
  ]);
}(angular));
