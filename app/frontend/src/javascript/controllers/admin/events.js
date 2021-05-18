/* eslint-disable
    camelcase,
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

/* COMMON CODE */

/**
 * Provides a set of common properties and methods to the $scope parameter. They are used
 * in the various events' admin controllers.
 *
 * Provides :
 *  - $scope.datePicker = {}
 *  - $scope.event_themes = []
 *  - $scope.submited(content)
 *  - $scope.cancel()
 *  - $scope.addFile()
 *  - $scope.deleteFile(file)
 *  - $scope.fileinputClass(v)
 *  - $scope.toggleStartDatePicker($event)
 *  - $scope.toggleEndDatePicker($event)
 *  - $scope.toggleRecurrenceEnd(e)
 *  - $scope.addPrice()
 *  - $scope.removePrice(price, $event)
 *  - $scope.handleEventChange(?)
 *
 * Requires :
 *  - $scope.event.event_files_attributes = []
 *  - $scope.event.
 *  - $state (Ui-Router) [ 'app.public.events_list' ]
 */
class EventsController {
  constructor ($scope, $state) {
    // default parameters for AngularUI-Bootstrap datepicker
    $scope.datePicker = {
      format: Fablab.uibDateFormat,
      startOpened: false, // default: datePicker is not shown
      endOpened: false,
      recurrenceEndOpened: false,
      options: {
        startingDay: Fablab.weekStartingDay
      }
    };

    // themes of the current event
    $scope.event_themes = $scope.event.event_theme_ids;

    /**
     * For use with ngUpload (https://github.com/twilson63/ngUpload).
     * Intended to be the callback when an upload is done: any raised error will be stacked in the
     * $scope.alerts array. If everything goes fine, the user is redirected to the project page.
     * @param content {Object} JSON - The upload's result
     */
    $scope.submited = function (content) {
      $scope.onSubmited(content);
    };

    /**
     * Changes the user's view to the events list page
     */
    $scope.cancel = function () { $state.go('app.public.events_list'); };

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
     * This will create a single new empty entry into the event's attachements list.
     */
    $scope.addFile = function () { $scope.event.event_files_attributes.push({}); };

    /**
     * This will remove the given file from the event's attachements list. If the file was previously uploaded
     * to the server, it will be marked for deletion on the server. Otherwise, it will be simply truncated from
     * the attachements array.
     * @param file {Object} the file to delete
     */
    $scope.deleteFile = function (file) {
      const index = $scope.event.event_files_attributes.indexOf(file);
      if (file.id != null) {
        return file._destroy = true;
      } else {
        return $scope.event.event_files_attributes.splice(index, 1);
      }
    };

    /**
     * Show/Hide the "start" datepicker (open the drop down/close it)
     */
    $scope.toggleStartDatePicker = function ($event) {
      $event.preventDefault();
      $event.stopPropagation();
      return $scope.datePicker.startOpened = !$scope.datePicker.startOpened;
    };

    /**
     * Show/Hide the "end" datepicker (open the drop down/close it)
     */
    $scope.toggleEndDatePicker = function ($event) {
      $event.preventDefault();
      $event.stopPropagation();
      return $scope.datePicker.endOpened = !$scope.datePicker.endOpened;
    };

    /**
     * Masks/displays the recurrence pane allowing the admin to set the current event as recursive
     */
    $scope.toggleRecurrenceEnd = function (e) {
      e.preventDefault();
      e.stopPropagation();
      return $scope.datePicker.recurrenceEndOpened = !$scope.datePicker.recurrenceEndOpened;
    };

    /**
     * Initialize a new price item in the additional prices list
     */
    $scope.addPrice = function () {
      $scope.event.prices.push({
        category: null,
        amount: null
      });
    };

    /**
     * Remove the price or mark it as 'to delete'
     */
    $scope.removePrice = function (price, event) {
      event.preventDefault();
      event.stopPropagation();
      if (price.id) {
        price._destroy = true;
      } else {
        const index = $scope.event.prices.indexOf(price);
        $scope.event.prices.splice(index, 1);
      }
    };

    /**
     * When the theme selection has changes, extract the IDs to populate the form
     * @param themes {Array<EventTheme>}
     */
    $scope.handleEventChange = function (themes) {
      $scope.event_themes = themes.map(t => t.id);
    };
  }
}

/**
 * Controller used in the events listing page (admin view)
 */
Application.Controllers.controller('AdminEventsController', ['$scope', '$state', 'dialogs', '$uibModal', 'growl', 'AuthService', 'Event', 'Category', 'EventTheme', 'AgeRange', 'PriceCategory', 'eventsPromise', 'categoriesPromise', 'themesPromise', 'ageRangesPromise', 'priceCategoriesPromise', '_t', 'Member', 'uiTourService', 'settingsPromise',
  function ($scope, $state, dialogs, $uibModal, growl, AuthService, Event, Category, EventTheme, AgeRange, PriceCategory, eventsPromise, categoriesPromise, themesPromise, ageRangesPromise, priceCategoriesPromise, _t, Member, uiTourService, settingsPromise) {
  /* PUBLIC SCOPE */

    // By default, the pagination mode is activated to limit the page size
    $scope.paginateActive = true;

    // The events displayed on the page
    $scope.events = eventsPromise;

    // Current virtual page
    $scope.page = 1;

    // Temporary datastore for creating new elements
    $scope.inserted = {
      category: null,
      theme: null,
      age_range: null
    };

    // List of categories for the events
    $scope.categories = categoriesPromise;

    // List of events themes
    $scope.themes = themesPromise;

    // List of age ranges
    $scope.ageRanges = ageRangesPromise;

    // List of price categories for the events
    $scope.priceCategories = priceCategoriesPromise;

    // Default: we display all events (no restriction)
    $scope.eventsScope =
      { selected: '' };

    // default tab: events list
    $scope.tabs = { active: 0 };

    /**
     * Adds a bucket of events to the bottom of the page, grouped by month
     */
    $scope.loadMoreEvents = function () {
      $scope.page += 1;
      return Event.query({ page: $scope.page, scope: $scope.eventsScope.selected }, function (data) {
        $scope.events = $scope.events.concat(data);
        return paginationCheck(data, $scope.events);
      });
    };

    /**
     * Saves a new element / Update an existing one to the server (form validation callback)
     * @param model {string} model name
     * @param data {Object} element name
     * @param [id] {number} element id, in case of update
     */
    $scope.saveElement = function (model, data, id) {
      if (id != null) {
        return getModel(model)[0].update({ id }, data);
      } else {
        return getModel(model)[0].save(data, function (resp) { getModel(model)[1][getModel(model)[1].length - 1].id = resp.id; });
      }
    };

    /**
     * Deletes the element at the specified index
     * @param model {string} model name
     * @param index {number} element index in the $scope[model] array
     */
    $scope.removeElement = function (model, index) {
      if ((model === 'category') && (getModel(model)[1].length === 1)) {
        growl.error(_t('app.admin.events.at_least_one_category_is_required') + ' ' + _t('app.admin.events.unable_to_delete_the_last_one'));
        return false;
      }
      if (getModel(model)[1][index].related_to > 0) {
        growl.error(_t('app.admin.events.unable_to_delete_ELEMENT_already_in_use_NUMBER_times', { ELEMENT: model, NUMBER: getModel(model)[1][index].related_to }));
        return false;
      }
      return dialogs.confirm({
        resolve: {
          object () {
            return {
              title: _t('app.admin.events.confirmation_required'),
              msg: _t('app.admin.events.do_you_really_want_to_delete_this_ELEMENT', { ELEMENT: model })
            };
          }
        }
      }
      , function () { // delete confirmed
        getModel(model)[0].delete(getModel(model)[1][index], null, function () { getModel(model)[1].splice(index, 1); }
          , function () { growl.error(_t('app.admin.events.unable_to_delete_an_error_occured')); });
      });
    };

    /**
     * Creates a new empty entry in the $scope[model] array
     * @param model {string} model name
     */
    $scope.addElement = function (model) {
      $scope.inserted[model] = {
        name: '',
        related_to: 0
      };
      return getModel(model)[1].push($scope.inserted[model]);
    };

    /**
     * Removes the newly inserted but not saved element / Cancel the current element modification
     * @param model {string} model name
     * @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
     * @param index {number} element index in the $scope[model] array
     */
    $scope.cancelElement = function (model, rowform, index) {
      if (getModel(model)[1][index].id != null) {
        return rowform.$cancel();
      } else {
        return getModel(model)[1].splice(index, 1);
      }
    };

    /**
     * Open a modal dialog allowing the definition of a new price category.
     * Save it once filled and handle the result.
     */
    $scope.newPriceCategory = function () {
      $uibModal.open({
        templateUrl: '/admin/events/price_form.html',
        size: 'md',
        resolve: {
          category () { return {}; }
        },
        controller: 'PriceCategoryController'
      }).result.finally(null).then(function (p_cat) {
        // save the price category to the API
        PriceCategory.save(p_cat, function (cat) {
          $scope.priceCategories.push(cat);
          return growl.success(_t('app.admin.events.price_category_successfully_created'));
        }
        , function (err) {
          growl.error(_t('app.admin.events.unable_to_add_the_price_category_check_name_already_used'));
          return console.error(err);
        });
      });
    };
    /**
     * Update the given price category with the new properties
     * to specify in a modal dialog
     * @param index {number} index of the caterory in the $scope.priceCategories array
     * @param id {number} price category ID, must match the ID of the category at the index specified above
     */
    $scope.editPriceCategory = function (id, index) {
      if ($scope.priceCategories[index].id !== id) {
        return growl.error(_t('app.admin.events.unexpected_error_occurred_please_refresh'));
      } else {
        return $uibModal.open({
          templateUrl: '/admin/events/price_form.html',
          size: 'md',
          resolve: {
            category () { return $scope.priceCategories[index]; }
          },
          controller: 'PriceCategoryController'
        }).result.finally(null).then(function (p_cat) {
          // update the price category to the API
          PriceCategory.update({ id }, { price_category: p_cat }, function (cat) {
            $scope.priceCategories[index] = cat;
            return growl.success(_t('app.admin.events.price_category_successfully_updated'));
          }
          , function (err) {
            growl.error(_t('app.admin.events.unable_to_update_the_price_category'));
            return console.error(err);
          });
        });
      }
    };

    /**
     * Delete the given price category from the API
     * @param index {number} index of the caterory in the $scope.priceCategories array
     * @param id {number} price category ID, must match the ID of the category at the index specified above
     */
    $scope.removePriceCategory = function (id, index) {
      if ($scope.priceCategories[index].id !== id) {
        return growl.error(_t('app.admin.events.unexpected_error_occurred_please_refresh'));
      } else if ($scope.priceCategories[index].events > 0) {
        return growl.error(_t('app.admin.events.unable_to_delete_this_price_category_because_it_is_already_used'));
      } else {
        return dialogs.confirm(
          {
            resolve: {
              object () {
                return {
                  title: _t('app.admin.events.confirmation_required'),
                  msg: _t('app.admin.events.do_you_really_want_to_delete_this_price_category')
                };
              }
            }
          },
          function () { // delete confirmed
            PriceCategory.remove(
              { id },
              function () { // successfully deleted
                growl.success(_t('app.admin.events.price_category_successfully_deleted'));
                $scope.priceCategories.splice(index, 1);
              },
              function () { growl.error(_t('app.admin.events.price_category_deletion_failed')); }
            );
          }
        );
      }
    };

    /**
     * Triggered when the admin changes the events filter (all, passed, future).
     * We request the first page of corresponding events to the API
     */
    $scope.changeScope = function () {
      Event.query({ page: 1, scope: $scope.eventsScope.selected }, function (data) {
        $scope.events = data;
        return paginationCheck(data, $scope.events);
      });
      return $scope.page = 1;
    };

    /**
     * Setup the feature-tour for the admin/events page.
     * This is intended as a contextual help (when pressing F1)
     */
    $scope.setupEventsTour = function () {
      // get the tour defined by the ui-tour directive
      const uitour = uiTourService.getTourByName('events');
      uitour.createStep({
        selector: 'body',
        stepId: 'welcome',
        order: 0,
        title: _t('app.admin.tour.events.welcome.title'),
        content: _t('app.admin.tour.events.welcome.content'),
        placement: 'bottom',
        orphan: true
      });
      uitour.createStep({
        selector: '.events-management .events-list',
        stepId: 'list',
        order: 1,
        title: _t('app.admin.tour.events.list.title'),
        content: _t('app.admin.tour.events.list.content'),
        placement: 'top'
      });
      uitour.createStep({
        selector: '.events-management .events-list-filter',
        stepId: 'filter',
        order: 2,
        title: _t('app.admin.tour.events.filter.title'),
        content: _t('app.admin.tour.events.filter.content'),
        placement: 'bottom'
      });
      if (AuthService.isAuthorized('admin')) {
        uitour.createStep({
          selector: '.events-management .events-categories',
          stepId: 'categories',
          order: 3,
          title: _t('app.admin.tour.events.categories.title'),
          content: _t('app.admin.tour.events.categories.content'),
          placement: 'bottom'
        });
        uitour.createStep({
          selector: '.events-management .events-themes',
          stepId: 'themes',
          order: 4,
          title: _t('app.admin.tour.events.themes.title'),
          content: _t('app.admin.tour.events.themes.content'),
          placement: 'top'
        });
        uitour.createStep({
          selector: '.events-management .events-age-ranges',
          stepId: 'ages',
          order: 5,
          title: _t('app.admin.tour.events.ages.title'),
          content: _t('app.admin.tour.events.ages.content'),
          placement: 'top'
        });
        uitour.createStep({
          selector: '.events-management .prices-tab',
          stepId: 'prices',
          order: 6,
          title: _t('app.admin.tour.events.prices.title'),
          content: _t('app.admin.tour.events.prices.content'),
          placement: 'bottom'
        });
      }
      uitour.createStep({
        selector: 'body',
        stepId: 'conclusion',
        order: 7,
        title: _t('app.admin.tour.conclusion.title'),
        content: _t('app.admin.tour.conclusion.content'),
        placement: 'bottom',
        orphan: true
      });
      // on step change, change the active tab if needed
      uitour.on('stepChanged', function (nextStep) {
        if (nextStep.stepId === 'list' || nextStep.stepId === 'filter') { $scope.tabs.active = 0; }
        if (nextStep.stepId === 'categories' || nextStep.stepId === 'ages') { $scope.tabs.active = 1; }
        if (nextStep.stepId === 'prices') { $scope.tabs.active = 2; }
      });
      // on tour end, save the status in database
      uitour.on('ended', function () {
        if (uitour.getStatus() === uitour.Status.ON && $scope.currentUser.profile.tours.indexOf('events') < 0) {
          Member.completeTour({ id: $scope.currentUser.id }, { tour: 'events' }, function (res) {
            $scope.currentUser.profile.tours = res.tours;
          });
        }
      });
      // if the user has never seen the tour, show him now
      if (settingsPromise.feature_tour_display !== 'manual' && $scope.currentUser.profile.tours.indexOf('events') < 0) {
        uitour.start();
      }
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      paginationCheck(eventsPromise, $scope.events);
    };

    /**
     * Check if all events are already displayed OR if the button 'load more events'
     * is required
     * @param lastEvents {Array} last events loaded onto the diplay (ie. last "page")
     * @param events {Array} full list of events displayed on the page (not only the last retrieved)
     */
    const paginationCheck = function (lastEvents, events) {
      if (lastEvents.length > 0) {
        if (events.length >= lastEvents[0].nb_total_events) {
          return $scope.paginateActive = false;
        } else {
          return $scope.paginateActive = true;
        }
      } else {
        return $scope.paginateActive = false;
      }
    };

    /**
     * Return the model and the datastore matching the given name
     * @param name {string} 'category', 'theme' or 'age_range'
     * @return {[Object, Array]} model and datastore
     */
    const getModel = function (name) {
      switch (name) {
        case 'category': return [Category, $scope.categories];
        case 'theme': return [EventTheme, $scope.themes];
        case 'age_range': return [AgeRange, $scope.ageRanges];
        default: return [null, []];
      }
    };

    // init the controller (call at the end !)
    return initialize();
  }

]);

/**
 * Controller used in the reservations listing page for a specific event
 */
Application.Controllers.controller('ShowEventReservationsController', ['$scope', 'eventPromise', 'reservationsPromise', function ($scope, eventPromise, reservationsPromise) {
  // retrieve the event from the ID provided in the current URL
  $scope.event = eventPromise;

  // list of reservations for the current event
  $scope.reservations = reservationsPromise;

  /**
   * Test if the provided reservation has been cancelled
   * @param reservation {Reservation}
   * @returns {boolean}
   */
  $scope.isCancelled = function (reservation) {
    return !!(reservation.slots_attributes[0].canceled_at);
  };
}]);

/**
 * Controller used in the event creation page
 */
Application.Controllers.controller('NewEventController', ['$scope', '$state', 'CSRF', 'categoriesPromise', 'themesPromise', 'ageRangesPromise', 'priceCategoriesPromise', '_t',
  function ($scope, $state, CSRF, categoriesPromise, themesPromise, ageRangesPromise, priceCategoriesPromise, _t) {
    CSRF.setMetaTags();

    // API URL where the form will be posted
    $scope.actionUrl = '/api/events/';

    // Form action on the above URL
    $scope.method = 'post';

    // List of categories for the events
    $scope.categories = categoriesPromise;

    // List of events themes
    $scope.themes = themesPromise;

    // List of age ranges
    $scope.ageRanges = ageRangesPromise;

    // List of availables price's categories
    $scope.priceCategories = priceCategoriesPromise;

    // Default event parameters
    $scope.event = {
      event_files_attributes: [],
      start_date: new Date(),
      end_date: new Date(),
      start_time: new Date(),
      end_time: new Date(),
      all_day: 'false',
      recurrence: 'none',
      category_id: null,
      prices: []
    };

    // Possible types of recurrences for an event
    $scope.recurrenceTypes = [
      { label: _t('app.admin.events_new.none'), value: 'none' },
      { label: _t('app.admin.events_new.every_days'), value: 'day' },
      { label: _t('app.admin.events_new.every_week'), value: 'week' },
      { label: _t('app.admin.events_new.every_month'), value: 'month' },
      { label: _t('app.admin.events_new.every_year'), value: 'year' }
    ];

    // triggered when the new event form was submitted to the API and have received an answer
    $scope.onSubmited = function (content) {
      if ((content.id == null)) {
        $scope.alerts = [];
        angular.forEach(content, function (v, k) {
          angular.forEach(v, function (err) { $scope.alerts.push({ msg: k + ': ' + err, type: 'danger' }); });
        });
      } else {
        $state.go('app.public.events_list');
      }
    };

    // Using the EventsController
    return new EventsController($scope, $state);
  }
]);

/**
 * Controller used in the events edition page
 */
Application.Controllers.controller('EditEventController', ['$scope', '$state', '$stateParams', 'CSRF', 'eventPromise', 'categoriesPromise', 'themesPromise', 'ageRangesPromise', 'priceCategoriesPromise', '$uibModal', 'growl', '_t',
  function ($scope, $state, $stateParams, CSRF, eventPromise, categoriesPromise, themesPromise, ageRangesPromise, priceCategoriesPromise, $uibModal, growl, _t) {
    /* PUBLIC SCOPE */

    // API URL where the form will be posted
    $scope.actionUrl = `/api/events/${$stateParams.id}`;

    // Form action on the above URL
    $scope.method = 'put';

    // Retrieve the event details, in case of error the user is redirected to the events listing
    $scope.event = eventPromise;

    // We'll keep track of the initial dates here, for later comparison
    $scope.initialDates = {};

    // List of categories for the events
    $scope.categories = categoriesPromise;

    // List of available price's categories
    $scope.priceCategories = priceCategoriesPromise;

    // List of events themes
    $scope.themes = themesPromise;

    // List of age ranges
    $scope.ageRanges = ageRangesPromise;

    // Default edit-mode for periodic event
    $scope.editMode = 'single';

    // show edit-mode modal if event is recurrent
    $scope.isShowEditModeModal = $scope.event.recurrence_events.length > 0;

    $scope.editRecurrent = function (e) {
      if ($scope.isShowEditModeModal && $scope.event.recurrence_events.length > 0) {
        e.preventDefault();

        // open a choice edit-mode dialog
        const modalInstance = $uibModal.open({
          animation: true,
          templateUrl: '/events/editRecurrent.html',
          size: 'md',
          controller: 'EditRecurrentEventController',
          resolve: {
            editMode: function () { return $scope.editMode; },
            initialDates: function () { return $scope.initialDates; },
            currentEvent: function () { return $scope.event; }
          }
        });
        // submit form event by edit-mode
        modalInstance.result.then(function (res) {
          $scope.isShowEditModeModal = false;
          $scope.editMode = res.editMode;
          e.target.click();
        });
      }
    };

    // triggered when the edit event form was submitted to the API and have received an answer
    $scope.onSubmited = function (data) {
      if (data.total === data.updated) {
        if (data.updated > 1) {
          growl.success(_t(
            'app.admin.events_edit.events_updated',
            { COUNT: data.updated - 1 }
          ));
        } else {
          growl.success(_t(
            'app.admin.events_edit.event_successfully_updated'
          ));
        }
      } else {
        if (data.total > 1) {
          growl.warning(_t(
            'app.admin.events_edit.events_not_updated',
            { TOTAL: data.total, COUNT: data.total - data.updated }
          ));
          if (_.find(data.details, { error: 'EventPriceCategory' })) {
            growl.error(_t(
              'app.admin.events_edit.error_deleting_reserved_price'
            ));
          } else {
            growl.error(_t(
              'app.admin.events_edit.other_error'
            ));
          }
        } else {
          growl.error(_t(
            'app.admin.events_edit.unable_to_update_the_event'
          ));
          if (data.details[0].error === 'EventPriceCategory') {
            growl.error(_t(
              'app.admin.events_edit.error_deleting_reserved_price'
            ));
          } else {
            growl.error(_t(
              'app.admin.events_edit.other_error'
            ));
          }
        }
      }
      $state.go('app.public.events_list');
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      CSRF.setMetaTags();

      // init the dates to JS objects
      $scope.event.start_date = moment($scope.event.start_date).toDate();
      $scope.event.end_date = moment($scope.event.end_date).toDate();

      $scope.initialDates = {
        start: new Date($scope.event.start_date.valueOf()),
        end: new Date($scope.event.end_date.valueOf())
      };

      // Using the EventsController
      return new EventsController($scope, $state);
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

/**
 * Controller used in the event edit-mode modal window
 */
Application.Controllers.controller('EditRecurrentEventController', ['$scope', '$uibModalInstance', 'editMode', 'growl', 'initialDates', 'currentEvent', '_t',
  function ($scope, $uibModalInstance, editMode, growl, initialDates, currentEvent, _t) {
    // with recurrent slots: how many slots should we update?
    $scope.editMode = editMode;

    /**
     * Confirmation callback
     */
    $scope.ok = function () {
      $uibModalInstance.close({
        editMode: $scope.editMode
      });
    };

    /**
     * Test if any of the dates of the event has changed
     */
    $scope.hasDateChanged = function () {
      return (!moment(initialDates.start).isSame(currentEvent.start_date, 'day') || !moment(initialDates.end).isSame(currentEvent.end_date, 'day'));
    };

    /**
     * Cancellation callback
     */
    $scope.cancel = function () {
      $uibModalInstance.dismiss('cancel');
    };
  }
]);
