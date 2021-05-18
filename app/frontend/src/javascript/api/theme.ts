import apiClient from './clients/api-client';
import { AxiosResponse } from 'axios';
import { Theme } from '../models/theme';

export default class ThemeAPI {
  async index (): Promise<Array<Theme>> {
    const res: AxiosResponse<Array<Theme>> = await apiClient.get(`/api/themes`);
    return res?.data;
  }
}

