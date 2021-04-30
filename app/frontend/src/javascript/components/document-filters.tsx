import React, { useEffect, useState } from 'react';
import { LabelledInput } from './base/labelled-input';
import { useTranslation } from 'react-i18next';

interface DocumentFiltersProps {
  onFilterChange: (value: { reference: string, customer: string, date: Date }) => void
}

/**
 * This component shows 3 input fields for filtering invoices/payment-schedules by reference, customer name and date
 */
export const DocumentFilters: React.FC<DocumentFiltersProps> = ({ onFilterChange }) => {
  const { t } = useTranslation('admin');

  // stores the value of reference input
  const [referenceFilter, setReferenceFilter] = useState('');
  // stores the value of the customer input
  const [customerFilter, setCustomerFilter] = useState('');
  // stores the value of the date input
  const [dateFilter, setDateFilter] = useState(null);

  /**
   * When any filter changes, trigger the callback with the current value of all filters
   */
  useEffect(() => {
    onFilterChange({ reference: referenceFilter, customer: customerFilter, date: dateFilter });
  }, [referenceFilter, customerFilter, dateFilter])

  /**
   * Callback triggered when the input 'reference' is updated.
   */
  const handleReferenceUpdate = (e) => {
    setReferenceFilter(e.target.value);
  }

  /**
   * Callback triggered when the input 'customer' is updated.
   */
  const handleCustomerUpdate = (e) => {
    setCustomerFilter(e.target.value);
  }

  /**
   * Callback triggered when the input 'date' is updated.
   */
  const handleDateUpdate = (e) => {
    let date = e.target.value;
    if (e.target.value === '') date = null;
    setDateFilter(date);
  }

  return (
    <div className="document-filters">
      <LabelledInput id="reference"
                     label={t('app.admin.invoices.document_filters.reference')}
                     type="text"
                     onChange={handleReferenceUpdate}
                     value={referenceFilter} />
      <LabelledInput id="customer"
                     label={t('app.admin.invoices.document_filters.customer')}
                     type="text"
                     onChange={handleCustomerUpdate}
                     value={customerFilter} />
      <LabelledInput id="reference"
                     label={t('app.admin.invoices.document_filters.date')}
                     type="date"
                     onChange={handleDateUpdate}
                     value={dateFilter ? dateFilter : ''} />
    </div>
  );
}
