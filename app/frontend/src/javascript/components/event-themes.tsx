import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import Select from 'react-select';
import { react2angular } from 'react2angular';
import { Loader } from './base/loader';
import { Event } from '../models/event';
import { EventTheme } from '../models/event-theme';
import { IApplication } from '../models/application';
import EventThemeAPI from '../api/event-theme';

declare var Application: IApplication;

interface EventThemesProps {
  event: Event,
  onChange: (themes: Array<EventTheme>) => void
}

/**
 * Option format, expected by react-select
 * @see https://github.com/JedWatson/react-select
 */
type selectOption = { value: number, label: string };

/**
 * This component shows a select input to edit the themes associated with the event
 */
const EventThemes: React.FC<EventThemesProps> = ({ event, onChange }) => {
  const { t } = useTranslation('shared');

  const [themes, setThemes] = useState<Array<EventTheme>>([]);

  useEffect(() => {
    new EventThemeAPI().index().then(data => setThemes(data));
  }, []);

  /**
   * Check if there's any EventTheme in DB, otherwise we won't display the selector
   */
  const hasThemes = (): boolean => {
    return themes.length > 0;
  };

  /**
   * Return the current theme(s) for the given event, formatted to match the react-select format
   */
  const defaultValues = (): Array<selectOption> => {
    const res = [];
    themes.forEach(t => {
      if (event.event_theme_ids.indexOf(t.id) > -1) {
        res.push({ value: t.id, label: t.name });
      }
    });
    return res;
  }

  /**
   * Callback triggered when the selection has changed.
   * Convert the react-select specific format to an array of EventTheme, and call the provided callback.
   */
  const handleChange = (selectedOptions: Array<selectOption>): void => {
    const res = [];
    selectedOptions.forEach(opt => {
      res.push(themes.find(t => t.id === opt.value));
    })
    onChange(res);
  }

  /**
   * Convert all themes to the react-select format
   */
  const buildOptions = (): Array<selectOption> => {
    return themes.map(t => {
      return { value: t.id, label: t.name }
    });
  }

  return (
    <div className="event-themes">
      {hasThemes() && <div className="event-themes--panel">
        <h3>{ t('app.shared.event.event_themes') }</h3>
        <div className="content">
          <Select defaultValue={defaultValues()}
                  placeholder={t('app.shared.event.select_theme')}
                  onChange={handleChange}
                  options={buildOptions()}
                  isMulti />
        </div>
      </div>}
    </div>
  );
}

const EventThemesWrapper: React.FC<EventThemesProps> = ({ event, onChange }) => {
  return (
    <Loader>
      <EventThemes event={event} onChange={onChange}/>
    </Loader>
  );
}


Application.Components.component('eventThemes', react2angular(EventThemesWrapper, ['event', 'onChange']));
