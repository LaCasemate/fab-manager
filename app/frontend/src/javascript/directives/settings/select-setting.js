Application.Directives.directive('selectSetting', ['Setting', 'growl', '_t',
  function (Setting, growl, _t) {
    return ({
      restrict: 'E',
      scope: {
        name: '@',
        label: '@',
        settings: '=',
        classes: '@',
        required: '<',
        option1: '<',
        option2: '<',
        option3: '<',
        option4: '<',
        option5: '<'
      },
      templateUrl: '/admin/settings/select.html',
      link ($scope, element, attributes) {
        // The setting
        $scope.setting = {
          name: $scope.name,
          value: $scope.settings[$scope.name]
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
