/**
 * This component shows a list of all payment schedules with their associated deadlines (aka. PaymentScheduleItem) and invoices
 */

import React, { ReactEventHandler, ReactNode, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Loader } from './loader';
import moment from 'moment';
import { IFablab } from '../models/fablab';
import _ from 'lodash';
import { PaymentSchedule, PaymentScheduleItem, PaymentScheduleItemState } from '../models/payment-schedule';
import { FabButton } from './fab-button';
import { FabModal } from './fab-modal';
import PaymentScheduleAPI from '../api/payment-schedule';
import { StripeElements } from './stripe-elements';
import { StripeConfirm } from './stripe-confirm';

declare var Fablab: IFablab;

interface PaymentSchedulesTableProps {
  paymentSchedules: Array<PaymentSchedule>,
  showCustomer?: boolean,
  refreshList: () => void
}

const PaymentSchedulesTableComponent: React.FC<PaymentSchedulesTableProps> = ({ paymentSchedules, showCustomer, refreshList }) => {
  const { t } = useTranslation('admin');

  const [showExpanded, setShowExpanded] = useState<Map<number, boolean>>(new Map());
  const [showConfirmCashing, setShowConfirmCashing] = useState<boolean>(false);
  const [showResolveAction, setShowResolveAction] = useState<boolean>(false);
  const [isConfirmActionDisabled, setConfirmActionDisabled] = useState<boolean>(true);
  const [tempDeadline, setTempDeadline] = useState<PaymentScheduleItem>(null);

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
        {t('app.admin.invoices.schedules_table.download')}
      </a>
    );
  }

  /**
   * Return the human-readable string for the status of the provided deadline.
   */
  const formatState = (item: PaymentScheduleItem): JSX.Element => {
    let res = t(`app.admin.invoices.schedules_table.state_${item.state}`);
    if (item.state === PaymentScheduleItemState.Paid) {
      const key = `app.admin.invoices.schedules_table.method_${item.payment_method}`
      res += ` (${t(key)})`;
    }
    return <span className={`state-${item.state}`}>{res}</span>;
  }

  /**
   * Return the action button(s) for the given deadline
   */
  const itemButtons = (item: PaymentScheduleItem): JSX.Element => {
    switch (item.state) {
      case PaymentScheduleItemState.Paid:
        return downloadButton(TargetType.Invoice, item.invoice_id);
      case PaymentScheduleItemState.Pending:
        return (
          <FabButton onClick={handleConfirmCheckPayment(item)}
                     icon={<i className="fas fa-money-check" />}>
            {t('app.admin.invoices.schedules_table.confirm_payment')}
          </FabButton>
        );
      case PaymentScheduleItemState.RequireAction:
        return (
          <FabButton onClick={handleSolveAction(item)}
                     icon={<i className="fas fa-wrench" />}>
            {t('app.admin.invoices.schedules_table.solve')}
          </FabButton>
        );
      case PaymentScheduleItemState.RequirePaymentMethod:
        return (
          <FabButton onClick={handleUpdateCard(item)}
                     icon={<i className="fas fa-credit-card" />}>
            {t('app.admin.invoices.schedules_table.update_card')}
          </FabButton>
        );
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
        refreshList();
        toggleConfirmCashingModal();
      }
    });
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
      refreshList();
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
  const handleUpdateCard = (item: PaymentScheduleItem): ReactEventHandler => {
    return (): void => {
      /*
      TODO
       - Notify the customer, collect new payment information, and create a new payment method
       - Attach the payment method to the customer
       - Update the default payment method
       - Pay the invoice using the new payment method
       */
    }
  }

  return (
    <div>
      <table className="schedules-table">
        <thead>
        <tr>
          <th className="w-35" />
          <th className="w-200">{t('app.admin.invoices.schedules_table.schedule_num')}</th>
          <th className="w-200">{t('app.admin.invoices.schedules_table.date')}</th>
          <th className="w-120">{t('app.admin.invoices.schedules_table.price')}</th>
          {showCustomer && <th className="w-200">{t('app.admin.invoices.schedules_table.customer')}</th>}
          <th className="w-200"/>
        </tr>
        </thead>
        <tbody>
        {paymentSchedules.map(p => <tr key={p.id}>
          <td colSpan={6}>
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
                <td colSpan={5}>
                  <div>
                    <table className="schedule-items-table">
                      <thead>
                      <tr>
                        <th className="w-120">{t('app.admin.invoices.schedules_table.deadline')}</th>
                        <th className="w-120">{t('app.admin.invoices.schedules_table.amount')}</th>
                        <th className="w-200">{t('app.admin.invoices.schedules_table.state')}</th>
                        <th className="w-200" />
                      </tr>
                      </thead>
                      <tbody>
                      {_.orderBy(p.items, 'due_date').map(item => <tr key={item.id}>
                        <td>{formatDate(item.due_date)}</td>
                        <td>{formatPrice(item.amount)}</td>
                        <td>{formatState(item)}</td>
                        <td>{itemButtons(item)}</td>
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
        <FabModal title={t('app.admin.invoices.schedules_table.confirm_check_cashing')}
                  isOpen={showConfirmCashing}
                  toggleModal={toggleConfirmCashingModal}
                  onConfirm={onCheckCashingConfirmed}
                  closeButton={true}
                  confirmButton={t('app.admin.invoices.schedules_table.confirm_button')}>
          {tempDeadline && <span>
            {t('app.admin.invoices.schedules_table.confirm_check_cashing_body', {
              AMOUNT: formatPrice(tempDeadline.amount),
              DATE: formatDate(tempDeadline.due_date)
            })}
          </span>}
        </FabModal>
        <StripeElements>
          <FabModal title={t('app.admin.invoices.schedules_table.resolve_action')}
                    isOpen={showResolveAction}
                    toggleModal={toggleResolveActionModal}
                    onConfirm={afterAction}
                    confirmButton={t('app.admin.invoices.schedules_table.ok_button')}
                    preventConfirm={isConfirmActionDisabled}>
            {tempDeadline && <StripeConfirm clientSecret={tempDeadline.client_secret} onResponse={toggleConfirmActionButton} />}
          </FabModal>
        </StripeElements>
      </div>
    </div>
  );
};
PaymentSchedulesTableComponent.defaultProps = { showCustomer: false };


export const PaymentSchedulesTable: React.FC<PaymentSchedulesTableProps> = ({ paymentSchedules, showCustomer, refreshList }) => {
  return (
    <Loader>
      <PaymentSchedulesTableComponent paymentSchedules={paymentSchedules} showCustomer={showCustomer} refreshList={refreshList} />
    </Loader>
  );
}
