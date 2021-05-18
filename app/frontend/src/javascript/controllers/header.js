'use strict';

Application.Controllers.controller('HeaderController', ['$scope', '$rootScope', '$state',
  function ($scope, $rootScope, $state) {
    $scope.aboutPage = ($state.current.name === 'app.public.about');

    $rootScope.$on('$stateChangeStart', function (event, toState) {
      $scope.aboutPage = (toState.name === 'app.public.about');
    });
  }
]);
