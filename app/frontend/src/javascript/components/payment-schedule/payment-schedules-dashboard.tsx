import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { PaymentSchedulesTable } from './payment-schedules-table';
import { FabButton } from '../base/fab-button';
import { Loader } from '../base/loader';
import { User } from '../../models/user';
import { PaymentSchedule } from '../../models/payment-schedule';
import { IApplication } from '../../models/application';
import PaymentScheduleAPI from '../../api/payment-schedule';

declare var Application: IApplication;

interface PaymentSchedulesDashboardProps {
  currentUser: User
}

// how many payment schedules should we display for each page?
const PAGE_SIZE = 20;

/**
 * This component shows a list of all payment schedules with their associated deadlines (aka. PaymentScheduleItem) and invoices
 * for the currentUser
 */
const PaymentSchedulesDashboard: React.FC<PaymentSchedulesDashboardProps> = ({ currentUser }) => {
  const { t } = useTranslation('logged');

  // list of displayed payment schedules
  const [paymentSchedules, setPaymentSchedules] = useState<Array<PaymentSchedule>>([]);
  // current page
  const [pageNumber, setPageNumber] = useState<number>(1);

  /**
   * When the component is loaded first, refresh the list of schedules to fill the first page.
   */
  useEffect(() => {
    handleRefreshList();
  }, []);

  /**
   * Fetch from the API the next payment schedules to display, for the current filters, and append them to the current results table.
   */
  const handleLoadMore = (): void => {
    setPageNumber(pageNumber + 1);

    const api = new PaymentScheduleAPI();
    api.index({ query: { page: pageNumber + 1, size: PAGE_SIZE }}).then((res) => {
      const list = paymentSchedules.concat(res);
      setPaymentSchedules(list);
    });
  }

  /**
   * Reload from te API all the currently displayed payment schedules
   */
  const handleRefreshList = (onError?: (msg: any) => void): void => {
    const api = new PaymentScheduleAPI();
    api.index({ query: { page: 1, size: PAGE_SIZE * pageNumber }}).then((res) => {
      setPaymentSchedules(res);
    }).catch((err) => {
      if (typeof onError === 'function') { onError(err.message); }
    });
  }

  /**
   * Check if the current collection of payment schedules is empty or not.
   */
  const hasSchedules = (): boolean => {
    return paymentSchedules.length > 0;
  }

  /**
   * Check if there are some results for the current filters that aren't currently shown.
   */
  const hasMoreSchedules = (): boolean => {
    return hasSchedules() && paymentSchedules.length < paymentSchedules[0].max_length;
  }

  return (
    <div className="payment-schedules-dashboard">
      {!hasSchedules() && <div>{t('app.logged.dashboard.payment_schedules.no_payment_schedules')}</div>}
      {hasSchedules() && <div className="schedules-list">
        <PaymentSchedulesTable paymentSchedules={paymentSchedules} showCustomer={false} refreshList={handleRefreshList} operator={currentUser} />
        {hasMoreSchedules() && <FabButton className="load-more" onClick={handleLoadMore}>{t('app.logged.dashboard.payment_schedules.load_more')}</FabButton>}
      </div>}
    </div>
  );
}


const PaymentSchedulesDashboardWrapper: React.FC<PaymentSchedulesDashboardProps> = ({ currentUser }) => {
  return (
    <Loader>
      <PaymentSchedulesDashboard currentUser={currentUser} />
    </Loader>
  );
}

Application.Components.component('paymentSchedulesDashboard', react2angular(PaymentSchedulesDashboardWrapper, ['currentUser']));
