import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { CartItems, IntentConfirmation, PaymentConfirmation, UpdateCardResponse } from '../models/payment';

export default class StripeAPI {
  static async confirm (stp_payment_method_id: string, cart_items: CartItems): Promise<PaymentConfirmation> {
    const res: AxiosResponse = await apiClient.post(`/api/stripe/confirm_payment`, {
      payment_method_id: stp_payment_method_id,
      cart_items
    });
    return res?.data;
  }

  static async setupIntent (user_id: number): Promise<IntentConfirmation> {
    const res: AxiosResponse = await apiClient.get(`/api/stripe/setup_intent/${user_id}`);
    return res?.data;
  }

  // TODO, type the response
  static async confirmPaymentSchedule (setup_intent_id: string, cart_items: CartItems): Promise<any> {
    const res: AxiosResponse = await apiClient.post(`/api/stripe/confirm_payment_schedule`, {
      setup_intent_id,
      cart_items
    });
    return res?.data;
  }

  static async updateCard (user_id: number, stp_payment_method_id: string): Promise<UpdateCardResponse> {
    const res: AxiosResponse = await apiClient.post(`/api/stripe/update_card`, {
      user_id,
      payment_method_id: stp_payment_method_id,
    });
    return res?.data;
  }
}

