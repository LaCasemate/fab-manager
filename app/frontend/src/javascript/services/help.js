'use strict';

Application.Services.factory('Help', ['$rootScope', '$uibModal', '$state', 'AuthService',
  function ($rootScope, $uibModal, $state, AuthService) {
    const TOURS = {
      'app.public.home': 'welcome',
      'app.public.machines_list': 'machines',
      'app.public.spaces_list': 'spaces',
      'app.admin.trainings': 'trainings',
      'app.admin.calendar': 'calendar',
      'app.admin.members': 'members',
      'app.admin.invoices': 'invoices',
      'app.admin.pricing': 'pricing',
      'app.admin.events': 'events',
      'app.admin.projects': 'projects',
      'app.admin.statistics': 'statistics',
      'app.admin.settings': 'settings',
      'app.admin.open_api_clients': 'open-api'
    };

    return function (e) {
      if (!AuthService.isAuthorized(['admin', 'manager'])) return;

      if (e.key === 'F1') {
        e.preventDefault();
        // retrieve the tour name, based on the current location
        const tourName = TOURS[$state.current.name];

        // if no tour, just open the guide
        if (tourName === undefined) {
          return window.open('https://github.com/sleede/fab-manager/raw/master/doc/fr/guide_utilisation_fab_manager_v4.7.pdf', '_blank');
        }

        $uibModal.open({
          animation: true,
          templateUrl: '/shared/help_modal.html',
          resolve: {
            tourName: function () { return tourName; }
          },
          controller: ['$scope', '$uibModalInstance', 'uiTourService', 'tourName', function ($scope, $uibModalInstance, uiTourService, tourName) {
          // start the tour and hide the modal
            $scope.onTour = function () {
              const tour = uiTourService.getTourByName(tourName);
              if (tour) { tour.start(); }

              $uibModalInstance.close('tour');
            };

            // open the user's guide and hide the modal
            $scope.onGuide = function () {
              $uibModalInstance.close('guide');
            };
          }]
        });
      }
    };
  }]);
