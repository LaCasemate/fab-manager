import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { EventTheme } from '../models/event-theme';

export default class EventThemeAPI {
  async index (): Promise<Array<EventTheme>> {
    const res: AxiosResponse<Array<EventTheme>> = await apiClient.get(`/api/event_themes`);
    return res?.data;
  }
}
