Application.Directives.directive('selectMultipleSetting', ['Setting', 'growl', '_t', '$uibModal',
  function (Setting, growl, _t, $uibModal) {
    return ({
      restrict: 'E',
      scope: {
        name: '@',
        label: '@',
        settings: '=',
        classes: '@',
        required: '<',
        titleNew: '@',
        descriptionNew: '@',
        beforeAdd: '='
      },
      templateUrl: '/admin/settings/select-multiple.html',
      link ($scope, element, attributes) {
        // The setting
        $scope.setting = {
          name: $scope.name,
          value: $scope.settings[$scope.name]
        };

        // the options
        $scope.options = $scope.settings[$scope.name].split(' ').sort();

        // the selected options
        $scope.selection = [];

        /**
         * Remove the items in the selection from the options and update setting.value
         */
        $scope.removeItem = function () {
          const options = $scope.options.filter(function (opt) {
            return $scope.selection.indexOf(opt) < 0;
          });
          $scope.options = options;
          $scope.setting.value = options.join(' ');
          growl.success(_t('app.admin.settings.COUNT_items_removed', { COUNT: $scope.selection.length }));
          $scope.selection = [];
        };

        /**
         * Open a modal dialog asking for the value of a new item to add
         */
        $scope.addItem = function () {
          $uibModal.open({
            templateUrl: '/admin/settings/newSelectOption.html',
            resolve: {
              titleNew: function () { return $scope.titleNew; },
              descriptionNew: function () { return $scope.descriptionNew; }
            },
            controller: ['$scope', '$uibModalInstance', 'titleNew', 'descriptionNew',
              function ($scope, $uibModalInstance, titleNew, descriptionNew) {
                $scope.value = undefined;
                $scope.titleNew = titleNew;
                $scope.descriptionNew = descriptionNew;
                $scope.ok = function () {
                  $uibModalInstance.close($scope.value);
                };
                $scope.dismiss = function () {
                  $uibModalInstance.dismiss('cancel');
                };
              }]
          }).result.finally(null).then(function (val) {
            const options = Array.from($scope.options);
            if (typeof $scope.beforeAdd === 'function') { val = $scope.beforeAdd(val); }
            options.push(val);
            $scope.options = options;
            $scope.setting.value = options.join(' ');
            growl.success(_t('app.admin.settings.item_added'));
          });
        };

        /**
         * Callback to save the setting value to the database
         * @param setting {{value:*, name:string}} note that the value will be stringified
         */
        $scope.save = function (setting) {
          const { value } = setting;

          Setting.update(
            { name: setting.name },
            { value },
            function () {
              growl.success(_t('app.admin.settings.customization_of_SETTING_successfully_saved', { SETTING: _t(`app.admin.settings.${setting.name}`) }));
              $scope.settings[$scope.name] = value;
            },
            function (error) {
              if (error.status === 304) return;

              if (error.status === 423) {
                growl.error(_t('app.admin.settings.error_SETTING_locked', { SETTING: _t(`app.admin.settings.${setting.name}`) }));
                return;
              }

              growl.error(_t('app.admin.settings.an_error_occurred_saving_the_setting'));
              console.log(error);
            }
          );
        };
      }
    });
  }
]);
