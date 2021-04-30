import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import { DocumentFilters } from '../document-filters';
import { PaymentSchedulesTable } from './payment-schedules-table';
import { FabButton } from '../base/fab-button';
import { Loader } from '../base/loader';
import { User } from '../../models/user';
import { PaymentSchedule } from '../../models/payment-schedule';
import { IApplication } from '../../models/application';
import PaymentScheduleAPI from '../../api/payment-schedule';

declare var Application: IApplication;

interface PaymentSchedulesListProps {
  currentUser: User
}

// how many payment schedules should we display for each page?
const PAGE_SIZE = 20;

/**
 * This component shows a list of all payment schedules with their associated deadlines (aka. PaymentScheduleItem) and invoices
 */
const PaymentSchedulesList: React.FC<PaymentSchedulesListProps> = ({ currentUser }) => {
  const { t } = useTranslation('admin');

  // list of displayed payment schedules
  const [paymentSchedules, setPaymentSchedules] = useState<Array<PaymentSchedule>>([]);
  // current page
  const [pageNumber, setPageNumber] = useState<number>(1);
  // current filter, by reference, for the schedules
  const [referenceFilter, setReferenceFilter] = useState<string>(null);
  // current filter, by customer's name, for the schedules
  const [customerFilter, setCustomerFilter] = useState<string>(null);
  // current filter, by date, for the schedules and the deadlines
  const [dateFilter, setDateFilter] = useState<Date>(null);

  /**
   * When the component is loaded first, refresh the list of schedules to fill the first page.
   */
  useEffect(() => {
    handleRefreshList();
  }, []);

  /**
   * Fetch from the API the payments schedules matching the given filters and reset the results table with the new schedules.
   */
  const handleFiltersChange = ({ reference, customer, date }): void => {
    setReferenceFilter(reference);
    setCustomerFilter(customer);
    setDateFilter(date);

    const api = new PaymentScheduleAPI();
    api.list({ query: { reference, customer, date, page: 1, size: PAGE_SIZE }}).then((res) => {
      setPaymentSchedules(res);
    });
  };

  /**
   * Fetch from the API the next payment schedules to display, for the current filters, and append them to the current results table.
   */
  const handleLoadMore = (): void => {
    setPageNumber(pageNumber + 1);

    const api = new PaymentScheduleAPI();
    api.list({ query: { reference: referenceFilter, customer: customerFilter, date: dateFilter, page: pageNumber + 1, size: PAGE_SIZE }}).then((res) => {
      const list = paymentSchedules.concat(res);
      setPaymentSchedules(list);
    });
  }

  /**
   * Reload from te API all the currently displayed payment schedules
   */
  const handleRefreshList = (onError?: (msg: any) => void): void => {
    const api = new PaymentScheduleAPI();
    api.list({ query: { reference: referenceFilter, customer: customerFilter, date: dateFilter, page: 1, size: PAGE_SIZE * pageNumber }}).then((res) => {
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
    <div className="payment-schedules-list">
      <h3>
        <i className="fas fa-filter" />
        {t('app.admin.invoices.payment_schedules.filter_schedules')}
      </h3>
      <div className="schedules-filters">
        <DocumentFilters onFilterChange={handleFiltersChange} />
      </div>
      {!hasSchedules() && <div>{t('app.admin.invoices.payment_schedules.no_payment_schedules')}</div>}
      {hasSchedules() && <div className="schedules-list">
        <PaymentSchedulesTable paymentSchedules={paymentSchedules} showCustomer={true} refreshList={handleRefreshList} operator={currentUser} />
        {hasMoreSchedules() && <FabButton className="load-more" onClick={handleLoadMore}>{t('app.admin.invoices.payment_schedules.load_more')}</FabButton>}
      </div>}
    </div>
  );
}


const PaymentSchedulesListWrapper: React.FC<PaymentSchedulesListProps> = ({ currentUser }) => {
  return (
    <Loader>
      <PaymentSchedulesList currentUser={currentUser} />
    </Loader>
  );
}

Application.Components.component('paymentSchedulesList', react2angular(PaymentSchedulesListWrapper, ['currentUser']));
