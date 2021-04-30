import React from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import moment from 'moment';
import _ from 'lodash'
import { IApplication } from '../models/application';
import { Plan } from '../models/plan';
import { User, UserRole } from '../models/user';
import { Loader } from './base/loader';
import '../lib/i18n';
import { IFablab } from '../models/fablab';

declare var Application: IApplication;
declare var Fablab: IFablab;

interface PlanCardProps {
  plan: Plan,
  userId?: number,
  subscribedPlanId?: number,
  operator: User,
  isSelected: boolean,
  onSelectPlan: (plan: Plan) => void,
}

/**
 * This component is a "card" (visually), publicly presenting the details of a plan and allowing a user to subscribe.
 */
const PlanCard: React.FC<PlanCardProps> = ({ plan, userId, subscribedPlanId, operator, onSelectPlan, isSelected }) => {
  const { t } = useTranslation('public');
  /**
   * Return the formatted localized amount of the given plan (eg. 20.5 => "20,50 €")
   */
  const amount = () : string => {
    return new Intl.NumberFormat(Fablab.intl_locale, {style: 'currency', currency: Fablab.intl_currency}).format(plan.amount);
  }
  /**
   * Return the formatted localized amount, divided by the number of months (eg. 120 => "10,00 € / month")
   */
  const monthlyAmount = (): string => {
    const monthly = plan.amount / moment.duration(plan.interval_count, plan.interval).asMonths();
    return new Intl.NumberFormat(Fablab.intl_locale, {style: 'currency', currency: Fablab.intl_currency}).format(monthly);
  }
  /**
   * Return the formatted localized duration of te given plan (eg. Month/3 => "3 mois")
   */
  const duration = (): string => {
    return moment.duration(plan.interval_count, plan.interval).humanize();
  }
  /**
   * Check if the user can subscribe to the current plan, for himself
   */
  const canSubscribeForMe = (): boolean => {
    return operator?.role === UserRole.Member || (operator?.role === UserRole.Manager && userId === operator?.id)
  }
  /**
   * Check if the user can subscribe to the current plan, for someone else
   */
  const canSubscribeForOther = (): boolean => {
    return operator?.role === UserRole.Admin || (operator?.role === UserRole.Manager && userId !== operator?.id)
  }
  /**
   * Check it the user has subscribed to this plan or not
   */
  const hasSubscribedToThisPlan = (): boolean => {
    return subscribedPlanId === plan.id;
  }
  /**
   * Check if the plan has an attached file
   */
  const hasAttachment = (): boolean => {
    return !!plan.plan_file_url;
  }
  /**
   * Check if the plan has a description
   */
  const hasDescription = (): boolean => {
    return !!plan.description;
  }
  /**
   * Check if the plan is allowing a monthly payment schedule
   */
  const canBeScheduled = (): boolean => {
    return plan.monthly_payment;
  }
  /**
   * Callback triggered when the user select the plan
   */
  const handleSelectPlan = (): void => {
    onSelectPlan(plan);
  }
  return (
    <div className="plan-card">
      <h3 className="title">{plan.base_name}</h3>
      <div className="content">
        {canBeScheduled() && <div className="wrap-monthly">
          <div className="price">
            <div className="amount">{t('app.public.plans.AMOUNT_per_month', {AMOUNT: monthlyAmount()})}</div>
            <span className="period">{duration()}</span>
          </div>
        </div>}
        {!canBeScheduled() && <div className="wrap">
          <div className="price">
            <div className="amount">{amount()}</div>
            <span className="period">{duration()}</span>
          </div>
        </div>}
      </div>
      <div className="card-footer">
        {hasDescription() && <div className="plan-description" dangerouslySetInnerHTML={{__html: plan.description}}/>}
        {hasAttachment() && <a className="info-link" href={ plan.plan_file_url } target="_blank">{ t('app.public.plans.more_information') }</a>}
        {canSubscribeForMe() && <div className="cta-button">
          {!hasSubscribedToThisPlan() && <button className={`subscribe-button ${isSelected ? 'selected-card' : ''}`}
                                                 onClick={handleSelectPlan}
                                                 disabled={!_.isNil(subscribedPlanId)}>
            {userId && <span>{t('app.public.plans.i_choose_that_plan')}</span>}
            {!userId && <span>{t('app.public.plans.i_subscribe_online')}</span>}
          </button>}
          {hasSubscribedToThisPlan() && <button className="subscribe-button selected-card" disabled>
            { t('app.public.plans.i_already_subscribed') }
          </button>}
        </div>}
        {canSubscribeForOther() && <div className="cta-button">
          <button className={`subscribe-button ${isSelected ? 'selected-card' : ''}`}
                  onClick={handleSelectPlan}
                  disabled={_.isNil(userId)}>
            <span>{ t('app.public.plans.i_choose_that_plan') }</span>
          </button>
        </div>}
      </div>
    </div>
  );
}

const PlanCardWrapper: React.FC<PlanCardProps> = ({ plan, userId, subscribedPlanId, operator, onSelectPlan, isSelected }) => {
  return (
    <Loader>
      <PlanCard plan={plan} userId={userId} subscribedPlanId={subscribedPlanId} operator={operator} isSelected={isSelected} onSelectPlan={onSelectPlan}/>
    </Loader>
  );
}

Application.Components.component('planCard', react2angular(PlanCardWrapper, ['plan', 'userId', 'subscribedPlanId', 'operator', 'onSelectPlan', 'isSelected']));
