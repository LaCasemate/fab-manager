import { Reservation } from './reservation';
import { SubscriptionRequest } from './subscription';

export interface PaymentConfirmation {
  requires_action?: boolean,
  payment_intent_client_secret?: string,
  success?: boolean,
  error?: {
    statusText: string
  }
}

export interface IntentConfirmation {
  client_secret: string
}

export enum PaymentMethod {
  Card = 'card',
  Other = ''
}

export interface CartItems {
  customer_id: number,
  reservation?: Reservation,
  subscription?: SubscriptionRequest,
  coupon_code?: string,
  payment_schedule?: boolean,
  payment_method: PaymentMethod
}

export interface UpdateCardResponse {
  updated: boolean,
  error?: string
}
