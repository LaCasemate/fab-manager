/* eslint-disable
    camelcase,
    handle-callback-err,
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

/**
 * Controller used in the calendar management page
 */

Application.Controllers.controller('AdminCalendarController', ['$scope', '$state', '$uibModal', 'moment', 'AuthService', 'Availability', 'Slot', 'Setting', 'Export', 'growl', 'dialogs', 'bookingWindowStart', 'bookingWindowEnd', 'machinesPromise', 'plansPromise', 'groupsPromise', 'settingsPromise', '_t', 'uiCalendarConfig', 'CalendarConfig', 'Member', 'uiTourService',
  function ($scope, $state, $uibModal, moment, AuthService, Availability, Slot, Setting, Export, growl, dialogs, bookingWindowStart, bookingWindowEnd, machinesPromise, plansPromise, groupsPromise, settingsPromise, _t, uiCalendarConfig, CalendarConfig, Member, uiTourService) {
    /* PRIVATE STATIC CONSTANTS */

    // The calendar is divided in slots of 30 minutes
    const BASE_SLOT = '00:30:00';

    // The bookings can be positioned every half hours
    const BOOKING_SNAP = '00:30:00';

    // We do not allow the creation of slots that are not a multiple of 60 minutes
    const SLOT_MULTIPLE = parseInt(settingsPromise.slot_duration, 10);

    /* PUBLIC SCOPE */

    // list of the FabLab machines
    $scope.machines = machinesPromise;

    // currently selected availability
    $scope.availability = null;

    // corresponding fullCalendar item in the DOM
    $scope.availabilityDom = null;

    // Should we show the scheduled events in the calendar?
    $scope.eventsInCalendar = (settingsPromise.events_in_calendar === 'true');

    // bind the availabilities slots with full-Calendar events
    $scope.eventSources = [{
      url: '/api/availabilities',
      textColor: 'black'
    }];

    // fullCalendar (v2) configuration
    $scope.calendarConfig = CalendarConfig({
      slotDuration: BASE_SLOT,
      snapDuration: BOOKING_SNAP,
      selectable: true,
      selectHelper: true,
      minTime: moment.duration(moment(bookingWindowStart.setting.value).format('HH:mm:ss')),
      maxTime: moment.duration(moment(bookingWindowEnd.setting.value).format('HH:mm:ss')),
      select (start, end, jsEvent, view) {
        return calendarSelectCb(start, end, jsEvent, view);
      },
      eventClick (event, jsEvent, view) {
        return calendarEventClickCb(event, jsEvent, view);
      },
      eventRender (event, element, view) {
        return eventRenderCb(event, element, view);
      },
      viewRender (view, element) {
        return viewRenderCb(view, element);
      },
      loading (isLoading, view) {
        return loadingCb(isLoading, view);
      }
    });

    /**
     * Open a confirmation modal to cancel the booking of a user for the currently selected event.
     * @param slot {Object} reservation slot of a user, inherited from $resource
     */
    $scope.cancelBooking = function (slot) {
    // open a confirmation dialog
      dialogs.confirm(
        {
          resolve: {
            object () {
              return {
                title: _t('app.admin.calendar.confirmation_required'),
                msg: _t('app.admin.calendar.do_you_really_want_to_cancel_the_USER_s_reservation_the_DATE_at_TIME_concerning_RESERVATION'
                  , { GENDER: getGender($scope.currentUser), USER: slot.user.name, DATE: moment(slot.start_at).format('L'), TIME: moment(slot.start_at).format('LT'), RESERVATION: slot.reservable.name })
              };
            }
          }
        },
        function () {
          // the admin has confirmed, cancel the subscription
          Slot.cancel(
            { id: slot.slot_id },
            function (data, status) { // success
              // update the canceled_at attribute
              for (const resa of Array.from($scope.reservations)) {
                if (resa.slot_id === data.id) {
                  resa.canceled_at = data.canceled_at;
                  break;
                }
              }
              // notify the admin
              return growl.success(_t('app.admin.calendar.reservation_was_successfully_cancelled'));
            },
            function (data, status) { // failed
              growl.error(_t('app.admin.calendar.reservation_cancellation_failed'));
            }
          );
        }
      );
    };

    /**
     * Open a confirmation modal to remove a machine for the currently selected availability,
     * except if it is the last machine of the reservation.
     * @param machine {Object} must contain the machine ID and name
     */
    $scope.removeMachine = function (machine) {
      if ($scope.availability.machine_ids.length === 1) {
        return growl.error(_t('app.admin.calendar.unable_to_remove_the_last_machine_of_the_slot_delete_the_slot_rather'));
      } else {
      // open a confirmation dialog
        return dialogs.confirm({
          resolve: {
            object () {
              return {
                title: _t('app.admin.calendar.confirmation_required'),
                msg: _t('app.admin.calendar.do_you_really_want_to_remove_MACHINE_from_this_slot', { GENDER: getGender($scope.currentUser), MACHINE: machine.name }) + ' ' +
               _t('app.admin.calendar.this_will_prevent_any_new_reservation_on_this_slot_but_wont_cancel_those_existing') + '<br><strong>' +
               _t('app.admin.calendar.beware_this_cannot_be_reverted') + '</strong>'
              };
            }
          }
        }
        , function () {
        // the admin has confirmed, remove the machine
          const machines = $scope.availability.machine_ids;
          for (let m_id = 0; m_id < machines.length; m_id++) {
            const key = machines[m_id];
            if (m_id === machine.id) {
              machines.splice(key, 1);
            }
          }

          return Availability.update({ id: $scope.availability.id }, { availability: { machines_attributes: [{ id: machine.id, _destroy: true }] } }
            , function (data, status) { // success
              // update the machine_ids attribute
              $scope.availability.machine_ids = data.machine_ids;
              $scope.availability.title = data.title;
              uiCalendarConfig.calendars.calendar.fullCalendar('rerenderEvents');
              // notify the admin
              return growl.success(_t('app.admin.calendar.the_machine_was_successfully_removed_from_the_slot'));
            }
            , function (data, status) { // failed
              growl.error(_t('app.admin.calendar.deletion_failed'));
            }
          );
        });
      }
    };

    /**
     * Open a confirmation modal to remove a plan for the currently selected availability,
     * @param plan {Object} must contain the machine ID and name
     */
    $scope.removePlan = function (plan) {
      // open a confirmation dialog
      return dialogs.confirm({
        resolve: {
          object () {
            return {
              title: _t('app.admin.calendar.confirmation_required'),
              msg: _t('app.admin.calendar.do_you_really_want_to_remove_PLAN_from_this_slot', { GENDER: getGender($scope.currentUser), PLAN: plan.name })
            };
          }
        }
      },
      function () {
        // the admin has confirmed, remove the plan
        _.drop($scope.availability.plan_ids, plan.id);

        Availability.update({ id: $scope.availability.id }, { availability: { plans_attributes: [{ id: plan.id, _destroy: true }] } }
          , function (data, status) { // success
            // update the plan_ids attribute
            $scope.availability.plan_ids = data.plan_ids;
            $scope.availability.plans = availabilityPlans();
            uiCalendarConfig.calendars.calendar.fullCalendar('rerenderEvents');
            // notify the admin
            return growl.success(_t('app.admin.calendar.the_plan_was_successfully_removed_from_the_slot'));
          }
          , function (data, status) { // failed
            growl.error(_t('app.admin.calendar.deletion_failed'));
          }
        );
      });
    };

    /**
     * Callback to alert the admin that the export request was acknowledged and is
     * processing right now.
     */
    $scope.alertExport = function (type) {
      Export.status({ category: 'availabilities', type }).then(function (res) {
        if (!res.data.exists) {
          return growl.success(_t('app.admin.calendar.export_is_running_you_ll_be_notified_when_its_ready'));
        }
      });
    };

    /**
     * Mark the selected slot as unavailable for new reservations or allow reservations again on it
     */
    $scope.toggleLockReservations = function () {
    // first, define a shortcut to the lock property
      const locked = $scope.availability.lock;
      // then check if we'll allow reservations locking
      let prevent = !locked; // if currently locked, allow unlock anyway
      if (!locked) {
        prevent = false;
        angular.forEach($scope.reservations, function (r) {
          if (r.canceled_at === null) {
            return prevent = true;
          }
        }); // if currently unlocked and has any non-cancelled reservation, disallow locking
      }
      if (!prevent) {
      // open a confirmation dialog
        dialogs.confirm(
          {
            resolve: {
              object () {
                return {
                  title: _t('app.admin.calendar.confirmation_required'),
                  msg: locked ? _t('app.admin.calendar.do_you_really_want_to_allow_reservations') : _t('app.admin.calendar.do_you_really_want_to_block_this_slot')
                };
              }
            }
          },
          function () {
            // the admin has confirmed, lock/unlock the slot
            Availability.lock(
              { id: $scope.availability.id },
              { lock: !locked },
              function (data) { // success
                $scope.availability = data;
                growl.success(locked ? _t('app.admin.calendar.unlocking_success') : _t('app.admin.calendar.locking_success'));
                uiCalendarConfig.calendars.calendar.fullCalendar('refetchEvents');
              },
              function (error) { // failed
                growl.error(locked ? _t('app.admin.calendar.unlocking_failed') : _t('app.admin.calendar.locking_failed'));
                console.error(error);
              }
            );
          }
        );
      } else {
        return growl.error(_t('app.admin.calendar.unlockable_because_reservations'));
      }
    };

    /**
     * Confirm and destroy the slot in $scope.availability
     */
    $scope.removeSlot = function () {
      // open a confirmation dialog
      const modalInstance = $uibModal.open({
        animation: true,
        templateUrl: '/admin/calendar/deleteRecurrent.html',
        size: 'md',
        controller: 'DeleteRecurrentAvailabilityController',
        resolve: {
          availabilityPromise: ['Availability', function (Availability) { return Availability.get({ id: $scope.availability.id }).$promise; }]
        }
      });
      // once the dialog was closed, do things depending on the result
      modalInstance.result.then(function (res) {
        if (res.status === 'success') {
          $scope.availability = null;
        }
        for (const availability of res.availabilities) {
          uiCalendarConfig.calendars.calendar.fullCalendar('removeEvents', availability);
        }
      });
    };

    /**
     * Setup the feature-tour for the admin/calendar page.
     * This is intended as a contextual help (when pressing F1)
     */
    $scope.setupCalendarTour = function () {
      // get the tour defined by the ui-tour directive
      const uitour = uiTourService.getTourByName('calendar');
      uitour.createStep({
        selector: 'body',
        stepId: 'welcome',
        order: 0,
        title: _t('app.admin.tour.calendar.welcome.title'),
        content: _t('app.admin.tour.calendar.welcome.content'),
        placement: 'bottom',
        orphan: true
      });
      uitour.createStep({
        selector: '.admin-calendar .fc-view-container',
        stepId: 'agenda',
        order: 1,
        title: _t('app.admin.tour.calendar.agenda.title'),
        content: _t('app.admin.tour.calendar.agenda.content'),
        placement: 'right',
        popupClass: 'width-350'
      });
      if (AuthService.isAuthorized('admin')) {
        uitour.createStep({
          selector: '.admin-calendar .export-xls-button',
          stepId: 'export',
          order: 2,
          title: _t('app.admin.tour.calendar.export.title'),
          content: _t('app.admin.tour.calendar.export.content'),
          placement: 'left'
        });
      }
      uitour.createStep({
        selector: '.heading .import-ics-button',
        stepId: 'import',
        order: 3,
        title: _t('app.admin.tour.calendar.import.title'),
        content: _t('app.admin.tour.calendar.import.content'),
        placement: 'left'
      });
      uitour.createStep({
        selector: 'body',
        stepId: 'conclusion',
        order: 4,
        title: _t('app.admin.tour.conclusion.title'),
        content: _t('app.admin.tour.conclusion.content'),
        placement: 'bottom',
        orphan: true
      });
      // on tour end, save the status in database
      uitour.on('ended', function () {
        if (uitour.getStatus() === uitour.Status.ON && $scope.currentUser.profile.tours.indexOf('calendar') < 0) {
          Member.completeTour({ id: $scope.currentUser.id }, { tour: 'calendar' }, function (res) {
            $scope.currentUser.profile.tours = res.tours;
          });
        }
      });
      // if the user has never seen the tour, show him now
      if (settingsPromise.feature_tour_display !== 'manual' && $scope.currentUser.profile.tours.indexOf('calendar') < 0) {
        uitour.start();
      }
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {};

    /**
     * Return an enumerable meaninful string for the gender of the provider user
     * @param user {Object} Database user record
     * @return {string} 'male' or 'female'
     */
    const getGender = function (user) {
      if (user.statistic_profile) {
        if (user.statistic_profile.gender === 'true') { return 'male'; } else { return 'female'; }
      } else { return 'other'; }
    };

    /**
     * Return a list of plans classified by group
     *
     * @returns {array}
     */
    const availabilityPlans = function () {
      const plansClassifiedByGroup = [];
      const _plans = _.filter(plansPromise, function (p) { return _.includes($scope.availability.plan_ids, p.id); });
      for (const group of Array.from(groupsPromise)) {
        const groupObj = { id: group.id, name: group.name, plans: [] };
        for (const plan of Array.from(_plans)) {
          if (plan.group_id === group.id) { groupObj.plans.push(plan); }
        }
        if (groupObj.plans.length > 0) {
          plansClassifiedByGroup.push(groupObj);
        }
      }
      return plansClassifiedByGroup;
    };

    // Triggered when the admin drag on the agenda to create a new reservable slot.
    // @see http://fullcalendar.io/docs/selection/select_callback/
    //
    const calendarSelectCb = function (start, end, jsEvent, view) {
      start = moment.tz(start.toISOString(), Fablab.timezone);
      end = moment.tz(end.toISOString(), Fablab.timezone);
      if (view.name === 'month') {
        end = end.subtract(1, 'day').startOf('day');
      }

      // check if slot is not in the past
      const today = new Date();
      if (Math.trunc((start.valueOf() - today) / (60 * 1000)) < 0) {
        growl.warning(_t('app.admin.calendar.event_in_the_past'));
        return uiCalendarConfig.calendars.calendar.fullCalendar('unselect');
      }

      // check that the selected slot is an multiple of SLOT_MULTIPLE (ie. not decimal)
      const slots = Math.trunc((end.valueOf() - start.valueOf()) / (60 * 1000)) / SLOT_MULTIPLE;
      if (!Number.isInteger(slots)) {
        // otherwise, round it to upper decimal
        const upper = (Math.ceil(slots) || 1) * SLOT_MULTIPLE;
        end = moment(start).add(upper, 'minutes');
      }

      // then we open a modal window to let the admin specify the slot type
      const modalInstance = $uibModal.open({
        templateUrl: '/admin/calendar/eventModal.html',
        controller: 'CreateEventModalController',
        backdrop: 'static',
        keyboard: false,
        resolve: {
          start () { return start; },
          end () { return end; },
          slots () { return Math.ceil(slots); },
          machinesPromise: ['Machine', function (Machine) { return Machine.query().$promise; }],
          trainingsPromise: ['Training', function (Training) { return Training.query().$promise; }],
          spacesPromise: ['Space', function (Space) { return Space.query().$promise; }],
          tagsPromise: ['Tag', function (Tag) { return Tag.query().$promise; }],
          plansPromise: ['Plan', function (Plan) { return Plan.query().$promise; }],
          groupsPromise: ['Group', function (Group) { return Group.query().$promise; }],
          slotDurationPromise: ['Setting', function (Setting) { return Setting.get({ name: 'slot_duration' }).$promise; }]
        }
      });
      // when the modal is closed, we send the slot to the server for saving
      modalInstance.result.then(
        function (availability) {
          uiCalendarConfig.calendars.calendar.fullCalendar(
            'renderEvent',
            {
              id: availability.id,
              title: availability.title,
              start: availability.start_at,
              end: availability.end_at,
              textColor: 'black',
              backgroundColor: availability.backgroundColor,
              borderColor: availability.borderColor,
              tag_ids: availability.tag_ids,
              tags: availability.tags,
              machine_ids: availability.machine_ids,
              plan_ids: availability.plan_ids,
              slot_duration: availability.slot_duration
            },
            true
          );
        },
        function () { uiCalendarConfig.calendars.calendar.fullCalendar('unselect'); }
      );

      return uiCalendarConfig.calendars.calendar.fullCalendar('unselect');
    };

    /**
     * Triggered when the admin clicks on a availability slot in the agenda.
     * @see http://fullcalendar.io/docs/mouse/eventClick/
     */
    const calendarEventClickCb = function (event, jsEvent, view) {
      $scope.availability = event;
      $scope.availability.plans = availabilityPlans();

      if ($scope.availabilityDom) {
        $scope.availabilityDom.classList.remove('fc-selected');
      }
      $scope.availabilityDom = jsEvent.target.closest('.fc-event');
      $scope.availabilityDom.classList.add('fc-selected');

      // if the user has clicked on the delete event button, delete the event
      if ($(jsEvent.target).hasClass('remove-event')) {
        return $scope.removeSlot();
        // if the user has only clicked on the event, display its reservations
      } else {
        return Availability.reservations({ id: event.id }, function (reservations) { $scope.reservations = reservations; });
      }
    };

    /**
     * Triggered when fullCalendar tries to graphicaly render an event block.
     * Append the event tag into the block, just after the event title.
     * @see http://fullcalendar.io/docs/event_rendering/eventRender/
     */
    const eventRenderCb = function (event, element) {
      if (event.available_type !== 'event') {
        element.find('.fc-content').prepend('<span class="remove-event">x&nbsp;</span>');
      }
      if (event.tags && event.tags.length > 0) {
        let html = '';
        for (const tag of Array.from(event.tags)) {
          html += `<span class='label label-success text-white'>${tag.name}</span> `;
        }
        element.find('.fc-title').append(`<br/>${html}`);
      }
    };

    /**
     * Triggered when resource fetching starts/stops.
     * @see https://fullcalendar.io/docs/resource_data/loading/
     */
    const loadingCb = function (isLoading, view) {
      if (isLoading && uiCalendarConfig.calendars.calendar) {
        // we remove existing events when fetching starts to prevent duplicates
        uiCalendarConfig.calendars.calendar.fullCalendar('removeEvents');
      }
    };

    /**
     * Triggered when the view is changed
     * @see https://fullcalendar.io/docs/v3/viewRender#v2
     */
    const viewRenderCb = function (view, element) {
      // we unselect the current event to keep consistency
      $scope.availability = null;
      $scope.availabilityDom = null;
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }

]);

/**
 * Controller used in the slot creation modal window
 */
Application.Controllers.controller('CreateEventModalController', ['$scope', '$uibModalInstance', '$sce', 'moment', 'start', 'end', 'slots', 'machinesPromise', 'Availability', 'trainingsPromise', 'spacesPromise', 'tagsPromise', 'plansPromise', 'groupsPromise', 'slotDurationPromise', 'growl', '_t',
  function ($scope, $uibModalInstance, $sce, moment, start, end, slots, machinesPromise, Availability, trainingsPromise, spacesPromise, tagsPromise, plansPromise, groupsPromise, slotDurationPromise, growl, _t) {
    // $uibModal parameter
    $scope.start = start;

    // $uibModal parameter
    $scope.end = end;

    // machines list
    $scope.machines = machinesPromise.filter(function (m) { return !m.disabled; });

    // trainings list
    $scope.trainings = trainingsPromise.filter(function (t) { return !t.disabled; });

    // spaces list
    $scope.spaces = spacesPromise.filter(function (s) { return !s.disabled; });

    // all tags list
    $scope.tags = tagsPromise;

    $scope.isOnlySubscriptions = false;
    $scope.selectedPlans = [];
    $scope.selectedPlansBinding = {};
    // list of plans, classified by group
    $scope.plansClassifiedByGroup = [];

    // machines associated with the created slot
    $scope.selectedMachines = [];
    $scope.selectedMachinesBinding = {};

    // training associated with the created slot
    $scope.selectedTraining = null;

    // space associated with the created slot
    $scope.selectedSpace = null;

    // UI step
    $scope.step = 1;

    // the user is not able to edit the ending time of the availability, unless he set the type to 'training'
    $scope.endDateReadOnly = true;

    // timepickers configuration
    $scope.timepickers = {
      start: {
        hstep: 1,
        mstep: 5
      },
      end: {
        hstep: 1,
        mstep: 5
      }
    };

    // slot details
    $scope.availability = {
      start_at: start,
      end_at: end,
      available_type: 'machines', // default
      tag_ids: [],
      is_recurrent: false,
      period: 'week',
      nb_periods: 1,
      end_date: undefined, // recurrence end
      slot_duration: parseInt(slotDurationPromise.setting.value, 10)
    };

    // recurrent slots
    $scope.occurrences = [];

    // localized name(s) of the reservable item(s)
    $scope.reservableName = '';

    // localized name(s) of the selected tag(s)
    $scope.tagsName = '';

    // localized name(s) of the selected plan(s)
    $scope.plansName = '';

    // number of slots for this availability
    $scope.slots_nb = slots;

    /**
     * Adds or removes the provided machine from the current slot
     * @param machine {Object}
     */
    $scope.toggleSelection = function (machine) {
      const index = $scope.selectedMachines.indexOf(machine);
      if (index > -1) {
        return $scope.selectedMachines.splice(index, 1);
      } else {
        return $scope.selectedMachines.push(machine);
      }
    };

    /**
     * Select/unselect all the machines
     */
    $scope.toggleAll = function () {
      const count = $scope.selectedMachines.length;
      $scope.selectedMachines = [];
      $scope.selectedMachinesBinding = {};
      if (count === 0) {
        $scope.machines.forEach(function (machine) {
          $scope.selectedMachines.push(machine);
          $scope.selectedMachinesBinding[machine.id] = true;
        });
      }
    };

    /**
     * Adds or removes the provided plan from the current slot
     * @param plan {Object}
     */
    $scope.toggleSelectPlan = function (plan) {
      const index = $scope.selectedPlans.indexOf(plan);
      if (index > -1) {
        return $scope.selectedPlans.splice(index, 1);
      } else {
        return $scope.selectedPlans.push(plan);
      }
    };

    /**
     * Select/unselect all the plans
     */
    $scope.toggleAllPlans = function () {
      const count = $scope.selectedPlans.length;
      $scope.selectedPlans = [];
      $scope.selectedPlansBinding = {};
      if (count === 0) {
        plansPromise.filter(p => !p.disabled).forEach(function (plan) {
          $scope.selectedPlans.push(plan);
          $scope.selectedPlansBinding[plan.id] = true;
        });
      }
    };

    /**
     * Callback for the modal window validation: save the slot and closes the modal
     */
    $scope.ok = function () {
      if ($scope.availability.available_type === 'machines') {
        if ($scope.selectedMachines.length > 0) {
          $scope.availability.machine_ids = $scope.selectedMachines.map(function (m) { return m.id; });
        } else {
          growl.error(_t('app.admin.calendar.you_should_select_at_least_a_machine'));
          return;
        }
      } else if ($scope.availability.available_type === 'training') {
        $scope.availability.training_ids = [$scope.selectedTraining.id];
      } else if ($scope.availability.available_type === 'space') {
        $scope.availability.space_ids = [$scope.selectedSpace.id];
      }
      if ($scope.availability.is_recurrent) {
        $scope.availability.occurrences = $scope.occurrences;
      }
      if ($scope.isOnlySubscriptions && $scope.selectedPlans.length > 0) {
        $scope.availability.plan_ids = $scope.selectedPlans.map(function (p) { return p.id; });
      }
      return Availability.save(
        { availability: $scope.availability },
        function (availability) { $uibModalInstance.close(availability); }
      );
    };

    /**
     * Move the modal UI to the next step
     */
    $scope.next = function () {
      if ($scope.step === 1) { return validateType(); }
      if ($scope.step === 2) { return validateSelection(); }
      if ($scope.step === 3) { return validateTimes(); }
      if ($scope.step === 5) { return validateRecurrence(); }
      return $scope.step++;
    };

    /**
     * Move the modal UI to the next step
     */
    $scope.previous = function () { return $scope.step--; };

    /**
     * Callback to cancel the slot creation
     */
    $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };

    /**
     * For training/space availabilities, set the maximum number of people allowed registering on this slot.
     * Also, set the default slot duration
     */
    $scope.setNbTotalPlaces = function () {
      if ($scope.availability.available_type === 'training') {
        $scope.availability.nb_total_places = $scope.selectedTraining.nb_total_places;
      } else if ($scope.availability.available_type === 'space') {
        $scope.availability.nb_total_places = $scope.selectedSpace.default_places;
      }
    };

    /*
     * Test if the current availability type is divided in slots
     */
    $scope.isTypeDivided = function () {
      return isTypeDivided($scope.availability.available_type);
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      if ($scope.trainings.length > 0) {
        $scope.selectedTraining = $scope.trainings[0];
      }
      if ($scope.spaces.length > 0) {
        $scope.selectedSpace = $scope.spaces[0];
      }

      // when disable is only subscriptions option, reset all selected plans
      $scope.$watch('isOnlySubscriptions', function (value) {
        if (!value) {
          $scope.selectedPlans = [];
          $scope.selectedPlansBinding = {};
        }
      });

      // group plans by Group
      for (const group of groupsPromise.filter(g => !g.disabled)) {
        const groupObj = { id: group.id, name: group.name, plans: [] };
        for (const plan of plansPromise.filter(g => !g.disabled)) {
          if (plan.group_id === group.id) { groupObj.plans.push(plan); }
        }
        if (groupObj.plans.length > 0) {
          $scope.plansClassifiedByGroup.push(groupObj);
        }
      }

      // When the slot duration changes, we increment the availability to match the value
      $scope.$watch('availability.slot_duration', function (newValue, oldValue, scope) {
        if (newValue === undefined) return;

        const startSlot = moment($scope.start);
        startSlot.add(newValue * $scope.slots_nb, 'minutes');
        $scope.end = startSlot.toDate();
      });

      // When the number of slot changes, we increment the availability to match the value
      $scope.$watch('slots_nb', function (newValue, oldValue, scope) {
        const startSlot = moment($scope.start);
        startSlot.add($scope.availability.slot_duration * newValue, 'minutes');
        $scope.end = startSlot.toDate();
      });

      // When we configure a machine/space availability, do not let the user change the end time, as the total
      // time must be dividable by $scope.availability.slot_duration minutes (base slot duration). For training availabilities, the user
      // can configure any duration as it does not matters.
      $scope.$watch('availability.available_type', function (newValue, oldValue, scope) {
        if (isTypeDivided(newValue)) {
          $scope.endDateReadOnly = true;
          const slotDuration = $scope.availability.slot_duration || parseInt(slotDurationPromise.setting.value, 10);
          const slotsCurrentRange = Math.trunc(($scope.end.valueOf() - $scope.start.valueOf()) / (60 * 1000)) / slotDuration;
          if (!Number.isInteger(slotsCurrentRange)) {
            // otherwise, round it to upper decimal
            const upperSlots = Math.ceil(slotsCurrentRange);
            const upper = upperSlots * $scope.availability.slot_duration;
            $scope.end = moment($scope.start).add(upper, 'minutes').toDate();
            $scope.slots_nb = upperSlots;
          } else {
            $scope.slots_nb = slotsCurrentRange;
          }
          $scope.availability.end_at = $scope.end;
        } else {
          $scope.endDateReadOnly = false;
        }
      });

      // When the start date is changed, if we are configuring a machine/space availability,
      // maintain the relative length of the slot (ie. change the end time accordingly)
      $scope.$watch('start', function (newValue, oldValue, scope) {
        // adjust the end time
        const endSlot = moment($scope.end);
        endSlot.add(moment(newValue).diff(oldValue), 'milliseconds');
        $scope.end = endSlot.toDate();

        // update availability object
        $scope.availability.start_at = $scope.start;
      });

      // Maintain consistency between the end time and the date object in the availability object
      $scope.$watch('end', function (newValue, oldValue, scope) {
        if (newValue.valueOf() !== oldValue.valueOf()) {
          // we prevent the admin from setting the end of the availability before its beginning
          if (moment($scope.start).add($scope.availability.slot_duration, 'minutes').isAfter(newValue)) {
            $scope.end = oldValue;
          }
          // update availability object
          $scope.availability.end_at = $scope.end;
        }
      });
    };

    /*
     * Test if the provided availability type is divided in slots
     */
    const isTypeDivided = function (type) {
      return ((type === 'machines') || (type === 'space'));
    };

    /**
     * Validates that a machine or more was/were selected before continuing to step 3 (adjust time + tags)
     */
    const validateSelection = function () {
      if ($scope.availability.available_type === 'machines') {
        if ($scope.selectedMachines.length === 0) {
          return growl.error(_t('app.admin.calendar.you_should_select_at_least_a_machine'));
        }
      }
      $scope.step++;
    };

    /**
     * Validates that the slots/availability date and times are correct
     */
    const validateTimes = function () {
      if (moment($scope.end).isSameOrBefore($scope.start)) {
        return growl.error(_t('app.admin.calendar.inconsistent_times'));
      }
      if ($scope.isTypeDivided()) {
        if (!$scope.slots_nb) {
          return growl.error(_t('app.admin.calendar.min_one_slot'));
        }
        if (!$scope.availability.slot_duration) {
          return growl.error(_t('app.admin.calendar.min_slot_duration'));
        }
      }
      $scope.step++;
    };

    /**
     * Validates that the recurrence parameters were correctly set before continuing to step 5 (summary)
     */
    const validateRecurrence = function () {
      if ($scope.availability.is_recurrent) {
        if (!$scope.availability.period) {
          return growl.error(_t('app.admin.calendar.select_period'));
        }
        if (!$scope.availability.nb_periods || $scope.availability.nb_periods < 1) {
          return growl.error(_t('app.admin.calendar.select_nb_period'));
        }
        if (!$scope.availability.end_date) {
          return growl.error(_t('app.admin.calendar.select_end_date'));
        }
      }
      // settings are ok
      computeOccurrences();
      computeNames();
      $scope.step++;
    };

    /**
     * Initialize some settings, depending on the availability type, before continuing to step 2 (select a machine/training/space)
     */
    const validateType = function () {
      $scope.setNbTotalPlaces();
      if ($scope.availability.available_type === 'training') {
        $scope.availability.slot_duration = undefined;
      } else {
        $scope.availability.slot_duration = parseInt(slotDurationPromise.setting.value, 10);
      }
      $scope.step++;
    };

    /**
     * Compute the various occurrences of the availability, according to the recurrence settings
     */
    const computeOccurrences = function () {
      $scope.occurrences = [];

      if ($scope.availability.is_recurrent) {
        const date = moment($scope.availability.start_at);
        const diff = moment($scope.availability.end_at).diff($scope.availability.start_at);
        const end = moment($scope.availability.end_date).endOf('day');
        while (date.isBefore(end)) {
          const occur_end = moment(date).add(diff, 'ms');
          $scope.occurrences.push({
            start_at: date.toDate(),
            end_at: occur_end.toDate()
          });
          date.add($scope.availability.nb_periods, $scope.availability.period);
        }
      } else {
        $scope.occurrences.push({
          start_at: $scope.availability.start_at,
          end_at: $scope.availability.end_at
        });
      }
    };

    const computeNames = function () {
      $scope.reservableName = '';
      switch ($scope.availability.available_type) {
        case 'machines':
          $scope.reservableName = localizedList($scope.selectedMachines);
          break;
        case 'training':
          $scope.reservableName = `<strong>${$scope.selectedTraining.name}</strong>`;
          break;
        case 'space':
          $scope.reservableName = `<strong>${$scope.selectedSpace.name}</strong>`;
          break;
        default:
          $scope.reservableName = `<span class="warning">${_t('app.admin.calendar.none')}</span>`;
      }
      const tags = $scope.tags.filter(function (t) {
        return $scope.availability.tag_ids.indexOf(t.id) > -1;
      });
      $scope.tagsName = localizedList(tags);
      if ($scope.isOnlySubscriptions && $scope.selectedPlans.length > 0) {
        $scope.plansName = localizedList($scope.selectedPlans);
      }
    };

    const localizedList = function (items) {
      if (items.length === 0) return `<span class="text-gray text-italic">${_t('app.admin.calendar.none')}</span>`;

      const names = items.map(function (i) { return $sce.trustAsHtml(`<strong>${i.name}</strong>`); });
      if (items.length > 1) return names.slice(0, -1).join(', ') + ` ${_t('app.admin.calendar.and')} ` + names[names.length - 1];

      return names[0];
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

/**
 * Controller used in the slot deletion modal window
 */
Application.Controllers.controller('DeleteRecurrentAvailabilityController', ['$scope', '$uibModalInstance', 'Availability', 'availabilityPromise', 'growl', '_t',
  function ($scope, $uibModalInstance, Availability, availabilityPromise, growl, _t) {
    // is the current slot (to be deleted) recurrent?
    $scope.isRecurrent = availabilityPromise.is_recurrent;

    // with recurrent slots: how many slots should we delete?
    $scope.deleteMode = 'single';

    /**
     * Confirmation callback
     */
    $scope.ok = function () {
      const { id, start_at, end_at } = availabilityPromise;
      // the admin has confirmed, delete the slot
      Availability.delete(
        { id, mode: $scope.deleteMode },
        function (res) {
          // delete success
          if (res.deleted > 1) {
            growl.success(_t(
              'app.admin.calendar.slots_deleted',
              { START: moment(start_at).format('LL LT'), COUNT: res.deleted - 1 }
            ));
          } else {
            growl.success(_t(
              'app.admin.calendar.slot_successfully_deleted',
              { START: moment(start_at).format('LL LT'), END: moment(end_at).format('LT') }
            ));
          }
          $uibModalInstance.close({
            status: 'success',
            availabilities: res.details.map(function (d) { return d.availability.id; })
          });
        },
        function (res) {
          // not everything was deleted
          const { data } = res;
          if (data.total > 1) {
            growl.warning(_t(
              'app.admin.calendar.slots_not_deleted',
              { TOTAL: data.total, COUNT: data.total - data.deleted }
            ));
          } else {
            growl.error(_t(
              'app.admin.calendar.unable_to_delete_the_slot',
              { START: moment(start_at).format('LL LT'), END: moment(end_at).format('LT') }
            ));
          }
          $uibModalInstance.close({
            status: 'failed',
            availabilities: data.details.filter(function (d) { return d.status; }).map(function (d) { return d.availability.id; })
          });
        });
    };

    /**
     * Cancellation callback
     */
    $scope.cancel = function () {
      $uibModalInstance.dismiss('cancel');
    };
  }
]);

/**
 * Controller used in the iCalendar (ICS) imports management page
 */

Application.Controllers.controller('AdminICalendarController', ['$scope', 'iCalendars', 'ICalendar', 'dialogs', 'growl', '_t',
  function ($scope, iCalendars, ICalendar, dialogs, growl, _t) {
    // list of ICS sources
    $scope.calendars = iCalendars;

    // configuration of a new ICS source
    $scope.newCalendar = {
      color: undefined,
      text_color: undefined,
      url: undefined,
      name: undefined,
      text_hidden: false
    };

    /**
     * Save the new iCalendar in database
     */
    $scope.save = function () {
      ICalendar.save({}, { i_calendar: $scope.newCalendar }, function (data) {
        // success
        $scope.calendars.push(data);
        $scope.newCalendar.url = undefined;
        $scope.newCalendar.name = undefined;
        $scope.newCalendar.color = null;
        $scope.newCalendar.text_color = null;
        $scope.newCalendar.text_hidden = false;
      }, function (error) {
        // failed
        growl.error(_t('app.admin.icalendar.create_error'));
        console.error(error);
      });
    };

    /**
     * Return a CSS-like style of the given calendar configuration
     * @param calendar
     */
    $scope.calendarStyle = function (calendar) {
      return {
        'border-color': calendar.color,
        color: calendar.text_color,
        width: calendar.text_hidden ? '50px' : 'auto',
        height: calendar.text_hidden ? '21px' : 'auto'
      };
    };

    /**
     * Delete the given calendar from the database
     * @param calendar
     */
    $scope.delete = function (calendar) {
      dialogs.confirm(
        {
          resolve: {
            object () {
              return {
                title: _t('app.admin.icalendar.confirmation_required'),
                msg: _t('app.admin.icalendar.confirm_delete_import')
              };
            }
          }
        },
        function () {
          ICalendar.delete(
            { id: calendar.id },
            function () {
              // success
              const idx = $scope.calendars.indexOf(calendar);
              $scope.calendars.splice(idx, 1);
              growl.info(_t('app.admin.icalendar.delete_success'));
            }, function (error) {
              // failed
              growl.error(_t('app.admin.icalendar.delete_failed'));
              console.error(error);
            }
          );
        }
      );
    };

    /**
     * Asynchronously re-fetches the events from the given calendar
     * @param calendar
     */
    $scope.sync = function (calendar) {
      ICalendar.sync(
        { id: calendar.id },
        function () {
          // success
          growl.info(_t('app.admin.icalendar.refresh'));
        }, function (error) {
          // failed
          growl.error(_t('app.admin.icalendar.sync_failed'));
          console.error(error);
        }
      );
    };
  }
]);
