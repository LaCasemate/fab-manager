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
Application.Directives.directive('cart', ['$rootScope', '$uibModal', 'dialogs', 'growl', 'Auth', 'Price', 'Wallet', 'CustomAsset', 'Slot', 'AuthService', 'Payment', 'helpers', '_t',
  function ($rootScope, $uibModal, dialogs, growl, Auth, Price, Wallet, CustomAsset, Slot, AuthService, Payment, helpers, _t) {
    return ({
      restrict: 'E',
      scope: {
        slot: '=',
        slotSelectionTime: '=',
        events: '=',
        user: '=',
        modePlans: '=',
        plan: '=',
        planSelectionTime: '=',
        settings: '=',
        plans: '=',
        groups: '=',
        onSlotAddedToCart: '=',
        onSlotRemovedFromCart: '=',
        onSlotStartToModify: '=',
        onSlotModifySuccess: '=',
        onSlotModifyCancel: '=',
        onSlotModifyUnselect: '=',
        onSlotCancelSuccess: '=',
        afterPayment: '=',
        reservableId: '@',
        reservableType: '@',
        reservableName: '@',
        limitToOneSlot: '@'
      },
      templateUrl: '/shared/_cart.html',
      link ($scope, element, attributes) {
      // will store the user's plan if he chose to buy one
        $scope.selectedPlan = null;

        // total amount of the bill to pay
        $scope.amountTotal = 0;

        // total amount of the elements in the cart, without considering any coupon
        $scope.totalNoCoupon = 0;

        // once the cart was paid, retain the total amount paid by the customer
        $scope.amountPaid = 0;

        // Discount coupon to apply to the basket, if any
        $scope.coupon = { applied: null };

        // Global config: is the user authorized to change his bookings slots?
        $scope.enableBookingMove = ($scope.settings.booking_move_enable === 'true');

        // Global config: delay in hours before a booking while changing the booking slot is forbidden
        $scope.moveBookingDelay = parseInt($scope.settings.booking_move_delay);

        // Global config: is the user authorized to cancel his bookings?
        $scope.enableBookingCancel = ($scope.settings.booking_cancel_enable === 'true');

        // Global config: delay in hours before a booking while the cancellation is forbidden
        $scope.cancelBookingDelay = parseInt($scope.settings.booking_cancel_delay);

        // Payment schedule
        $scope.schedule = {
          requested_schedule: false, // does the user requests a payment schedule for his subscription
          payment_schedule: undefined // the effective computed payment schedule
        };

        // online payments (by card)
        $scope.onlinePayment = {
          showModal: false,
          cartItems: undefined
        };

        // currently logged-in user
        $scope.currentUser = $rootScope.currentUser;

        /**
         * Add the provided slot to the shopping cart (state transition from free to 'about to be reserved')
         * and increment the total amount of the cart if needed.
         * @param slot {Object} fullCalendar event object
         */
        $scope.validateSlot = function (slot) {
          validateTags(slot, function () {
            validateSameTimeReservations(slot, function () {
              slot.isValid = true;
              updateCartPrice();
            });
          });
        };

        /**
         * Remove the provided slot from the shopping cart (state transition from 'about to be reserved' to free)
         * and decrement the total amount of the cart if needed.
         * @param slot {Object} fullCalendar event object
         * @param index {number} index of the slot in the reservation array
         * @param [event] {Object} see https://docs.angularjs.org/guide/expression#-event-
         */
        $scope.removeSlot = function (slot, index, event) {
          if (event) { event.preventDefault(); }
          $scope.events.reserved.splice(index, 1);
          // if is was the last slot, we remove any plan from the cart
          if ($scope.events.reserved.length === 0) {
            $scope.selectedPlan = null;
            $scope.plan = null;
            $scope.modePlans = false;
          }
          if (typeof $scope.onSlotRemovedFromCart === 'function') { $scope.onSlotRemovedFromCart(slot); }
          return updateCartPrice();
        };

        /**
         * Checks that every selected slots were added to the shopping cart. Ie. will return false if
         * any checked slot was not validated by the user.
         */
        $scope.isSlotsValid = function () {
          let isValid = true;
          if ($scope.events) {
            angular.forEach($scope.events.reserved, function (m) {
              if (!m.isValid) {
                return isValid = false;
              }
            });
          }
          return isValid;
        };

        /**
         * Switch the user's view from the reservation agenda to the plan subscription
         */
        $scope.showPlans = function () {
          // first, we ensure that a user was selected (admin/manager) or logged (member)
          const isSelectedUser = Object.keys($scope.user).length > 0;
          // all slots are in future
          const areFutureSlots = _.every($scope.events.reserved, function (s) {
            return s.start.isAfter();
          });
          if (isSelectedUser && areFutureSlots) {
            return $scope.modePlans = true;
          } else if (!isSelectedUser) {
          // otherwise we alert, this error musn't occur when the current user hasn't the admin role
            return growl.error(_t('app.shared.cart.please_select_a_member_first'));
          } else if (!areFutureSlots) {
            return growl.error(_t('app.shared.cart.unable_to_select_plan_if_slots_in_the_past'));
          }
        };

        /**
         * Validates the shopping chart and redirect the user to the payment step
         */
        $scope.payCart = function () {
        // first, we check that a user was selected
          if (Object.keys($scope.user).length > 0) {
            // check selected user has a subscription, if any slot is restricted for subscriptions
            const slotValidations = [];
            let slotNotValid;
            let slotNotValidError;
            if ($scope.events.reserved) {
              $scope.events.reserved.forEach(function (slot) {
                if (slot.plan_ids.length > 0) {
                  if (
                    ($scope.selectedPlan && _.includes(slot.plan_ids, $scope.selectedPlan.id)) ||
                    ($scope.user.subscribed_plan && _.includes(slot.plan_ids, $scope.user.subscribed_plan.id))
                  ) {
                    slotValidations.push(true);
                  } else {
                    slotNotValid = slot;
                    if ($scope.selectedPlan && !_.includes(slot.plan_ids, $scope.selectedPlan.id)) {
                      slotNotValidError = 'selectedPlanError';
                    }
                    if ($scope.user.subscribed_plan && !_.includes(slot.plan_ids, $scope.user.subscribed_plan.id)) {
                      slotNotValidError = 'userPlanError';
                    }
                    if (!$scope.selectedPlan || !$scope.user.subscribed_plan) {
                      slotNotValidError = 'noPlanError';
                    }
                    slotValidations.push(false);
                  }
                }
              });
              const hasPlanForSlot = slotValidations.every(function (a) {
                return a;
              });
              if (!hasPlanForSlot) {
                if (!AuthService.isAuthorized(['admin', 'manager'])) {
                  return growl.error(_t('app.shared.cart.slot_restrict_subscriptions_must_select_plan'));
                } else {
                  const modalInstance = $uibModal.open({
                    animation: true,
                    templateUrl: '/shared/_reserve_slot_without_plan.html',
                    size: 'md',
                    controller: 'ReserveSlotWithoutPlanController',
                    resolve: {
                      slot: function () {
                        return slotNotValid;
                      },
                      slotNotValidError: function () {
                        return slotNotValidError;
                      }
                    }
                  });
                  modalInstance.result.then(function (res) {
                    return paySlots();
                  });
                }
              } else {
                return paySlots();
              }
            } else if ($scope.selectedPlan) {
              return paySlots();
            }
          } else {
          // otherwise we alert, this error musn't occur when the current user is not admin or manager
            return growl.error(_t('app.shared.cart.please_select_a_member_first'));
          }
        };

        /**
         * When modifying an already booked reservation, confirm the modification.
         */
        $scope.modifySlot = function () {
          Slot.update({ id: $scope.events.modifiable.slot_id }, {
            slot: {
              start_at: $scope.events.placable.start,
              end_at: $scope.events.placable.end,
              availability_id: $scope.events.placable.availability_id
            }
          }
          , function () { // success
            // -> run the callback
            if (typeof $scope.onSlotModifySuccess === 'function') { $scope.onSlotModifySuccess(); }
            // -> set the events as successfully moved (to display a summary)
            $scope.events.moved = {
              newSlot: $scope.events.placable,
              oldSlot: $scope.events.modifiable
            };
            // -> reset the 'moving' status
            $scope.events.placable = null;
            $scope.events.modifiable = null;
          }
          , function (err) { // failure
            growl.error(_t('app.shared.cart.unable_to_change_the_reservation'));
            console.error(err);
          });
        };

        /**
         * Cancel the current booking modification, reseting the whole process
         * @param [event] {Object} see https://docs.angularjs.org/guide/expression#-event-
         */
        $scope.cancelModifySlot = function (event) {
          if (event) { event.preventDefault(); }
          if (typeof $scope.onSlotModifyCancel === 'function') { $scope.onSlotModifyCancel(); }
          $scope.events.placable = null;
          $scope.events.modifiable = null;
        };

        /**
         * When modifying an already booked reservation, cancel the choice of the new slot
         * @param e {Object} see https://docs.angularjs.org/guide/expression#-event-
         */
        $scope.removeSlotToPlace = function (e) {
          e.preventDefault();
          if (typeof $scope.onSlotModifyUnselect === 'function') { $scope.onSlotModifyUnselect(); }
          $scope.events.placable = null;
        };

        /**
         * Checks if $scope.events.modifiable and $scope.events.placable have tag incompatibilities
         * @returns {boolean} true in case of incompatibility
         */
        $scope.tagMissmatch = function () {
          if ($scope.events.placable.tag_ids.length === 0) { return false; }
          for (const tag of Array.from($scope.events.modifiable.tags)) {
            if (!Array.from($scope.events.placable.tag_ids).includes(tag.id)) {
              return true;
            }
          }
          return false;
        };

        /**
         * Check if the currently logged user has the 'admin' role OR the 'manager' role, but is not taking reseravtion for himself
         * @returns {boolean}
         */
        $scope.isAuthorized = function () {
          if (AuthService.isAuthorized('admin')) return true;

          if (AuthService.isAuthorized('manager')) {
            return ($rootScope.currentUser.id !== $scope.user.id);
          }

          return false;
        };

        /**
         * This will update the payment_schedule setting when the user toggles the switch button
         * @param checked {Boolean}
         */
        $scope.togglePaymentSchedule = (checked) => {
          setTimeout(() => {
            $scope.schedule.requested_schedule = checked;
            updateCartPrice();
            $scope.$apply();
          }, 50);
        };

        /**
         * This will open/close the online payment modal
         */
        $scope.toggleOnlinePaymentModal = (beforeApply) => {
          setTimeout(() => {
            $scope.onlinePayment.showModal = !$scope.onlinePayment.showModal;
            if (typeof beforeApply === 'function') {
              beforeApply();
            }
            $scope.$apply();
          }, 50);
        };

        /**
         * Invoked atfer a successful card payment
         * @param result {*} may be a reservation or a subscription
         */
        $scope.afterOnlinePaymentSuccess = (result) => {
          $scope.toggleOnlinePaymentModal();
          afterPayment(result);
        };

        /* PRIVATE SCOPE */

        /**
         * Kind of constructor: these actions will be realized first when the directive is loaded
         */
        const initialize = function () {
          // What the bound slot
          $scope.$watch('slotSelectionTime', function (newValue, oldValue) {
            if (newValue !== oldValue) {
              slotSelectionChanged();
            }
          });
          $scope.$watch('user', function (newValue, oldValue) {
            if (newValue !== oldValue) {
              resetCartState();
              updateCartPrice();
            }
          });
          $scope.$watch('planSelectionTime', function (newValue, oldValue) {
            if (newValue !== oldValue) {
              planSelectionChanged();
            }
          });
          // watch when a coupon is applied to re-compute the total price
          $scope.$watch('coupon.applied', function (newValue, oldValue) {
            if (newValue !== oldValue) {
              updateCartPrice();
            }
          });
        };

        /**
         * Validates that the current slot is reserved by a member with an authorized tag. Admin and managers can overpass
         * the mismatch.
         * @param slot {Object} fullCalendar event object.
         * @param callback {function}
         */
        const validateTags = function (slot, callback) {
          const interTags = _.intersection.apply(null, [slot.tag_ids, $scope.user.tag_ids]);
          if (slot.tag_ids.length === 0 || interTags.length > 0) {
            if (typeof callback === 'function') callback();
          } else {
            // ask confirmation
            const modalInstance = $uibModal.open({
              animation: true,
              templateUrl: '/shared/_reserve_slot_tags_mismatch.html',
              size: 'md',
              controller: 'ReserveSlotTagsMismatchController',
              resolve: {
                slotTags: function () { return slot.tags; },
                userTags: function () { return $scope.user.tags; },
                userName: function () { return $scope.user.name; }
              }
            });
            modalInstance.result.then(function (res) {
              if (typeof callback === 'function') callback(res);
            });
          }
        };

        /**
         * Validates that no other reservations were made that conflict the current slot and alert the user about the conflict.
         * If the user is an administrator or a manager, he can overpass the conflict.
         * @param slot {Object} fullCalendar event object.
         * @param callback {function}
         */
        const validateSameTimeReservations = function (slot, callback) {
          let sameTimeReservations = [
            'training_reservations',
            'machine_reservations',
            'space_reservations',
            'events_reservations'
          ].map(function (k) {
            return _.filter($scope.user[k], function (r) {
              return slot.start.isSame(r.start_at) ||
                (slot.end.isAfter(r.start_at) && slot.end.isBefore(r.end_at)) ||
                (slot.start.isAfter(r.start_at) && slot.start.isBefore(r.end_at)) ||
                (slot.start.isBefore(r.start_at) && slot.end.isAfter(r.end_at));
            });
          });
          sameTimeReservations = _.union.apply(null, sameTimeReservations);
          if (sameTimeReservations.length > 0) {
            const modalInstance = $uibModal.open({
              animation: true,
              templateUrl: '/shared/_reserve_slot_same_time.html',
              size: 'md',
              controller: 'ReserveSlotSameTimeController',
              resolve: {
                sameTimeReservations: function () { return sameTimeReservations; },
                bookOverlappingSlotsPromise: ['Setting', function (Setting) { return Setting.get({ name: 'book_overlapping_slots' }).$promise; }]
              }
            });
            modalInstance.result.then(function (res) {
              if (typeof callback === 'function') callback(res);
            });
          } else {
            if (typeof callback === 'function') callback();
          }
        };

        /**
         * Callback triggered when the selected slot changed
         */
        const slotSelectionChanged = function () {
          if ($scope.slot) {
            // if this slot is restricted for subscribers...
            if ($scope.slot.plan_ids.length > 0) {
              // ... we select all the plans matching these restrictions...
              const _plans = _.filter($scope.plans, function (p) { return _.includes($scope.slot.plan_ids, p.id); });
              // ... and we group these plans, by Group...
              $scope.slot.plansGrouped = [];
              $scope.slot.group_ids = [];
              for (const group of Array.from($scope.groups)) {
                const groupObj = { id: group.id, name: group.name, plans: [] };
                for (const plan of Array.from(_plans)) {
                  if (plan.group_id === group.id) { groupObj.plans.push(plan); }
                }
                if (groupObj.plans.length > 0) {
                  // ... Finally, we only keep the plans matching the group of the current user
                  // OR all plans if the current user is admin or manager
                  if (AuthService.isAuthorized(['admin', 'manager'])) {
                    $scope.slot.plansGrouped.push(groupObj);
                  } else if ($scope.user.group_id === groupObj.id) {
                    $scope.slot.plansGrouped.push(groupObj);
                  }
                }
              }
              $scope.slot.group_ids = $scope.slot.plansGrouped.map(function (g) { return g.id; });
            }

            if (!$scope.slot.is_reserved && !$scope.events.modifiable && !$scope.slot.is_completed) {
              // slot is not reserved and we are not currently modifying a slot
              // -> can be added to cart or removed if already present
              const index = _.findIndex($scope.events.reserved, (e) => e._id === $scope.slot._id);
              if (index === -1) {
                if (($scope.limitToOneSlot === 'true') && $scope.events.reserved[0]) {
                // if we limit the number of slots in the cart to 1, and there is already
                // a slot in the cart, we remove it before adding the new one
                  $scope.removeSlot($scope.events.reserved[0], 0);
                }
                // slot is not in the cart, so we add it
                $scope.events.reserved.push($scope.slot);
                if (typeof $scope.onSlotAddedToCart === 'function') { $scope.onSlotAddedToCart(); }
              } else {
                // slot is in the cart, remove it
                $scope.removeSlot($scope.slot, index);
              }
              // in every cases, because a new reservation has started, we reset the cart content
              resetCartState();
              // finally, we update the prices
              return updateCartPrice();
            } else if (!$scope.slot.is_reserved && !$scope.slot.is_completed && $scope.events.modifiable) {
              // slot is not reserved but we are currently modifying a slot
              // -> we request the calender to change the rendering
              if (typeof $scope.onSlotModifyUnselect === 'function') {
                // if the callback return false, cancel the selection for the current modification
                const res = $scope.onSlotModifyUnselect();
                if (!res) return;
              }
              // -> then, we re-affect the destination slot
              if (!$scope.events.placable || ($scope.events.placable._id !== $scope.slot._id)) {
                return $scope.events.placable = $scope.slot;
              } else {
                return $scope.events.placable = null;
              }
            } else if ($scope.slot.is_reserved && $scope.events.modifiable && ($scope.slot.is_reserved._id === $scope.events.modifiable._id)) {
              // slot is reserved and currently modified
              // -> we cancel the modification
              $scope.cancelModifySlot();
            } else if ($scope.slot.is_reserved && (slotCanBeModified($scope.slot) || slotCanBeCanceled($scope.slot)) && !$scope.events.modifiable && ($scope.events.reserved.length === 0)) {
              // slot is reserved and is ok to be modified or cancelled
              // but we are not currently running a modification or having any slots in the cart
              // -> first affect the modification/cancellation rights attributes to the current slot
              resetCartState();
              $scope.slot.movable = slotCanBeModified($scope.slot);
              $scope.slot.cancelable = slotCanBeCanceled($scope.slot);
              // -> then, we open a dialog to ask to the user to choose an action
              return dialogs.confirm({
                templateUrl: '/shared/confirm_modify_slot_modal.html',
                resolve: {
                  object () { return $scope.slot; }
                }
              }
              , function (type) {
              // the user has chosen an action, so we proceed
                if (type === 'move') {
                  if (typeof $scope.onSlotStartToModify === 'function') { $scope.onSlotStartToModify(); }
                  $scope.events.modifiable = $scope.slot;
                } else if (type === 'cancel') {
                  dialogs.confirm(
                    {
                      resolve: {
                        object () {
                          return {
                            title: _t('app.shared.cart.confirmation_required'),
                            msg: _t('app.shared.cart.do_you_really_want_to_cancel_this_reservation_html')
                          };
                        }
                      }
                    },
                    function () { // cancel confirmed
                      Slot.cancel({ id: $scope.slot.slot_id }, function () { // successfully canceled
                        growl.success(_t('app.shared.cart.reservation_was_cancelled_successfully'));
                        if (typeof $scope.onSlotCancelSuccess === 'function') { return $scope.onSlotCancelSuccess(); }
                      }
                      , function () { // error while canceling
                        growl.error(_t('app.shared.cart.cancellation_failed'));
                      });
                    }
                  );
                }
              });
            }
          }
        };

        /**
         * Reset the parameters that may lead to a wrong price but leave the content (events added to cart)
         */
        const resetCartState = function () {
          $scope.selectedPlan = null;
          $scope.paidPlan = null;
          $scope.coupon.applied = null;
          $scope.events.moved = null;
          $scope.events.paid = [];
          $scope.events.modifiable = null;
          $scope.events.placable = null;
          $scope.schedule.requested_schedule = false;
          $scope.schedule.payment_schedule = null;
        };

        /**
         * Determines if the provided booked slot is able to be modified by the user.
         * @param slot {Object} fullCalendar event object
         */
        const slotCanBeModified = function (slot) {
          if (AuthService.isAuthorized(['admin', 'manager'])) { return true; }
          const slotStart = moment(slot.start);
          const now = moment();
          return (slot.can_modify && $scope.enableBookingMove && (slotStart.diff(now, 'hours') >= $scope.moveBookingDelay));
        };

        /**
         * Determines if the provided booked slot is able to be canceled by the user.
         * @param slot {Object} fullCalendar event object
         */
        const slotCanBeCanceled = function (slot) {
          if (AuthService.isAuthorized(['admin', 'manager'])) { return true; }
          const slotStart = moment(slot.start);
          const now = moment();
          return (slot.can_modify && $scope.enableBookingCancel && (slotStart.diff(now, 'hours') >= $scope.cancelBookingDelay));
        };

        /**
         * Callback triggered when the selected slot changed
         */
        const planSelectionChanged = function () {
          if (Auth.isAuthenticated()) {
            if ($scope.selectedPlan !== $scope.plan) {
              $scope.selectedPlan = $scope.plan;
              $scope.schedule.requested_schedule = $scope.plan.monthly_payment;
            } else {
              $scope.selectedPlan = null;
            }
            return updateCartPrice();
          } else {
            return $rootScope.login(null, function () {
              $scope.selectedPlan = $scope.plan;
              return updateCartPrice();
            });
          }
        };

        /**
         * Update the total price of the current selection/reservation
         */
        const updateCartPrice = function () {
          if (Object.keys($scope.user).length > 0) {
            const items = [];
            if ($scope.selectedPlan) {
              items.push(mkSubscription($scope.selectedPlan.id));
            }
            if ($scope.events.reserved && $scope.events.reserved.length > 0) {
              items.push(mkReservation($scope.events.reserved));
            }

            return Price.compute(mkCartItems(items), function (res) {
              $scope.amountTotal = res.price;
              $scope.schedule.payment_schedule = res.schedule;
              $scope.totalNoCoupon = res.price_without_coupon;
              setSlotsDetails(res.details);
            });
          } else {
            // otherwise we alert, this error musn't occur when the current user is not admin
            growl.warning(_t('app.shared.cart.please_select_a_member_first'));
            $scope.amountTotal = null;
          }
        };

        const setSlotsDetails = function (details) {
          angular.forEach($scope.events.reserved, function (slot) {
            angular.forEach(details.slots, function (s) {
              if (moment(s.start_at).isSame(slot.start)) {
                slot.promo = s.promo;
                slot.price = s.price;
              }
            });
          });
        };

        /**
         * Create a hash map implementing the Reservation specs
         * @param slots {Array<Object>} Array of fullCalendar events: slots selected on the calendar
         * @return {{reservation: {reservable_type: string, reservable_id: string, slots_attributes: []}}}
         */
        const mkReservation = function (slots) {
          const reservation = {
            reservable_id: $scope.reservableId,
            reservable_type: $scope.reservableType,
            slots_attributes: []
          };
          angular.forEach(slots, function (slot) {
            reservation.slots_attributes.push({
              start_at: slot.start,
              end_at: slot.end,
              availability_id: slot.availability_id,
              offered: slot.offered || false
            });
          });

          return { reservation };
        };

        /**
         * Create a hash map implementing the Subscription specs
         * @param planId {number}
         * @return {{subscription: {plan_id: number}}}
         */
        const mkSubscription = function (planId) {
          return {
            subscription: {
              plan_id: planId
            }
          };
        };

        /**
         * Build the CartItems object, from the current reservation
         * @param items {Array<{reservation:{reservable_type: string, reservable_id: string, slots_attributes: []}}|{subscription: {plan_id: number}}>}
         * @param paymentMethod {string}
         * @return {CartItems}
         */
        const mkCartItems = function (items, paymentMethod = '') {
          const cartItems = {
            customer_id: $scope.user.id,
            payment_schedule: $scope.schedule.requested_schedule,
            payment_method: paymentMethod,
            coupon_code: (($scope.coupon.applied ? $scope.coupon.applied.code : undefined))
          };
          for (const item of items) {
            Object.assign(cartItems, item);
          }
          return cartItems;
        };

        /**
         * Open a modal window that allows the user to process a credit card payment for his current shopping cart.
         */
        const payOnline = function (items) {
          // check that the online payment is enabled
          if ($scope.settings.online_payment_module !== 'true') {
            growl.error(_t('app.shared.cart.online_payment_disabled'));
          } else {
            $scope.toggleOnlinePaymentModal(() => {
              $scope.onlinePayment.cartItems = mkCartItems(items, 'card');
            });
          }
        };
        /**
         * Open a modal window that allows the user to process a local payment for his current shopping cart (admin only).
         */
        const payOnSite = function (items) {
          $uibModal.open({
            templateUrl: '/shared/valid_reservation_modal.html',
            size: $scope.schedule.payment_schedule ? 'lg' : 'sm',
            resolve: {
              price () {
                return Price.compute(mkCartItems(items, '')).$promise;
              },
              cartItems () {
                return mkCartItems(items, '');
              },
              wallet () {
                return Wallet.getWalletByUser({ user_id: $scope.user.id }).$promise;
              },
              coupon () {
                return $scope.coupon.applied;
              },
              selectedPlan () {
                return $scope.selectedPlan;
              },
              schedule () {
                return $scope.schedule;
              },
              user () {
                return $scope.user;
              },
              settings () {
                return $scope.settings;
              }
            },
            controller: ['$scope', '$uibModalInstance', '$state', 'price', 'Auth', 'Reservation', 'Subscription', 'wallet', 'helpers', '$filter', 'coupon', 'selectedPlan', 'schedule', 'cartItems', 'user', 'settings',
              function ($scope, $uibModalInstance, $state, price, Auth, Reservation, Subscription, wallet, helpers, $filter, coupon, selectedPlan, schedule, cartItems, user, settings) {
                // user wallet amount
                $scope.wallet = wallet;

                // Global price (total of all items)
                $scope.price = price.price;

                // Price to pay (wallet deducted)
                $scope.amount = helpers.getAmountToPay(price.price, wallet.amount);

                // Reservation &| subscription
                $scope.cartItems = cartItems;

                // Subscription
                $scope.plan = selectedPlan;

                // Used in wallet info template to interpolate some translations
                $scope.numberFilter = $filter('number');

                // Shows the schedule info in the modal
                $scope.schedule = schedule.payment_schedule;

                // how should we collect payments for the payment schedule
                $scope.method = {
                  payment_method: 'card'
                };

                // "valid" Button label
                $scope.validButtonName = '';

                // online payment modal state
                // this is used to collect card data when a payment-schedule was selected, and paid with a card
                $scope.isOpenOnlinePaymentModal = false;

                // the customer
                $scope.user = user;

                /**
                 * Callback to process the local payment, triggered on button click
                 */
                $scope.ok = function () {
                  if ($scope.schedule && $scope.method.payment_method === 'card') {
                    // check that the online payment is enabled
                    if (settings.online_payment_module !== 'true') {
                      return growl.error(_t('app.shared.cart.online_payment_disabled'));
                    } else {
                      return $scope.toggleOnlinePaymentModal();
                    }
                  }
                  $scope.attempting = true;
                  // save subscription (if there's only a subscription selected)
                  if ((!$scope.cartItems.reservation || $scope.cartItems.reservation.slots_attributes.length === 0) && selectedPlan) {
                    const sub = mkSubscription(selectedPlan.id);

                    return Subscription.save(mkCartItems([sub], $scope.method.payment_method),
                      function (subscription) {
                        $uibModalInstance.close(subscription);
                        $scope.attempting = true;
                      }, function (response) {
                        $scope.alerts = [];
                        $scope.alerts.push({ msg: _t('app.shared.cart.a_problem_occurred_during_the_payment_process_please_try_again_later'), type: 'danger' });
                        $scope.attempting = false;
                      });
                  }
                  // otherwise, save the reservation (may include a subscription)
                  Reservation.save(cartItems, function (reservation) {
                    $uibModalInstance.close(reservation);
                    $scope.attempting = true;
                  }, function (response) {
                    $scope.alerts = [];
                    $scope.alerts.push({ msg: _t('app.shared.cart.a_problem_occurred_during_the_payment_process_please_try_again_later'), type: 'danger' });
                    $scope.attempting = false;
                  });
                };
                /**
                 * Callback to close the modal without processing the payment
                 */
                $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };

                /**
                 * Asynchronously updates the status of the online payment modal
                 */
                $scope.toggleOnlinePaymentModal = function () {
                  setTimeout(() => {
                    $scope.isOpenOnlinePaymentModal = !$scope.isOpenOnlinePaymentModal;
                    $scope.$apply();
                  }, 50);
                };

                /**
                 * After creating a payment schedule by card, from an administrator.
                 * @param result {*} Reservation or Subscription
                 */
                $scope.afterCreatePaymentSchedule = function (result) {
                  $scope.toggleOnlinePaymentModal();
                  $uibModalInstance.close(result);
                };

                /* PRIVATE SCOPE */

                /**
                 * Kind of constructor: these actions will be realized first when the directive is loaded
                 */
                const initialize = function () {
                  $scope.$watch('method.payment_method', function (newValue) {
                    $scope.validButtonName = computeValidButtonName();
                    $scope.cartItems.payment_method = newValue;
                  });
                };

                /**
                 * Compute the Label of the confirmation button
                 */
                const computeValidButtonName = function () {
                  let method = '';
                  if ($scope.schedule) {
                    if (AuthService.isAuthorized(['admin', 'manager']) && $rootScope.currentUser.id !== cartItems.customer_id) {
                      method = $scope.method.payment_method;
                    } else {
                      method = 'card';
                    }
                  }
                  if ($scope.amount > 0) {
                    return _t('app.shared.cart.confirm_payment_of_html', { METHOD: method, AMOUNT: $filter('currency')($scope.amount) });
                  } else {
                    if ((price.price > 0) && ($scope.wallet.amount === 0)) {
                      return _t('app.shared.cart.confirm_payment_of_html', { METHOD: method, AMOUNT: $filter('currency')(price.price) });
                    } else {
                      return _t('app.shared.buttons.confirm');
                    }
                  }
                };

                // # !!! MUST BE CALLED AT THE END of the controller
                initialize();
              }
            ]
          }).result.finally(null).then(function (reservation) { afterPayment(reservation); });
        };

        /**
         * Actions to run after the payment was successful
         * @param paymentResult {*} may be a reservation or a subscription
         */
        const afterPayment = function (paymentResult) {
          // we set the cart content as 'paid' to display a summary of the transaction
          $scope.events.paid = $scope.events.reserved;
          $scope.amountPaid = $scope.amountTotal;
          // we call the external callback if present
          if (typeof $scope.afterPayment === 'function') { $scope.afterPayment(paymentResult); }
          // we reset the coupon, and the cart content, and we unselect the slot
          $scope.coupon.applied = undefined;
          if ($scope.slot) {
            // reservation (+ subscription)
            $scope.slot = undefined;
            $scope.events.reserved = [];
          } else {
            // subscription only
            $scope.events = {};
          }
          $scope.paidPlan = $scope.selectedPlan;
          $scope.selectedPlan = undefined;
          $scope.schedule.requested_schedule = false;
          $scope.schedule.payment_schedule = undefined;
        };

        /**
         * Actions to pay slots (or subscription)
         */
        const paySlots = function () {
          const items = [];
          if ($scope.selectedPlan) {
            items.push(mkSubscription($scope.selectedPlan.id));
          }
          if ($scope.events.reserved && $scope.events.reserved.length > 0) {
            items.push(mkReservation($scope.events.reserved));
          }

          return Wallet.getWalletByUser({ user_id: $scope.user.id }, function (wallet) {
            const amountToPay = helpers.getAmountToPay($scope.amountTotal, wallet.amount);
            if ((AuthService.isAuthorized(['member']) && (amountToPay > 0 || (amountToPay === 0 && hasOtherDeadlines()))) ||
              (AuthService.isAuthorized('manager') && $scope.user.id === $rootScope.currentUser.id && amountToPay > 0)) {
              return payOnline(items);
            } else {
              if (AuthService.isAuthorized(['admin']) ||
                (AuthService.isAuthorized('manager') && $scope.user.id !== $rootScope.currentUser.id) ||
                (amountToPay === 0 && !hasOtherDeadlines())) {
                return payOnSite(items);
              }
            }
          });
        };

        /**
         * Check if the later deadlines of the payment schedule exists and are not equal to zero
         * @return {boolean}
         */
        const hasOtherDeadlines = function () {
          if (!$scope.schedule.payment_schedule) return false;
          if ($scope.schedule.payment_schedule.items.length < 2) return false;
          return $scope.schedule.payment_schedule.items[1].amount !== 0;
        };

        // !!! MUST BE CALLED AT THE END of the directive
        return initialize();
      }
    });
  }
]);

/**
 * Controller of the modal showing the reservations the same date at the same time
 */
Application.Controllers.controller('ReserveSlotSameTimeController', ['$scope', '$uibModalInstance', 'AuthService', 'sameTimeReservations', 'bookOverlappingSlotsPromise',
  function ($scope, $uibModalInstance, AuthService, sameTimeReservations, bookOverlappingSlotsPromise) {
    $scope.sameTimeReservations = sameTimeReservations;
    $scope.bookSlotAtSameTime = (bookOverlappingSlotsPromise.setting.value === 'true');
    $scope.isAuthorized = AuthService.isAuthorized;
    /**
     * Confirmation callback
     */
    $scope.ok = function () {
      $uibModalInstance.close({});
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
 * Controller of the modal showing the slot tags
 */
Application.Controllers.controller('ReserveSlotTagsMismatchController', ['$scope', '$uibModalInstance', 'AuthService', 'slotTags', 'userTags', 'userName',
  function ($scope, $uibModalInstance, AuthService, slotTags, userTags, userName) {
    $scope.slotTags = slotTags;
    $scope.userTags = userTags;
    $scope.userName = userName;
    $scope.isAuthorized = AuthService.isAuthorized;
    /**
     * Confirmation callback
     */
    $scope.ok = function () {
      $uibModalInstance.close({});
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
 * Controller used to alert admin reserve slot without plan
 */
Application.Controllers.controller('ReserveSlotWithoutPlanController', ['$scope', '$uibModalInstance', 'slot', 'slotNotValidError', 'growl', '_t',
  function ($scope, $uibModalInstance, slot, slotNotValidError, growl, _t) {
    $scope.slot = slot;
    $scope.slotNotValidError = slotNotValidError;
    /**
     * Confirmation callback
     */
    $scope.ok = function () {
      $uibModalInstance.close({});
    };
    /**
     * Cancellation callback
     */
    $scope.cancel = function () {
      $uibModalInstance.dismiss('cancel');
    };
  }
]);
