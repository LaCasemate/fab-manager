/* eslint-disable
    no-return-assign,
    no-undef,
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

Application.Controllers.controller('DashboardController', ['$scope', 'memberPromise', 'trainingsPromise', 'SocialNetworks', function ($scope, memberPromise, trainingsPromise, SocialNetworks) {
  // Current user's profile
  $scope.user = memberPromise;

  // List of social networks associated with this user and toggle 'show all' state
  $scope.social = {
    showAllLinks: false,
    networks: SocialNetworks
  };

  /**
   * Check if the member has used his training credits for the given credit
   * @param trainingCredits array of credits used by the member
   * @param trainingId id of the training to find
   */
  $scope.hasUsedTrainingCredit = function (trainingCredits, trainingId) {
    return trainingCredits.find(tc => tc.training_id === trainingId);
  };

  /**
   * Return the name associated with the provided training ID
   * @param trainingId training identifier
   * @return {string}
   */
  $scope.getTrainingName = function (trainingId) {
    return trainingsPromise.find(t => t.id === trainingId).name;
  };

  /* PRIVATE SCOPE */

  /**
   * Kind of constructor: these actions will be realized first when the controller is loaded
   */
  const initialize = () => $scope.social.networks = filterNetworks();

  /**
   * Filter the social networks or websites that are associated with the profile of the user provided in promise
   * and return the filtered networks
   * @return {Array}
   */
  const filterNetworks = function () {
    const networks = [];
    for (const network of Array.from(SocialNetworks)) {
      if ($scope.user.profile[network] && ($scope.user.profile[network].length > 0)) {
        networks.push(network);
      }
    }
    return networks;
  };

  // !!! MUST BE CALLED AT THE END of the controller
  return initialize();
}

]);
