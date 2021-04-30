import { Plan } from './plan';
import { PaymentMethod } from './payment';

export interface Subscription {
  id: number,
  plan_id: number,
  expired_at: Date,
  canceled_at?: Date,
  stripe: boolean,
  plan: Plan
}

export interface SubscriptionRequest {
  plan_id: number
}
