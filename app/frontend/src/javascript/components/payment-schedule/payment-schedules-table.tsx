import React, { ReactEventHandler, ReactNode, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Loader } from '../base/loader';
import moment from 'moment';
import _ from 'lodash';
import { FabButton } from '../base/fab-button';
import { FabModal } from '../base/fab-modal';
import { StripeElements } from '../payment/stripe/stripe-elements';
import { StripeConfirm } from '../payment/stripe/stripe-confirm';
import { StripeCardUpdate } from '../payment/stripe/stripe-card-update';
import { User, UserRole } from '../../models/user';
import { IFablab } from '../../models/fablab';
import { PaymentSchedule, PaymentScheduleItem, PaymentScheduleItemState } from '../../models/payment-schedule';
import PaymentScheduleAPI from '../../api/payment-schedule';

import stripeLogo from '../../../../images/powered_by_stripe.png';
import mastercardLogo from '../../../../images/mastercard.png';
import visaLogo from '../../../../images/visa.png';

declare var Fablab: IFablab;

interface PaymentSchedulesTableProps {
  paymentSchedules: Array<PaymentSchedule>,
  showCustomer?: boolean,
  refreshList: (onError: (msg: any) => void) => void,
  operator: User,
}

/**
 * This component shows a list of all payment schedules with their associated deadlines (aka. PaymentScheduleItem) and invoices
 */
const PaymentSchedulesTableComponent: React.FC<PaymentSchedulesTableProps> = ({ paymentSchedules, showCustomer, refreshList, operator }) => {
  const { t } = useTranslation('shared');

  // for each payment schedule: are the details (all deadlines) shown or hidden?
  const [showExpanded, setShowExpanded] = useState<Map<number, boolean>>(new Map());
  // is open, the modal dialog to confirm the cashing of a check?
  const [showConfirmCashing, setShowConfirmCashing] = useState<boolean>(false);
  // is open, the modal dialog the resolve a pending card payment?
  const [showResolveAction, setShowResolveAction] = useState<boolean>(false);
  // the user cannot confirm the action modal (3D secure), unless he has resolved the pending action
  const [isConfirmActionDisabled, setConfirmActionDisabled] = useState<boolean>(true);
  // is open, the modal dialog to update the card details
  const [showUpdateCard, setShowUpdateCard] = useState<boolean>(false);
  // when an action is triggered on a deadline, the deadline is saved here until the action is done or cancelled.
  const [tempDeadline, setTempDeadline] = useState<PaymentScheduleItem>(null);
  // when an action is triggered on a deadline, the parent schedule is saved here until the action is done or cancelled.
  const [tempSchedule, setTempSchedule] = useState<PaymentSchedule>(null);
  // prevent submitting the form to update the card details, until all required fields are filled correctly
  const [canSubmitUpdateCard, setCanSubmitUpdateCard] = useState<boolean>(true);
  // errors are saved here, if any, for display purposes.
  const [errors, setErrors] = useState<string>(null);
  // is open, the modal dialog to cancel the associated subscription?
  const [showCancelSubscription, setShowCancelSubscription] = useState<boolean>(false);

  /**
   * Check if the requested payment schedule is displayed with its deadlines (PaymentScheduleItem) or without them
   */
  const isExpanded = (paymentScheduleId: number): boolean => {
    return showExpanded.get(paymentScheduleId);
  }

  /**
   * Return the formatted localized date for the given date
   */
  const formatDate = (date: Date): string => {
    return Intl.DateTimeFormat().format(moment(date).toDate());
  }
  /**
   * Return the formatted localized amount for the given price (eg. 20.5 => "20,50 €")
   */
  const formatPrice = (price: number): string => {
    return new Intl.NumberFormat(Fablab.intl_locale, {style: 'currency', currency: Fablab.intl_currency}).format(price);
  }

  /**
   * Return the value for the CSS property 'display', for the payment schedule deadlines
   */
  const statusDisplay = (paymentScheduleId: number): string => {
    if (isExpanded(paymentScheduleId)) {
      return 'table-row'
    } else {
      return 'none';
    }
  }

  /**
   * Return the action icon for showing/hiding the deadlines
   */
  const expandCollapseIcon = (paymentScheduleId: number): JSX.Element => {
    if (isExpanded(paymentScheduleId)) {
      return <i className="fas fa-minus-square" />;
    } else {
      return <i className="fas fa-plus-square" />
    }
  }

  /**
   * Show or hide the deadlines for the provided payment schedule, inverting their current status
   */
  const togglePaymentScheduleDetails = (paymentScheduleId: number): ReactEventHandler => {
    return (): void => {
      if (isExpanded(paymentScheduleId)) {
        setShowExpanded((prev) => new Map(prev).set(paymentScheduleId, false));
      } else {
        setShowExpanded((prev) => new Map(prev).set(paymentScheduleId, true));
      }
    }
  }

  /**
   * For use with downloadButton()
   */
  enum TargetType {
    Invoice = 'invoices',
    PaymentSchedule = 'payment_schedules'
  }

  /**
   * Return a button to download a PDF file, may be an invoice, or a payment schedule, depending or the provided parameters
   */
  const downloadButton = (target: TargetType, id: number): JSX.Element => {
    const link = `api/${target}/${id}/download`;
    return (
      <a href={link} target="_blank" className="download-button">
        <i className="fas fa-download" />
        {t('app.shared.schedules_table.download')}
      </a>
    );
  }

  /**
   * Return the human-readable string for the status of the provided deadline.
   */
  const formatState = (item: PaymentScheduleItem): JSX.Element => {
    let res = t(`app.shared.schedules_table.state_${item.state}`);
    if (item.state === PaymentScheduleItemState.Paid) {
      const key = `app.shared.schedules_table.method_${item.payment_method}`
      res += ` (${t(key)})`;
    }
    return <span className={`state-${item.state}`}>{res}</span>;
  }

  /**
   * Check if the current operator has administrative rights or is a normal member
   */
  const isPrivileged = (): boolean => {
    return (operator.role === UserRole.Admin || operator.role == UserRole.Manager);
  }

  /**
   * Return the action button(s) for the given deadline
   */
  const itemButtons = (item: PaymentScheduleItem, schedule: PaymentSchedule): JSX.Element => {
    switch (item.state) {
      case PaymentScheduleItemState.Paid:
        return downloadButton(TargetType.Invoice, item.invoice_id);
      case PaymentScheduleItemState.Pending:
        if (isPrivileged()) {
          return (
            <FabButton onClick={handleConfirmCheckPayment(item)}
                       icon={<i className="fas fa-money-check" />}>
              {t('app.shared.schedules_table.confirm_payment')}
            </FabButton>
          );
        } else {
          return <span>{t('app.shared.schedules_table.please_ask_reception')}</span>
        }
      case PaymentScheduleItemState.RequireAction:
        return (
          <FabButton onClick={handleSolveAction(item)}
                     icon={<i className="fas fa-wrench" />}>
            {t('app.shared.schedules_table.solve')}
          </FabButton>
        );
      case PaymentScheduleItemState.RequirePaymentMethod:
        return (
          <FabButton onClick={handleUpdateCard(item, schedule)}
                     icon={<i className="fas fa-credit-card" />}>
            {t('app.shared.schedules_table.update_card')}
          </FabButton>
        );
      case PaymentScheduleItemState.Error:
        if (isPrivileged()) {
          return (
            <FabButton onClick={handleCancelSubscription(schedule)}
                       icon={<i className="fas fa-times" />}>
              {t('app.shared.schedules_table.cancel_subscription')}
            </FabButton>
          )
        } else {
          return <span>{t('app.shared.schedules_table.please_ask_reception')}</span>
        }
      default:
        return <span />
    }
  }

  /**
   * Callback triggered when the user's clicks on the "cash check" button: show a confirmation modal
   */
  const handleConfirmCheckPayment = (item: PaymentScheduleItem): ReactEventHandler => {
    return (): void => {
      setTempDeadline(item);
      toggleConfirmCashingModal();
    }
  }

  /**
   * After the user has confirmed that he wants to cash the check, update the API, refresh the list and close the modal.
   */
  const onCheckCashingConfirmed = (): void => {
    const api = new PaymentScheduleAPI();
    api.cashCheck(tempDeadline.id).then((res) => {
      if (res.state === PaymentScheduleItemState.Paid) {
        refreshSchedulesTable();
        toggleConfirmCashingModal();
      }
    });
  }

  /**
   * Refresh all payment schedules in the table
   */
  const refreshSchedulesTable = (): void => {
    refreshList(setErrors);
  }

  /**
   * Show/hide the modal dialog that enable to confirm the cashing of the check for a given deadline.
   */
  const toggleConfirmCashingModal = (): void => {
    setShowConfirmCashing(!showConfirmCashing);
  }

  /**
   * Show/hide the modal dialog that trigger the card "action".
   */
  const toggleResolveActionModal = (): void => {
    setShowResolveAction(!showResolveAction);
  }

  /**
   * Callback triggered when the user's clicks on the "resolve" button: show a modal that will trigger the action
   */
  const handleSolveAction = (item: PaymentScheduleItem): ReactEventHandler => {
    return (): void => {
      setTempDeadline(item);
      toggleResolveActionModal();
    }
  }

  /**
   * After the action was done (successfully or not), ask the API to refresh the item status, then refresh the list and close the modal
   */
  const afterAction = (): void => {
    toggleConfirmActionButton();
    const api = new PaymentScheduleAPI();
    api.refreshItem(tempDeadline.id).then(() => {
      refreshSchedulesTable();
      toggleResolveActionModal();
    });
  }

  /**
   * Enable/disable the confirm button of the "action" modal
   */
  const toggleConfirmActionButton = (): void => {
    setConfirmActionDisabled(!isConfirmActionDisabled);
  }

  /**
   * Callback triggered when the user's clicks on the "update card" button: show a modal to input a new card
   */
  const handleUpdateCard = (item: PaymentScheduleItem, paymentSchedule: PaymentSchedule): ReactEventHandler => {
    return (): void => {
      setTempDeadline(item);
      setTempSchedule(paymentSchedule);
      toggleUpdateCardModal();
    }
  }

  /**
   * Show/hide the modal dialog to update the bank card details
   */
  const toggleUpdateCardModal = (): void => {
    setShowUpdateCard(!showUpdateCard);
  }

  /**
   * Return the logos, shown in the modal footer.
   */
  const logoFooter = (): ReactNode => {
    return (
      <div className="stripe-modal-icons">
        <i className="fa fa-lock fa-2x m-r-sm pos-rlt" />
        <img src={stripeLogo} alt="powered by stripe" />
        <img src={mastercardLogo} alt="mastercard" />
        <img src={visaLogo} alt="visa" />
      </div>
    );
  }

  /**
   * When the submit button is pushed, disable it to prevent double form submission
   */
  const handleCardUpdateSubmit = (): void => {
    setCanSubmitUpdateCard(false);
  }

  /**
   * When the card was successfully updated, pay the invoice (using the new payment method) and close the modal
   */
  const handleCardUpdateSuccess = (): void => {
    const api = new PaymentScheduleAPI();
    api.payItem(tempDeadline.id).then(() => {
      refreshSchedulesTable();
      toggleUpdateCardModal();
    }).catch((err) => {
      handleCardUpdateError(err);
    });
  }

  /**
   * When the card was not updated, show the error
   */
  const handleCardUpdateError = (error): void => {
    setErrors(error);
    setCanSubmitUpdateCard(true);
  }

  /**
   * Callback triggered when the user clicks on the "cancel subscription" button
   */
  const handleCancelSubscription = (schedule: PaymentSchedule): ReactEventHandler => {
    return (): void => {
      setTempSchedule(schedule);
      toggleCancelSubscriptionModal();
    }
  }

  /**
   * Show/hide the modal dialog to cancel the current subscription
   */
  const toggleCancelSubscriptionModal = (): void => {
    setShowCancelSubscription(!showCancelSubscription);
  }

  /**
   * When the user has confirmed the cancellation, we transfer the request to the API
   */
  const onCancelSubscriptionConfirmed = (): void => {
    const api = new PaymentScheduleAPI();
    api.cancel(tempSchedule.id).then(() => {
      refreshSchedulesTable();
      toggleCancelSubscriptionModal();
    });
  }

  return (
    <div>
      <table className="schedules-table">
        <thead>
        <tr>
          <th className="w-35" />
          <th className="w-200">{t('app.shared.schedules_table.schedule_num')}</th>
          <th className="w-200">{t('app.shared.schedules_table.date')}</th>
          <th className="w-120">{t('app.shared.schedules_table.price')}</th>
          {showCustomer && <th className="w-200">{t('app.shared.schedules_table.customer')}</th>}
          <th className="w-200"/>
        </tr>
        </thead>
        <tbody>
        {paymentSchedules.map(p => <tr key={p.id}>
          <td colSpan={showCustomer ? 6 : 5}>
            <table className="schedules-table-body">
              <tbody>
              <tr>
                <td className="w-35 row-header" onClick={togglePaymentScheduleDetails(p.id)}>{expandCollapseIcon(p.id)}</td>
                <td className="w-200">{p.reference}</td>
                <td className="w-200">{formatDate(p.created_at)}</td>
                <td className="w-120">{formatPrice(p.total)}</td>
                {showCustomer && <td className="w-200">{p.user.name}</td>}
                <td className="w-200">{downloadButton(TargetType.PaymentSchedule, p.id)}</td>
              </tr>
              <tr style={{ display: statusDisplay(p.id) }}>
                <td className="w-35" />
                <td colSpan={showCustomer ? 5 : 4}>
                  <div>
                    <table className="schedule-items-table">
                      <thead>
                      <tr>
                        <th className="w-120">{t('app.shared.schedules_table.deadline')}</th>
                        <th className="w-120">{t('app.shared.schedules_table.amount')}</th>
                        <th className="w-200">{t('app.shared.schedules_table.state')}</th>
                        <th className="w-200" />
                      </tr>
                      </thead>
                      <tbody>
                      {_.orderBy(p.items, 'due_date').map(item => <tr key={item.id}>
                        <td>{formatDate(item.due_date)}</td>
                        <td>{formatPrice(item.amount)}</td>
                        <td>{formatState(item)}</td>
                        <td>{itemButtons(item, p)}</td>
                      </tr>)}
                      </tbody>
                    </table>
                  </div>
                </td>
              </tr>
              </tbody>
            </table>
          </td>
        </tr>)}
        </tbody>
      </table>
      <div className="modals">
        <FabModal title={t('app.shared.schedules_table.confirm_check_cashing')}
                  isOpen={showConfirmCashing}
                  toggleModal={toggleConfirmCashingModal}
                  onConfirm={onCheckCashingConfirmed}
                  closeButton={true}
                  confirmButton={t('app.shared.schedules_table.confirm_button')}>
          {tempDeadline && <span>
            {t('app.shared.schedules_table.confirm_check_cashing_body', {
              AMOUNT: formatPrice(tempDeadline.amount),
              DATE: formatDate(tempDeadline.due_date)
            })}
          </span>}
        </FabModal>
        <FabModal title={t('app.shared.schedules_table.cancel_subscription')}
                  isOpen={showCancelSubscription}
                  toggleModal={toggleCancelSubscriptionModal}
                  onConfirm={onCancelSubscriptionConfirmed}
                  closeButton={true}
                  confirmButton={t('app.shared.schedules_table.confirm_button')}>
          {t('app.shared.schedules_table.confirm_cancel_subscription')}
        </FabModal>
        <StripeElements>
          <FabModal title={t('app.shared.schedules_table.resolve_action')}
                    isOpen={showResolveAction}
                    toggleModal={toggleResolveActionModal}
                    onConfirm={afterAction}
                    confirmButton={t('app.shared.schedules_table.ok_button')}
                    preventConfirm={isConfirmActionDisabled}>
            {tempDeadline && <StripeConfirm clientSecret={tempDeadline.client_secret} onResponse={toggleConfirmActionButton} />}
          </FabModal>
          <FabModal title={t('app.shared.schedules_table.update_card')}
                    isOpen={showUpdateCard}
                    toggleModal={toggleUpdateCardModal}
                    closeButton={false}
                    customFooter={logoFooter()}
                    className="update-card-modal">
            {tempDeadline && tempSchedule && <StripeCardUpdate onSubmit={handleCardUpdateSubmit}
                                                               onSuccess={handleCardUpdateSuccess}
                                                               onError={handleCardUpdateError}
                                                               customerId={tempSchedule.user.id}
                                                               operator={operator}
                                                               className="card-form" >
              {errors && <div className="stripe-errors">
                {errors}
              </div>}
            </StripeCardUpdate>}
            <div className="submit-card">
              {canSubmitUpdateCard && <button type="submit" disabled={!canSubmitUpdateCard} form="stripe-card" className="submit-card-btn">{t('app.shared.schedules_table.validate_button')}</button>}
              {!canSubmitUpdateCard && <div className="payment-pending">
                <div className="fa-2x">
                  <i className="fas fa-circle-notch fa-spin" />
                </div>
              </div>}
            </div>
          </FabModal>
        </StripeElements>
      </div>
    </div>
  );
};
PaymentSchedulesTableComponent.defaultProps = { showCustomer: false };


export const PaymentSchedulesTable: React.FC<PaymentSchedulesTableProps> = ({ paymentSchedules, showCustomer, refreshList, operator }) => {
  return (
    <Loader>
      <PaymentSchedulesTableComponent paymentSchedules={paymentSchedules} showCustomer={showCustomer} refreshList={refreshList} operator={operator} />
    </Loader>
  );
}
