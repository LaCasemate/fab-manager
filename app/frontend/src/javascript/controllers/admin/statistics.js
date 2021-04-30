/* eslint-disable
    no-constant-condition,
    no-return-assign,
    no-undef,
    standard/no-callback-literal,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

Application.Controllers.controller('StatisticsController', ['$scope', '$state', '$rootScope', '$uibModal', 'es', 'Member', '_t', 'membersPromise', 'statisticsPromise', 'uiTourService', 'settingsPromise',
  function ($scope, $state, $rootScope, $uibModal, es, Member, _t, membersPromise, statisticsPromise, uiTourService, settingsPromise) {
  /* PRIVATE STATIC CONSTANTS */

    // search window size
    const RESULTS_PER_PAGE = 20;

    // keep search context for (delay in minutes) ...
    const ES_SCROLL_TIME = 1;

    /* PUBLIC SCOPE */

    // ui-view transitions optimization: if true, the stats will never be refreshed
    $scope.preventRefresh = false;

    // statistics structure in elasticSearch
    $scope.statistics = statisticsPromise;

    // fablab users list
    $scope.members = membersPromise;

    // statistics data recovered from elasticSearch
    $scope.data = null;

    // when did the search was triggered
    $scope.searchDate = null;

    // id of the elastic search context
    $scope.scrollId = null;

    // total number of results for the current query
    $scope.totalHits = null;

    // configuration of the widget allowing to pick the ages range
    $scope.agePicker = {
      show: false,
      start: null,
      end: null
    };

    // total CA for the current view
    $scope.sumCA = 0;

    // average users' age for the current view
    $scope.averageAge = 0;

    // total of the stat field for non simple types
    $scope.sumStat = 0;

    // Results of custom aggregations for the current type
    $scope.customAggs = {};

    // default: results are not sorted
    $scope.sorting = {
      ca: 'none',
      date: 'desc'
    };

    // active tab will be set here
    $scope.selectedIndex = null;

    // ui-bootstrap active tab index
    $scope.selectedTab = 0;

    // type filter binding
    $scope.type = {
      selected: null,
      active: null
    };

    // selected custom filter
    $scope.customFilter = {
      show: false,
      criterion: {},
      value: null,
      exclude: false,
      datePicker: {
        format: Fablab.uibDateFormat,
        opened: false, // default: datePicker is not shown
        minDate: null,
        maxDate: moment().toDate(),
        options: {
          startingDay: Fablab.weekStartingDay
        }
      }
    };

    // available custom filters
    $scope.filters = [];

    // default: we do not open the datepicker menu
    $scope.datePicker =
    { show: false };

    // datePicker parameters for interval beginning
    $scope.datePickerStart = {
      format: Fablab.uibDateFormat,
      opened: false, // default: datePicker is not shown
      minDate: null,
      maxDate: moment().subtract(1, 'day').toDate(),
      selected: moment().utc().subtract(1, 'months').subtract(1, 'day').startOf('day').toDate(),
      options: {
        startingDay: Fablab.weekStartingDay
      }
    };

    // datePicker parameters for interval ending
    $scope.datePickerEnd = {
      format: Fablab.uibDateFormat,
      opened: false, // default: datePicker is not shown
      minDate: null,
      maxDate: moment().subtract(1, 'day').toDate(),
      selected: moment().subtract(1, 'day').endOf('day').toDate(),
      options: {
        startingDay: Fablab.weekStartingDay
      }
    };

    /**
     * Return a localized name for the given field
     */
    $scope.customFieldName = function (field) {
      return _t(`app.admin.statistics.${field}`);
    };

    /**
     * Callback to open the datepicker (interval start)
     * @param $event {Object} jQuery event object
     */
    $scope.toggleStartDatePicker = function ($event) { toggleDatePicker($event, $scope.datePickerStart); };

    /**
     * Callback to open the datepicker (interval end)
     * @param $event {Object} jQuery event object
     */
    $scope.toggleEndDatePicker = function ($event) { toggleDatePicker($event, $scope.datePickerEnd); };

    /**
     * Callback to open the datepicker (custom filter)
     * @param $event {Object} jQuery event object
     */
    $scope.toggleCustomDatePicker = function ($event) { toggleDatePicker($event, $scope.customFilter.datePicker); };

    /**
     * Callback called when the active tab is changed.
     * recover the current tab and store its value in $scope.selectedIndex
     * @param tab {Object} elasticsearch statistic structure (from statistic_indices table)
     * @param index {number} index of the tab in the $scope.statistics array
     */
    $scope.setActiveTab = function (tab, index) {
      $scope.selectedIndex = tab;
      $scope.selectedTab = index;
      $scope.type.selected = tab.types[0];
      $scope.type.active = $scope.type.selected;
      $scope.customFilter.criterion = {};
      $scope.customFilter.value = null;
      $scope.customFilter.exclude = false;
      $scope.sorting.ca = 'none';
      $scope.sorting.date = 'desc';
      buildCustomFiltersList();
      return refreshStats();
    };

    /**
     * Returns true if the provided tab must be hidden due to some global or local configuration
     * @param tab {Object} elasticsearch statistic structure (from statistic_indices table)
     */
    $scope.hiddenTab = function (tab) {
      if (tab.table) {
        return ((tab.es_type_key === 'subscription' && !$rootScope.modules.plans) ||
          (tab.es_type_key === 'training' && !$rootScope.modules.trainings) ||
          (tab.es_type_key === 'space' && !$rootScope.modules.spaces)
        );
      } else {
        return true;
      }
    };

    /**
     * Callback to validate the filters and send a new request to elastic
     */
    $scope.validateFilterChange = function () {
      $scope.agePicker.show = false;
      $scope.customFilter.show = false;
      $scope.type.active = $scope.type.selected;
      buildCustomFiltersList();
      return refreshStats();
    };

    /**
     * Callback to validate the dates range and refresh the data from elastic
     */
    $scope.validateDateChange = function () {
      $scope.datePicker.show = false;
      return refreshStats();
    };

    /**
     * Parse the given date and return a user-friendly string
     * @param date {Date} JS date or ant moment.js compatible date string
     */
    $scope.formatDate = function (date) { return moment(date).format('LL'); };

    /**
     * Parse the sex and return a user-friendly string
     * @param sex {string} 'male' | 'female'
     */
    $scope.formatSex = function (sex) {
      if (sex === 'male') {
        return _t('app.admin.statistics.man');
      }
      if (sex === 'female') {
        return _t('app.admin.statistics.woman');
      }
    };

    /**
     * Retrieve the label for the given subtype in the current type
     * @param key {string} statistic subtype key
     */
    $scope.formatSubtype = function (key) {
      let label = '';
      angular.forEach($scope.type.active.subtypes, function (subtype) {
        if (subtype.key === key) {
          return label = subtype.label;
        }
      });
      return label;
    };

    /**
     * Helper usable in ng-switch to determine the input type to display for custom filter value
     * @param filter {Object} custom filter criterion
     */
    $scope.getCustomValueInputType = function (filter) {
      if (filter && filter.values) {
        if (typeof (filter.values[0]) === 'string') {
          return filter.values[0];
        } else if (typeof (filter.values[0] === 'object')) {
          return 'input_select';
        }
      } else {
        return 'input_text';
      }
    };

    /**
     * Change the sorting order and refresh the results to match the new order
     * @param filter {Object} any filter
     */
    $scope.toggleSorting = function (filter) {
      switch ($scope.sorting[filter]) {
        case 'none': $scope.sorting[filter] = 'asc'; break;
        case 'asc': $scope.sorting[filter] = 'desc'; break;
        case 'desc': $scope.sorting[filter] = 'none'; break;
      }
      return refreshStats();
    };

    /**
     * Return the user's name from his given ID
     * @param id {number} user ID
     */
    $scope.getUserNameFromId = function (id) {
      const name = $scope.members[id];
      return (name || `ID ${id}`);
    };

    /**
     * Run a scroll query to elasticsearch to append the next packet of results to those displayed.
     * If the ES search context has expired when the user ask for more results, we re-run the whole query.
     */
    $scope.showMoreResults = function () {
    // if all results were retrieved, do nothing
      if ($scope.data.length >= $scope.totalHits) {
        return;
      }

      if (moment($scope.searchDate).add(ES_SCROLL_TIME, 'minutes').isBefore(moment())) {
      // elastic search context has expired, so we run again the whole query
        return refreshStats();
      } else {
        return es.scroll({
          scroll: ES_SCROLL_TIME + 'm',
          body: { scrollId: $scope.scrollId }
        }
        , function (error, response) {
          if (error) {
            return console.error(`Error: something unexpected occurred during elasticSearch scroll query: ${error}`);
          } else {
            $scope.scrollId = response._scroll_id;
            return $scope.data = $scope.data.concat(response.hits.hits);
          }
        });
      }
    };

    /**
     * Open a modal dialog asking the user for details about exporting the statistics tables to an excel file
     */
    $scope.exportToExcel = function () {
      const options = {
        templateUrl: '/admin/statistics/export.html',
        size: 'sm',
        controller: 'ExportStatisticsController',
        resolve: {
          dates () {
            return {
              start: $scope.datePickerStart.selected,
              end: $scope.datePickerEnd.selected
            };
          },
          query () {
            const custom = buildCustomFilterQuery();
            return buildElasticDataQuery($scope.type.active.key, custom, $scope.agePicker.start, $scope.agePicker.end, moment($scope.datePickerStart.selected), moment($scope.datePickerEnd.selected), $scope.sorting);
          },
          index () {
            return { key: $scope.selectedIndex.es_type_key };
          },
          type () {
            return { key: $scope.type.active.key };
          }
        }
      };

      return $uibModal.open(options)
        .result.finally(null).then(function (info) { console.log(info); });
    };

    /**
     * Setup the feature-tour for the admin/statistics page.
     * This is intended as a contextual help (when pressing F1)
     */
    $scope.setupStatisticsTour = function () {
      // get the tour defined by the ui-tour directive
      const uitour = uiTourService.getTourByName('statistics');
      uitour.createStep({
        selector: 'body',
        stepId: 'welcome',
        order: 0,
        title: _t('app.admin.tour.statistics.welcome.title'),
        content: _t('app.admin.tour.statistics.welcome.content'),
        placement: 'bottom',
        orphan: true
      });
      uitour.createStep({
        selector: '.heading .export-button',
        stepId: 'export',
        order: 1,
        title: _t('app.admin.tour.statistics.export.title'),
        content: _t('app.admin.tour.statistics.export.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: '.heading .charts-button',
        stepId: 'trending',
        order: 2,
        title: _t('app.admin.tour.statistics.trending.title'),
        content: _t('app.admin.tour.statistics.trending.content'),
        placement: 'left'
      });
      uitour.createStep({
        selector: 'body',
        stepId: 'conclusion',
        order: 3,
        title: _t('app.admin.tour.conclusion.title'),
        content: _t('app.admin.tour.conclusion.content'),
        placement: 'bottom',
        orphan: true
      });
      // on tour end, save the status in database
      uitour.on('ended', function () {
        if (uitour.getStatus() === uitour.Status.ON && $scope.currentUser.profile.tours.indexOf('statistics') < 0) {
          Member.completeTour({ id: $scope.currentUser.id }, { tour: 'statistics' }, function (res) {
            $scope.currentUser.profile.tours = res.tours;
          });
        }
      });
      // if the user has never seen the tour, show him now
      if (settingsPromise.feature_tour_display !== 'manual' && $scope.currentUser.profile.tours.indexOf('statistics') < 0) {
        uitour.start();
      }
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      // workaround for angular-bootstrap::tabs behavior: on tab deletion, another tab will be selected
      // which will cause every tabs to reload, one by one, when the view is closed
      $rootScope.$on('$stateChangeStart', function (event, toState, toParams, fromState, fromParams) {
        if ((fromState.name === 'app.admin.statistics') && (Object.keys(fromParams).length === 0)) {
          return $scope.preventRefresh = true;
        }
      });

      // set the default tab to "machines" if "subscriptions" are disabled
      if (!$rootScope.modules.plans) {
        const idx = $scope.statistics.findIndex(s => s.es_type_key === 'machine');
        $scope.setActiveTab($scope.statistics[idx], idx);
      } else {
        const idx = $scope.statistics.findIndex(s => s.es_type_key === 'subscription');
        $scope.setActiveTab($scope.statistics[idx], idx);
      }
    };

    /**
     * Generic function to toggle a bootstrap datePicker
     * @param $event {Object} jQuery event object
     * @param datePicker {Object} settings object of the concerned datepicker. Must have an 'opened' property
     */
    const toggleDatePicker = function ($event, datePicker) {
      $event.preventDefault();
      $event.stopPropagation();
      return datePicker.opened = !datePicker.opened;
    };

    /**
     * Force update the statistics table, querying elasticSearch according to the current config values
     */
    const refreshStats = function () {
      if ($scope.selectedIndex && !$scope.preventRefresh && $scope.type.active) {
        $scope.data = [];
        $scope.sumCA = 0;
        $scope.averageAge = 0;
        $scope.sumStat = 0;
        $scope.customAggs = {};
        $scope.totalHits = null;
        $scope.searchDate = new Date();
        let custom = buildCustomFilterQuery();
        return queryElasticStats($scope.selectedIndex.es_type_key, $scope.type.active.key, custom, function (res, err) {
          if (err) {
            return console.error(`[statisticsController::refreshStats] Unable to refresh due to ${err}`);
          } else {
            $scope.data = res.hits.hits;
            $scope.totalHits = res.hits.total;
            $scope.sumCA = res.aggregations.total_ca.value;
            $scope.averageAge = Math.round(res.aggregations.average_age.value * 100) / 100;
            $scope.sumStat = res.aggregations.total_stat.value;
            $scope.scrollId = res._scroll_id;
            return (function () {
              const result = [];
              for (custom of Array.from($scope.type.active.custom_aggregations)) {
                result.push($scope.customAggs[custom.field] = res.aggregations[custom.field].value);
              }
              return result;
            })();
          }
        });
      }
    };

    /**
     * Run the elasticSearch query to retrieve the /stats/type aggregations
     * @param index {String} elasticSearch document type (account|event|machine|project|subscription|training)
     * @param type {String} statistics type (month|year|booking|hour|user|project)
     * @param custom {{key:{string}, value:{string}}|null} custom filter property or null to disable this filter
     * @param callback {function} function be to run after results were retrieved, it will receive
     *   two parameters : results {Object}, error {String} (if any)
     */
    const queryElasticStats = function (index, type, custom, callback) {
    // handle invalid callback
      if (typeof (callback) !== 'function') {
        console.error('[statisticsController::queryElasticStats] Error: invalid callback provided');
        return;
      }

      // run query
      return es.search({
        index: 'stats',
        type: index,
        size: RESULTS_PER_PAGE,
        scroll: ES_SCROLL_TIME + 'm',
        'stat-type': type,
        'custom-query': custom ? JSON.stringify(Object.assign({ exclude: custom.exclude }, buildElasticCustomCriterion(custom))) : '',
        'start-date': moment($scope.datePickerStart.selected).format(),
        'end-date': moment($scope.datePickerEnd.selected).format(),
        body: buildElasticDataQuery(type, custom, $scope.agePicker.start, $scope.agePicker.end, moment($scope.datePickerStart.selected), moment($scope.datePickerEnd.selected), $scope.sorting)
      }
      , function (error, response) {
        if (error) {
          return callback({}, `Error: something unexpected occurred during elasticSearch query: ${error}`);
        } else {
          return callback(response);
        }
      });
    };

    /**
     * Build an object representing the content of the REST-JSON query to elasticSearch,
     * based on the provided parameters for row data recovering.
     * @param type {String} statistics type (month|year|booking|hour|user|project)
     * @param custom {{key:{string}, value:{string}}|null} custom filter property or null to disable this filter
     * @param ageMin {Number|null} filter by age: range lower value OR null to do not filter
     * @param ageMax {Number|null} filter by age: range higher value OR null to do not filter
     * @param intervalBegin {moment} statitics interval beginning (moment.js type)
     * @param intervalEnd {moment} statitics interval ending (moment.js type)
     * @param sortings {Array|null} elasticSearch criteria for sorting the results
     */
    const buildElasticDataQuery = function (type, custom, ageMin, ageMax, intervalBegin, intervalEnd, sortings) {
      const q = {
        query: {
          bool: {
            must: [
              {
                term: {
                  type: type
                }
              },
              {
                range: {
                  date: {
                    gte: intervalBegin.format(),
                    lte: intervalEnd.format()
                  }
                }
              }
            ]
          }
        }
      };
      // optional date range
      if ((typeof ageMin === 'number') && (typeof ageMax === 'number')) {
        q.query.bool.must.push({
          range: {
            age: {
              gte: ageMin,
              lte: ageMax
            }
          }
        });
      }
      // optional criterion
      if (custom) {
        const criterion = buildElasticCustomCriterion(custom);
        if (custom.exclude) {
          q.query.bool.must_not = [
            { term: criterion.match }
          ];
        } else {
          q.query.bool.must.push(criterion);
        }
      }

      if (sortings) {
        q.sort = buildElasticSortCriteria(sortings);
      }

      // aggregations (avg age & CA sum)
      q.aggs = {
        total_ca: {
          sum: {
            field: 'ca'
          }
        },
        average_age: {
          avg: {
            field: 'age'
          }
        },
        total_stat: {
          sum: {
            field: 'stat'
          }
        }
      };
      return q;
    };

    /**
     * Build the elasticSearch query DSL to match the selected cutom filter
     * @param custom {Object} if custom is empty or undefined, an empty string will be returned
     * @returns {{match:*}|string}
     */
    const buildElasticCustomCriterion = function (custom) {
      if (custom) {
        const criterion = {
          match: {}
        };
        switch ($scope.getCustomValueInputType($scope.customFilter.criterion)) {
          case 'input_date': criterion.match[custom.key] = moment(custom.value).format('YYYY-MM-DD'); break;
          case 'input_select': criterion.match[custom.key] = custom.value.key; break;
          case 'input_list': criterion.match[custom.key + '.name'] = custom.value; break;
          default: criterion.match[custom.key] = custom.value;
        }
        return criterion;
      } else {
        return '';
      }
    };

    /**
     * Parse the provided criteria array and return the corresponding elasticSearch syntax
     * @param criteria {Array} array of {key_to_sort:order}
     */
    const buildElasticSortCriteria = function (criteria) {
      const crits = [];
      angular.forEach(criteria, function (value, key) {
        if ((typeof value !== 'undefined') && (value !== null) && (value !== 'none')) {
          const c = {};
          c[key] = { order: value };
          return crits.push(c);
        }
      });
      return crits;
    };

    /**
     * Fulfill the list of available options in the custom filter panel. The list will be based on common
     * properties and on index-specific properties (additional_fields)
     */
    const buildCustomFiltersList = function () {
      $scope.filters = [
        { key: 'date', label: _t('app.admin.statistics.date'), values: ['input_date'] },
        { key: 'userId', label: _t('app.admin.statistics.user_id'), values: ['input_number'] },
        { key: 'gender', label: _t('app.admin.statistics.gender'), values: [{ key: 'male', label: _t('app.admin.statistics.man') }, { key: 'female', label: _t('app.admin.statistics.woman') }] },
        { key: 'age', label: _t('app.admin.statistics.age'), values: ['input_number'] },
        { key: 'ca', label: _t('app.admin.statistics.revenue'), values: ['input_number'] }
      ];

      // if no plans were created, there's no types for statisticIndex=subscriptions
      if ($scope.type.active) {
        $scope.filters.splice(4, 0, { key: 'subType', label: _t('app.admin.statistics.type'), values: $scope.type.active.subtypes });

        if (!$scope.type.active.simple) {
          const f = { key: 'stat', label: $scope.type.active.label, values: ['input_number'] };
          $scope.filters.push(f);
        }
      }

      return angular.forEach($scope.selectedIndex.additional_fields, function (field) {
        const filter = { key: field.key, label: field.label, values: [] };
        switch (field.data_type) {
          case 'index': filter.values.push('input_number'); break;
          case 'number': filter.values.push('input_number'); break;
          case 'date': filter.values.push('input_date'); break;
          case 'list': filter.values.push('input_list'); break;
          default: filter.values.push('input_text');
        }

        return $scope.filters.push(filter);
      });
    };

    /**
     * Build and return an object according to the custom filter set by the user, used to request elasticsearch
     * @return {Object|null}
     */
    const buildCustomFilterQuery = function () {
      let custom = null;
      if (!angular.isUndefinedOrNull($scope.customFilter.criterion) &&
        !angular.isUndefinedOrNull($scope.customFilter.criterion.key) &&
        !angular.isUndefinedOrNull($scope.customFilter.value)) {
        custom = {};
        custom.key = $scope.customFilter.criterion.key;
        custom.value = $scope.customFilter.value;
        custom.exclude = $scope.customFilter.exclude;
      }
      return custom;
    };

    // init the controller (call at the end !)
    return initialize();
  }

]);

Application.Controllers.controller('ExportStatisticsController', ['$scope', '$uibModalInstance', 'Export', 'dates', 'query', 'index', 'type', 'CSRF', 'growl', '_t',
  function ($scope, $uibModalInstance, Export, dates, query, index, type, CSRF, growl, _t) {
  // Retrieve Anti-CSRF tokens from cookies
    CSRF.setMetaTags();

    // Bindings for date range
    $scope.dates = dates;

    // Body of the query to export
    $scope.query = JSON.stringify(query);

    // API URL where the form will be posted
    $scope.actionUrl = `/stats/${index.key}/export`;

    // Key of the current search' statistic type
    $scope.typeKey = type.key;

    // Form action on the above URL
    $scope.method = 'post';

    // Anti-CSRF token to inject into the download form
    $scope.csrfToken = angular.element('meta[name="csrf-token"]')[0].content;

    // Binding of the export type (global / current)
    $scope.export =
    { type: 'current' };

    // datePicker parameters for interval beginning
    $scope.exportStart = {
      format: Fablab.uibDateFormat,
      opened: false, // default: datePicker is not shown
      minDate: null,
      maxDate: moment().subtract(1, 'day').toDate(),
      options: {
        startingDay: Fablab.weekStartingDay
      }
    };

    // datePicker parameters for interval ending
    $scope.exportEnd = {
      format: Fablab.uibDateFormat,
      opened: false, // default: datePicker is not shown
      minDate: null,
      maxDate: moment().subtract(1, 'day').toDate(),
      options: {
        startingDay: Fablab.weekStartingDay
      }
    };

    /**
     * Callback to open the datepicker (interval start)
     * @param $event {Object} jQuery event object
     */
    $scope.toggleStartDatePicker = function ($event) { $scope.exportStart.opened = !$scope.exportStart.opened; };

    /**
     * Callback to open the datepicker (interval end)
     * @param $event {Object} jQuery event object
     */
    $scope.toggleEndDatePicker = function ($event) { $scope.exportEnd.opened = !$scope.exportEnd.opened; };

    /**
     * Callback when exchanging the export type between 'global' and 'current view'
     * Adjust the query and the requesting url according to this type.
     */
    $scope.setRequest = function () {
      if ($scope.export.type === 'global') {
        $scope.actionUrl = '/stats/global/export';
        return $scope.query = JSON.stringify({
          query: {
            bool: {
              must: [
                {
                  range: {
                    date: {
                      gte: moment($scope.dates.start).format(),
                      lte: moment($scope.dates.end).format()
                    }
                  }
                }
              ]
            }
          }
        });
      } else {
        $scope.actionUrl = `/stats/${index.key}/export`;
        $scope.query = JSON.stringify(query);
      }
    };

    /**
     * Callback to close the modal, telling the caller what is exported
     */
    $scope.exportData = function () {
      const statusQry = { category: 'statistics', type: $scope.export.type, query: $scope.query };
      if ($scope.export.type !== 'global') {
        statusQry.type = index.key;
        statusQry.key = type.key;
      }

      Export.status(statusQry).then(function (res) {
        if (!res.data.exists) {
          return growl.success(_t('app.admin.statistics.export_is_running_you_ll_be_notified_when_its_ready'));
        }
      });

      return $uibModalInstance.close(statusQry);
    };

    /**
     * Callback to cancel the export and close the modal
     */
    $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };
  }
]);
