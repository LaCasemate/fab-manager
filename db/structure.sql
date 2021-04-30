SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: f_unaccent(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.f_unaccent(text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
             SELECT public.unaccent('public.unaccent', $1)
             $_$;


--
-- Name: fill_search_vector_for_project(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fill_search_vector_for_project() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      declare
        step_title record;
        step_description record;

      begin
        select title into step_title from project_steps where project_id = new.id;
        select string_agg(description, ' ') as content into step_description from project_steps where project_id = new.id;

        new.search_vector :=
          setweight(to_tsvector('pg_catalog.french', unaccent(coalesce(new.name, ''))), 'A') ||
          setweight(to_tsvector('pg_catalog.french', unaccent(coalesce(new.tags, ''))), 'B') ||
          setweight(to_tsvector('pg_catalog.french', unaccent(coalesce(new.description, ''))), 'D') ||
          setweight(to_tsvector('pg_catalog.french', unaccent(coalesce(step_title.title, ''))), 'C') ||
          setweight(to_tsvector('pg_catalog.french', unaccent(coalesce(step_description.content, ''))), 'D');

        return new;
      end
      $$;


--
-- Name: pg_search_dmetaphone(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pg_search_dmetaphone(text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
  SELECT array_to_string(ARRAY(SELECT dmetaphone(unnest(regexp_split_to_array($1, E'\\s+')))), ' ')
$_$;


SET default_tablespace = '';

--
-- Name: abuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.abuses (
    id integer NOT NULL,
    signaled_type character varying,
    signaled_id integer,
    first_name character varying,
    last_name character varying,
    email character varying,
    message text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: abuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.abuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: abuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.abuses_id_seq OWNED BY public.abuses.id;


--
-- Name: accounting_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounting_periods (
    id integer NOT NULL,
    start_at date,
    end_at date,
    closed_at timestamp without time zone,
    closed_by integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    period_total integer,
    perpetual_total integer,
    footprint character varying
);


--
-- Name: accounting_periods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounting_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounting_periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounting_periods_id_seq OWNED BY public.accounting_periods.id;


--
-- Name: addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.addresses (
    id integer NOT NULL,
    address character varying,
    street_number character varying,
    route character varying,
    locality character varying,
    country character varying,
    postal_code character varying,
    placeable_type character varying,
    placeable_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.addresses_id_seq OWNED BY public.addresses.id;


--
-- Name: age_ranges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.age_ranges (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    slug character varying
);


--
-- Name: age_ranges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.age_ranges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: age_ranges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.age_ranges_id_seq OWNED BY public.age_ranges.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assets (
    id integer NOT NULL,
    viewable_type character varying,
    viewable_id integer,
    attachment character varying,
    type character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assets_id_seq OWNED BY public.assets.id;


--
-- Name: auth_providers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_providers (
    id integer NOT NULL,
    name character varying,
    status character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    providable_type character varying,
    providable_id integer
);


--
-- Name: auth_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auth_providers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auth_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auth_providers_id_seq OWNED BY public.auth_providers.id;


--
-- Name: availabilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.availabilities (
    id integer NOT NULL,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    available_type character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nb_total_places integer,
    destroying boolean DEFAULT false,
    lock boolean DEFAULT false,
    is_recurrent boolean,
    occurrence_id integer,
    period character varying,
    nb_periods integer,
    end_date timestamp without time zone,
    slot_duration integer
);


--
-- Name: availabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.availabilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: availabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.availabilities_id_seq OWNED BY public.availabilities.id;


--
-- Name: availability_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.availability_tags (
    id integer NOT NULL,
    availability_id integer,
    tag_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: availability_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.availability_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: availability_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.availability_tags_id_seq OWNED BY public.availability_tags.id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    slug character varying
);


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: components; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.components (
    id integer NOT NULL,
    name character varying NOT NULL
);


--
-- Name: components_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.components_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: components_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.components_id_seq OWNED BY public.components.id;


--
-- Name: coupons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coupons (
    id integer NOT NULL,
    name character varying,
    code character varying,
    percent_off integer,
    valid_until timestamp without time zone,
    max_usages integer,
    active boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    validity_per_user character varying,
    amount_off integer
);


--
-- Name: coupons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.coupons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: coupons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.coupons_id_seq OWNED BY public.coupons.id;


--
-- Name: credits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.credits (
    id integer NOT NULL,
    creditable_type character varying,
    creditable_id integer,
    plan_id integer,
    hours integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: credits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.credits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: credits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.credits_id_seq OWNED BY public.credits.id;


--
-- Name: custom_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_assets (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: custom_assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.custom_assets_id_seq OWNED BY public.custom_assets.id;


--
-- Name: database_providers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.database_providers (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: database_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.database_providers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: database_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.database_providers_id_seq OWNED BY public.database_providers.id;


--
-- Name: event_price_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_price_categories (
    id integer NOT NULL,
    event_id integer,
    price_category_id integer,
    amount integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: event_price_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.event_price_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_price_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.event_price_categories_id_seq OWNED BY public.event_price_categories.id;


--
-- Name: event_themes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_themes (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    slug character varying
);


--
-- Name: event_themes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.event_themes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_themes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.event_themes_id_seq OWNED BY public.event_themes.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id integer NOT NULL,
    title character varying,
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    availability_id integer,
    amount integer,
    nb_total_places integer,
    nb_free_places integer,
    recurrence_id integer,
    age_range_id integer,
    category_id integer
);


--
-- Name: events_event_themes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events_event_themes (
    id integer NOT NULL,
    event_id integer,
    event_theme_id integer
);


--
-- Name: events_event_themes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_event_themes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_event_themes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_event_themes_id_seq OWNED BY public.events_event_themes.id;


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;


--
-- Name: exports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exports (
    id integer NOT NULL,
    category character varying,
    export_type character varying,
    query character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer,
    key character varying,
    extension character varying DEFAULT 'xlsx'::character varying
);


--
-- Name: exports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exports_id_seq OWNED BY public.exports.id;


--
-- Name: footprint_debugs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.footprint_debugs (
    id bigint NOT NULL,
    footprint character varying,
    data character varying,
    klass character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: footprint_debugs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.footprint_debugs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: footprint_debugs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.footprint_debugs_id_seq OWNED BY public.footprint_debugs.id;


--
-- Name: friendly_id_slugs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.friendly_id_slugs (
    id integer NOT NULL,
    slug character varying NOT NULL,
    sluggable_id integer NOT NULL,
    sluggable_type character varying(50),
    scope character varying,
    created_at timestamp without time zone
);


--
-- Name: friendly_id_slugs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.friendly_id_slugs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: friendly_id_slugs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.friendly_id_slugs_id_seq OWNED BY public.friendly_id_slugs.id;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    slug character varying,
    disabled boolean
);


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.groups_id_seq OWNED BY public.groups.id;


--
-- Name: history_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.history_values (
    id integer NOT NULL,
    setting_id integer,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    footprint character varying,
    invoicing_profile_id integer
);


--
-- Name: history_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.history_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: history_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.history_values_id_seq OWNED BY public.history_values.id;


--
-- Name: i_calendar_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.i_calendar_events (
    id integer NOT NULL,
    uid character varying,
    dtstart timestamp without time zone,
    dtend timestamp without time zone,
    summary character varying,
    description character varying,
    attendee character varying,
    i_calendar_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: i_calendar_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.i_calendar_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: i_calendar_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.i_calendar_events_id_seq OWNED BY public.i_calendar_events.id;


--
-- Name: i_calendars; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.i_calendars (
    id integer NOT NULL,
    url character varying,
    name character varying,
    color character varying,
    text_color character varying,
    text_hidden boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: i_calendars_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.i_calendars_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: i_calendars_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.i_calendars_id_seq OWNED BY public.i_calendars.id;


--
-- Name: imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.imports (
    id integer NOT NULL,
    user_id integer,
    attachment character varying,
    update_field character varying,
    category character varying,
    results text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.imports_id_seq OWNED BY public.imports.id;


--
-- Name: invoice_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoice_items (
    id integer NOT NULL,
    invoice_id integer,
    amount integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    description text,
    subscription_id integer,
    invoice_item_id integer,
    footprint character varying
);


--
-- Name: invoice_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invoice_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invoice_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invoice_items_id_seq OWNED BY public.invoice_items.id;


--
-- Name: invoices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoices (
    id integer NOT NULL,
    invoiced_type character varying,
    invoiced_id integer,
    total integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    reference character varying,
    payment_method character varying,
    avoir_date timestamp without time zone,
    invoice_id integer,
    type character varying,
    subscription_to_expire boolean,
    description text,
    wallet_amount integer,
    wallet_transaction_id integer,
    coupon_id integer,
    footprint character varying,
    environment character varying,
    invoicing_profile_id integer,
    operator_profile_id integer,
    statistic_profile_id integer
);


--
-- Name: invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invoices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invoices_id_seq OWNED BY public.invoices.id;


--
-- Name: invoicing_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invoicing_profiles (
    id integer NOT NULL,
    user_id integer,
    first_name character varying,
    last_name character varying,
    email character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: invoicing_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invoicing_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invoicing_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invoicing_profiles_id_seq OWNED BY public.invoicing_profiles.id;


--
-- Name: licences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.licences (
    id integer NOT NULL,
    name character varying NOT NULL,
    description text
);


--
-- Name: licences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.licences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: licences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.licences_id_seq OWNED BY public.licences.id;


--
-- Name: machines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.machines (
    id integer NOT NULL,
    name character varying NOT NULL,
    description text,
    spec text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    slug character varying,
    disabled boolean
);


--
-- Name: machines_availabilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.machines_availabilities (
    id integer NOT NULL,
    machine_id integer,
    availability_id integer
);


--
-- Name: machines_availabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.machines_availabilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machines_availabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.machines_availabilities_id_seq OWNED BY public.machines_availabilities.id;


--
-- Name: machines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.machines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.machines_id_seq OWNED BY public.machines.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    receiver_id integer,
    attached_object_type character varying,
    attached_object_id integer,
    notification_type_id integer,
    is_read boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    receiver_type character varying,
    is_send boolean DEFAULT false,
    meta_data jsonb DEFAULT '"{}"'::jsonb
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: o_auth2_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.o_auth2_mappings (
    id integer NOT NULL,
    o_auth2_provider_id integer,
    local_field character varying,
    api_field character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    local_model character varying,
    api_endpoint character varying,
    api_data_type character varying,
    transformation jsonb
);


--
-- Name: o_auth2_mappings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.o_auth2_mappings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: o_auth2_mappings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.o_auth2_mappings_id_seq OWNED BY public.o_auth2_mappings.id;


--
-- Name: o_auth2_providers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.o_auth2_providers (
    id integer NOT NULL,
    base_url character varying,
    token_endpoint character varying,
    authorization_endpoint character varying,
    client_id character varying,
    client_secret character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    profile_url character varying
);


--
-- Name: o_auth2_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.o_auth2_providers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: o_auth2_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.o_auth2_providers_id_seq OWNED BY public.o_auth2_providers.id;


--
-- Name: offer_days; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offer_days (
    id integer NOT NULL,
    subscription_id integer,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: offer_days_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.offer_days_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offer_days_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.offer_days_id_seq OWNED BY public.offer_days.id;


--
-- Name: open_api_calls_count_tracings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.open_api_calls_count_tracings (
    id integer NOT NULL,
    open_api_client_id integer,
    calls_count integer NOT NULL,
    at timestamp without time zone NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: open_api_calls_count_tracings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.open_api_calls_count_tracings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: open_api_calls_count_tracings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.open_api_calls_count_tracings_id_seq OWNED BY public.open_api_calls_count_tracings.id;


--
-- Name: open_api_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.open_api_clients (
    id integer NOT NULL,
    name character varying,
    calls_count integer DEFAULT 0,
    token character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: open_api_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.open_api_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: open_api_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.open_api_clients_id_seq OWNED BY public.open_api_clients.id;


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizations (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    invoicing_profile_id integer
);


--
-- Name: organizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.organizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.organizations_id_seq OWNED BY public.organizations.id;


--
-- Name: payment_gateway_objects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_gateway_objects (
    id bigint NOT NULL,
    gateway_object_id character varying,
    gateway_object_type character varying,
    item_type character varying,
    item_id bigint
);


--
-- Name: payment_gateway_objects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_gateway_objects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_gateway_objects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_gateway_objects_id_seq OWNED BY public.payment_gateway_objects.id;


--
-- Name: payment_schedule_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_schedule_items (
    id bigint NOT NULL,
    amount integer,
    due_date timestamp without time zone,
    state character varying DEFAULT 'new'::character varying,
    details jsonb DEFAULT '"{}"'::jsonb,
    payment_method character varying,
    client_secret character varying,
    payment_schedule_id bigint,
    invoice_id bigint,
    footprint character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: payment_schedule_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_schedule_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_schedule_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_schedule_items_id_seq OWNED BY public.payment_schedule_items.id;


--
-- Name: payment_schedules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_schedules (
    id bigint NOT NULL,
    scheduled_type character varying,
    scheduled_id bigint,
    total integer,
    reference character varying,
    payment_method character varying,
    wallet_amount integer,
    wallet_transaction_id bigint,
    coupon_id bigint,
    footprint character varying,
    environment character varying,
    invoicing_profile_id bigint,
    statistic_profile_id bigint,
    operator_profile_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: payment_schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_schedules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_schedules_id_seq OWNED BY public.payment_schedules.id;


--
-- Name: plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plans (
    id integer NOT NULL,
    name character varying,
    amount integer,
    "interval" character varying,
    group_id integer,
    stp_plan_id character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    training_credit_nb integer DEFAULT 0,
    is_rolling boolean DEFAULT true,
    description text,
    type character varying,
    base_name character varying,
    ui_weight integer DEFAULT 0,
    interval_count integer DEFAULT 1,
    slug character varying,
    disabled boolean,
    monthly_payment boolean
);


--
-- Name: plans_availabilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plans_availabilities (
    id integer NOT NULL,
    plan_id integer,
    availability_id integer
);


--
-- Name: plans_availabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plans_availabilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plans_availabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plans_availabilities_id_seq OWNED BY public.plans_availabilities.id;


--
-- Name: plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.plans_id_seq OWNED BY public.plans.id;


--
-- Name: price_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.price_categories (
    id integer NOT NULL,
    name character varying,
    conditions text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: price_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.price_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: price_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.price_categories_id_seq OWNED BY public.price_categories.id;


--
-- Name: prices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prices (
    id integer NOT NULL,
    group_id integer,
    plan_id integer,
    priceable_type character varying,
    priceable_id integer,
    amount integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: prices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.prices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: prices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.prices_id_seq OWNED BY public.prices.id;


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id integer NOT NULL,
    user_id integer,
    first_name character varying,
    last_name character varying,
    phone character varying,
    interest text,
    software_mastered text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    facebook character varying,
    twitter character varying,
    google_plus character varying,
    viadeo character varying,
    linkedin character varying,
    instagram character varying,
    youtube character varying,
    vimeo character varying,
    dailymotion character varying,
    github character varying,
    echosciences character varying,
    website character varying,
    pinterest character varying,
    lastfm character varying,
    flickr character varying,
    job character varying,
    tours character varying
);


--
-- Name: profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.profiles_id_seq OWNED BY public.profiles.id;


--
-- Name: project_steps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_steps (
    id integer NOT NULL,
    description text,
    project_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    title character varying,
    step_nb integer
);


--
-- Name: project_steps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_steps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_steps_id_seq OWNED BY public.project_steps.id;


--
-- Name: project_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_users (
    id integer NOT NULL,
    project_id integer,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    is_valid boolean DEFAULT false,
    valid_token character varying
);


--
-- Name: project_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_users_id_seq OWNED BY public.project_users.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id integer NOT NULL,
    name character varying,
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    tags text,
    licence_id integer,
    state character varying,
    slug character varying,
    published_at timestamp without time zone,
    author_statistic_profile_id integer,
    search_vector tsvector
);


--
-- Name: projects_components; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects_components (
    id integer NOT NULL,
    project_id integer,
    component_id integer
);


--
-- Name: projects_components_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.projects_components_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_components_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.projects_components_id_seq OWNED BY public.projects_components.id;


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: projects_machines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects_machines (
    id integer NOT NULL,
    project_id integer,
    machine_id integer
);


--
-- Name: projects_machines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.projects_machines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_machines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.projects_machines_id_seq OWNED BY public.projects_machines.id;


--
-- Name: projects_spaces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects_spaces (
    id integer NOT NULL,
    project_id integer,
    space_id integer
);


--
-- Name: projects_spaces_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.projects_spaces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_spaces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.projects_spaces_id_seq OWNED BY public.projects_spaces.id;


--
-- Name: projects_themes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects_themes (
    id integer NOT NULL,
    project_id integer,
    theme_id integer
);


--
-- Name: projects_themes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.projects_themes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_themes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.projects_themes_id_seq OWNED BY public.projects_themes.id;


--
-- Name: reservations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reservations (
    id integer NOT NULL,
    message text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    reservable_type character varying,
    reservable_id integer,
    nb_reserve_places integer,
    statistic_profile_id integer
);


--
-- Name: reservations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reservations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reservations_id_seq OWNED BY public.reservations.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name character varying,
    resource_type character varying,
    resource_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings (
    id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.settings_id_seq OWNED BY public.settings.id;


--
-- Name: slots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.slots (
    id integer NOT NULL,
    start_at timestamp without time zone,
    end_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    availability_id integer,
    ex_start_at timestamp without time zone,
    ex_end_at timestamp without time zone,
    canceled_at timestamp without time zone,
    offered boolean DEFAULT false,
    destroying boolean DEFAULT false
);


--
-- Name: slots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.slots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: slots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.slots_id_seq OWNED BY public.slots.id;


--
-- Name: slots_reservations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.slots_reservations (
    id integer NOT NULL,
    slot_id integer,
    reservation_id integer
);


--
-- Name: slots_reservations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.slots_reservations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: slots_reservations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.slots_reservations_id_seq OWNED BY public.slots_reservations.id;


--
-- Name: spaces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.spaces (
    id integer NOT NULL,
    name character varying,
    default_places integer,
    description text,
    slug character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    characteristics text,
    disabled boolean
);


--
-- Name: spaces_availabilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.spaces_availabilities (
    id integer NOT NULL,
    space_id integer,
    availability_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: spaces_availabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.spaces_availabilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: spaces_availabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.spaces_availabilities_id_seq OWNED BY public.spaces_availabilities.id;


--
-- Name: spaces_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.spaces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: spaces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.spaces_id_seq OWNED BY public.spaces.id;


--
-- Name: statistic_custom_aggregations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.statistic_custom_aggregations (
    id integer NOT NULL,
    query text,
    statistic_type_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    field character varying,
    es_index character varying,
    es_type character varying
);


--
-- Name: statistic_custom_aggregations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.statistic_custom_aggregations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: statistic_custom_aggregations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.statistic_custom_aggregations_id_seq OWNED BY public.statistic_custom_aggregations.id;


--
-- Name: statistic_fields; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.statistic_fields (
    id integer NOT NULL,
    statistic_index_id integer,
    key character varying,
    label character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    data_type character varying
);


--
-- Name: statistic_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.statistic_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: statistic_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.statistic_fields_id_seq OWNED BY public.statistic_fields.id;


--
-- Name: statistic_graphs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.statistic_graphs (
    id integer NOT NULL,
    statistic_index_id integer,
    chart_type character varying,
    "limit" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: statistic_graphs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.statistic_graphs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: statistic_graphs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.statistic_graphs_id_seq OWNED BY public.statistic_graphs.id;


--
-- Name: statistic_indices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.statistic_indices (
    id integer NOT NULL,
    es_type_key character varying,
    label character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    "table" boolean DEFAULT true,
    ca boolean DEFAULT true
);


--
-- Name: statistic_indices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.statistic_indices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: statistic_indices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.statistic_indices_id_seq OWNED BY public.statistic_indices.id;


--
-- Name: statistic_profile_trainings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.statistic_profile_trainings (
    id integer NOT NULL,
    statistic_profile_id integer,
    training_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: statistic_profile_trainings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.statistic_profile_trainings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: statistic_profile_trainings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.statistic_profile_trainings_id_seq OWNED BY public.statistic_profile_trainings.id;


--
-- Name: statistic_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.statistic_profiles (
    id integer NOT NULL,
    gender boolean,
    birthday date,
    group_id integer,
    user_id integer,
    role_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: statistic_profiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.statistic_profiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: statistic_profiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.statistic_profiles_id_seq OWNED BY public.statistic_profiles.id;


--
-- Name: statistic_sub_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.statistic_sub_types (
    id integer NOT NULL,
    key character varying,
    label character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: statistic_sub_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.statistic_sub_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: statistic_sub_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.statistic_sub_types_id_seq OWNED BY public.statistic_sub_types.id;


--
-- Name: statistic_type_sub_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.statistic_type_sub_types (
    id integer NOT NULL,
    statistic_type_id integer,
    statistic_sub_type_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: statistic_type_sub_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.statistic_type_sub_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: statistic_type_sub_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.statistic_type_sub_types_id_seq OWNED BY public.statistic_type_sub_types.id;


--
-- Name: statistic_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.statistic_types (
    id integer NOT NULL,
    statistic_index_id integer,
    key character varying,
    label character varying,
    graph boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    simple boolean
);


--
-- Name: statistic_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.statistic_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: statistic_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.statistic_types_id_seq OWNED BY public.statistic_types.id;


--
-- Name: stylesheets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stylesheets (
    id integer NOT NULL,
    contents text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    name character varying
);


--
-- Name: stylesheets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stylesheets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stylesheets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stylesheets_id_seq OWNED BY public.stylesheets.id;


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id integer NOT NULL,
    plan_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    expiration_date timestamp without time zone,
    canceled_at timestamp without time zone,
    statistic_profile_id integer
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.subscriptions_id_seq OWNED BY public.subscriptions.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: themes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.themes (
    id integer NOT NULL,
    name character varying NOT NULL
);


--
-- Name: themes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.themes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: themes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.themes_id_seq OWNED BY public.themes.id;


--
-- Name: tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tickets (
    id integer NOT NULL,
    reservation_id integer,
    event_price_category_id integer,
    booked integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tickets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tickets_id_seq OWNED BY public.tickets.id;


--
-- Name: trainings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trainings (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    nb_total_places integer,
    slug character varying,
    description text,
    public_page boolean DEFAULT true,
    disabled boolean
);


--
-- Name: trainings_availabilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trainings_availabilities (
    id integer NOT NULL,
    training_id integer,
    availability_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: trainings_availabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trainings_availabilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trainings_availabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trainings_availabilities_id_seq OWNED BY public.trainings_availabilities.id;


--
-- Name: trainings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trainings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trainings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trainings_id_seq OWNED BY public.trainings.id;


--
-- Name: trainings_machines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trainings_machines (
    id integer NOT NULL,
    training_id integer,
    machine_id integer
);


--
-- Name: trainings_machines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trainings_machines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trainings_machines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trainings_machines_id_seq OWNED BY public.trainings_machines.id;


--
-- Name: trainings_pricings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trainings_pricings (
    id integer NOT NULL,
    group_id integer,
    amount integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    training_id integer
);


--
-- Name: trainings_pricings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.trainings_pricings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trainings_pricings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.trainings_pricings_id_seq OWNED BY public.trainings_pricings.id;


--
-- Name: user_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_tags (
    id integer NOT NULL,
    user_id integer,
    tag_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_tags_id_seq OWNED BY public.user_tags.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    is_allow_contact boolean DEFAULT true,
    group_id integer,
    username character varying,
    slug character varying,
    is_active boolean DEFAULT true,
    provider character varying,
    uid character varying,
    auth_token character varying,
    merged_at timestamp without time zone,
    is_allow_newsletter boolean,
    current_sign_in_ip inet,
    last_sign_in_ip inet
);


--
-- Name: users_credits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_credits (
    id integer NOT NULL,
    user_id integer,
    credit_id integer,
    hours_used integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: users_credits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_credits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_credits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_credits_id_seq OWNED BY public.users_credits.id;


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: users_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_roles (
    user_id integer,
    role_id integer
);


--
-- Name: wallet_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wallet_transactions (
    id integer NOT NULL,
    wallet_id integer,
    transactable_type character varying,
    transactable_id integer,
    transaction_type character varying,
    amount integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    invoicing_profile_id integer
);


--
-- Name: wallet_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wallet_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wallet_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wallet_transactions_id_seq OWNED BY public.wallet_transactions.id;


--
-- Name: wallets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wallets (
    id integer NOT NULL,
    amount integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    invoicing_profile_id integer
);


--
-- Name: wallets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wallets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wallets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wallets_id_seq OWNED BY public.wallets.id;


--
-- Name: abuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.abuses ALTER COLUMN id SET DEFAULT nextval('public.abuses_id_seq'::regclass);


--
-- Name: accounting_periods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting_periods ALTER COLUMN id SET DEFAULT nextval('public.accounting_periods_id_seq'::regclass);


--
-- Name: addresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addresses ALTER COLUMN id SET DEFAULT nextval('public.addresses_id_seq'::regclass);


--
-- Name: age_ranges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.age_ranges ALTER COLUMN id SET DEFAULT nextval('public.age_ranges_id_seq'::regclass);


--
-- Name: assets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets ALTER COLUMN id SET DEFAULT nextval('public.assets_id_seq'::regclass);


--
-- Name: auth_providers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_providers ALTER COLUMN id SET DEFAULT nextval('public.auth_providers_id_seq'::regclass);


--
-- Name: availabilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.availabilities ALTER COLUMN id SET DEFAULT nextval('public.availabilities_id_seq'::regclass);


--
-- Name: availability_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.availability_tags ALTER COLUMN id SET DEFAULT nextval('public.availability_tags_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: components id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.components ALTER COLUMN id SET DEFAULT nextval('public.components_id_seq'::regclass);


--
-- Name: coupons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupons ALTER COLUMN id SET DEFAULT nextval('public.coupons_id_seq'::regclass);


--
-- Name: credits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credits ALTER COLUMN id SET DEFAULT nextval('public.credits_id_seq'::regclass);


--
-- Name: custom_assets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_assets ALTER COLUMN id SET DEFAULT nextval('public.custom_assets_id_seq'::regclass);


--
-- Name: database_providers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.database_providers ALTER COLUMN id SET DEFAULT nextval('public.database_providers_id_seq'::regclass);


--
-- Name: event_price_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_price_categories ALTER COLUMN id SET DEFAULT nextval('public.event_price_categories_id_seq'::regclass);


--
-- Name: event_themes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_themes ALTER COLUMN id SET DEFAULT nextval('public.event_themes_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


--
-- Name: events_event_themes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_event_themes ALTER COLUMN id SET DEFAULT nextval('public.events_event_themes_id_seq'::regclass);


--
-- Name: exports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports ALTER COLUMN id SET DEFAULT nextval('public.exports_id_seq'::regclass);


--
-- Name: footprint_debugs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.footprint_debugs ALTER COLUMN id SET DEFAULT nextval('public.footprint_debugs_id_seq'::regclass);


--
-- Name: friendly_id_slugs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friendly_id_slugs ALTER COLUMN id SET DEFAULT nextval('public.friendly_id_slugs_id_seq'::regclass);


--
-- Name: groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups ALTER COLUMN id SET DEFAULT nextval('public.groups_id_seq'::regclass);


--
-- Name: history_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history_values ALTER COLUMN id SET DEFAULT nextval('public.history_values_id_seq'::regclass);


--
-- Name: i_calendar_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.i_calendar_events ALTER COLUMN id SET DEFAULT nextval('public.i_calendar_events_id_seq'::regclass);


--
-- Name: i_calendars id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.i_calendars ALTER COLUMN id SET DEFAULT nextval('public.i_calendars_id_seq'::regclass);


--
-- Name: imports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imports ALTER COLUMN id SET DEFAULT nextval('public.imports_id_seq'::regclass);


--
-- Name: invoice_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_items ALTER COLUMN id SET DEFAULT nextval('public.invoice_items_id_seq'::regclass);


--
-- Name: invoices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices ALTER COLUMN id SET DEFAULT nextval('public.invoices_id_seq'::regclass);


--
-- Name: invoicing_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoicing_profiles ALTER COLUMN id SET DEFAULT nextval('public.invoicing_profiles_id_seq'::regclass);


--
-- Name: licences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.licences ALTER COLUMN id SET DEFAULT nextval('public.licences_id_seq'::regclass);


--
-- Name: machines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machines ALTER COLUMN id SET DEFAULT nextval('public.machines_id_seq'::regclass);


--
-- Name: machines_availabilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machines_availabilities ALTER COLUMN id SET DEFAULT nextval('public.machines_availabilities_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: o_auth2_mappings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.o_auth2_mappings ALTER COLUMN id SET DEFAULT nextval('public.o_auth2_mappings_id_seq'::regclass);


--
-- Name: o_auth2_providers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.o_auth2_providers ALTER COLUMN id SET DEFAULT nextval('public.o_auth2_providers_id_seq'::regclass);


--
-- Name: offer_days id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offer_days ALTER COLUMN id SET DEFAULT nextval('public.offer_days_id_seq'::regclass);


--
-- Name: open_api_calls_count_tracings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.open_api_calls_count_tracings ALTER COLUMN id SET DEFAULT nextval('public.open_api_calls_count_tracings_id_seq'::regclass);


--
-- Name: open_api_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.open_api_clients ALTER COLUMN id SET DEFAULT nextval('public.open_api_clients_id_seq'::regclass);


--
-- Name: organizations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations ALTER COLUMN id SET DEFAULT nextval('public.organizations_id_seq'::regclass);


--
-- Name: payment_gateway_objects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_gateway_objects ALTER COLUMN id SET DEFAULT nextval('public.payment_gateway_objects_id_seq'::regclass);


--
-- Name: payment_schedule_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_schedule_items ALTER COLUMN id SET DEFAULT nextval('public.payment_schedule_items_id_seq'::regclass);


--
-- Name: payment_schedules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_schedules ALTER COLUMN id SET DEFAULT nextval('public.payment_schedules_id_seq'::regclass);


--
-- Name: plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans ALTER COLUMN id SET DEFAULT nextval('public.plans_id_seq'::regclass);


--
-- Name: plans_availabilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans_availabilities ALTER COLUMN id SET DEFAULT nextval('public.plans_availabilities_id_seq'::regclass);


--
-- Name: price_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_categories ALTER COLUMN id SET DEFAULT nextval('public.price_categories_id_seq'::regclass);


--
-- Name: prices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prices ALTER COLUMN id SET DEFAULT nextval('public.prices_id_seq'::regclass);


--
-- Name: profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles ALTER COLUMN id SET DEFAULT nextval('public.profiles_id_seq'::regclass);


--
-- Name: project_steps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_steps ALTER COLUMN id SET DEFAULT nextval('public.project_steps_id_seq'::regclass);


--
-- Name: project_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_users ALTER COLUMN id SET DEFAULT nextval('public.project_users_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: projects_components id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects_components ALTER COLUMN id SET DEFAULT nextval('public.projects_components_id_seq'::regclass);


--
-- Name: projects_machines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects_machines ALTER COLUMN id SET DEFAULT nextval('public.projects_machines_id_seq'::regclass);


--
-- Name: projects_spaces id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects_spaces ALTER COLUMN id SET DEFAULT nextval('public.projects_spaces_id_seq'::regclass);


--
-- Name: projects_themes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects_themes ALTER COLUMN id SET DEFAULT nextval('public.projects_themes_id_seq'::regclass);


--
-- Name: reservations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations ALTER COLUMN id SET DEFAULT nextval('public.reservations_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings ALTER COLUMN id SET DEFAULT nextval('public.settings_id_seq'::regclass);


--
-- Name: slots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slots ALTER COLUMN id SET DEFAULT nextval('public.slots_id_seq'::regclass);


--
-- Name: slots_reservations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slots_reservations ALTER COLUMN id SET DEFAULT nextval('public.slots_reservations_id_seq'::regclass);


--
-- Name: spaces id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spaces ALTER COLUMN id SET DEFAULT nextval('public.spaces_id_seq'::regclass);


--
-- Name: spaces_availabilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spaces_availabilities ALTER COLUMN id SET DEFAULT nextval('public.spaces_availabilities_id_seq'::regclass);


--
-- Name: statistic_custom_aggregations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_custom_aggregations ALTER COLUMN id SET DEFAULT nextval('public.statistic_custom_aggregations_id_seq'::regclass);


--
-- Name: statistic_fields id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_fields ALTER COLUMN id SET DEFAULT nextval('public.statistic_fields_id_seq'::regclass);


--
-- Name: statistic_graphs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_graphs ALTER COLUMN id SET DEFAULT nextval('public.statistic_graphs_id_seq'::regclass);


--
-- Name: statistic_indices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_indices ALTER COLUMN id SET DEFAULT nextval('public.statistic_indices_id_seq'::regclass);


--
-- Name: statistic_profile_trainings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_profile_trainings ALTER COLUMN id SET DEFAULT nextval('public.statistic_profile_trainings_id_seq'::regclass);


--
-- Name: statistic_profiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_profiles ALTER COLUMN id SET DEFAULT nextval('public.statistic_profiles_id_seq'::regclass);


--
-- Name: statistic_sub_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_sub_types ALTER COLUMN id SET DEFAULT nextval('public.statistic_sub_types_id_seq'::regclass);


--
-- Name: statistic_type_sub_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_type_sub_types ALTER COLUMN id SET DEFAULT nextval('public.statistic_type_sub_types_id_seq'::regclass);


--
-- Name: statistic_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_types ALTER COLUMN id SET DEFAULT nextval('public.statistic_types_id_seq'::regclass);


--
-- Name: stylesheets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stylesheets ALTER COLUMN id SET DEFAULT nextval('public.stylesheets_id_seq'::regclass);


--
-- Name: subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions ALTER COLUMN id SET DEFAULT nextval('public.subscriptions_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: themes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.themes ALTER COLUMN id SET DEFAULT nextval('public.themes_id_seq'::regclass);


--
-- Name: tickets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets ALTER COLUMN id SET DEFAULT nextval('public.tickets_id_seq'::regclass);


--
-- Name: trainings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trainings ALTER COLUMN id SET DEFAULT nextval('public.trainings_id_seq'::regclass);


--
-- Name: trainings_availabilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trainings_availabilities ALTER COLUMN id SET DEFAULT nextval('public.trainings_availabilities_id_seq'::regclass);


--
-- Name: trainings_machines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trainings_machines ALTER COLUMN id SET DEFAULT nextval('public.trainings_machines_id_seq'::regclass);


--
-- Name: trainings_pricings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trainings_pricings ALTER COLUMN id SET DEFAULT nextval('public.trainings_pricings_id_seq'::regclass);


--
-- Name: user_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tags ALTER COLUMN id SET DEFAULT nextval('public.user_tags_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: users_credits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_credits ALTER COLUMN id SET DEFAULT nextval('public.users_credits_id_seq'::regclass);


--
-- Name: wallet_transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallet_transactions ALTER COLUMN id SET DEFAULT nextval('public.wallet_transactions_id_seq'::regclass);


--
-- Name: wallets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallets ALTER COLUMN id SET DEFAULT nextval('public.wallets_id_seq'::regclass);


--
-- Name: abuses abuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.abuses
    ADD CONSTRAINT abuses_pkey PRIMARY KEY (id);


--
-- Name: accounting_periods accounting_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting_periods
    ADD CONSTRAINT accounting_periods_pkey PRIMARY KEY (id);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: age_ranges age_ranges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.age_ranges
    ADD CONSTRAINT age_ranges_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: assets assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (id);


--
-- Name: auth_providers auth_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_providers
    ADD CONSTRAINT auth_providers_pkey PRIMARY KEY (id);


--
-- Name: availabilities availabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.availabilities
    ADD CONSTRAINT availabilities_pkey PRIMARY KEY (id);


--
-- Name: availability_tags availability_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.availability_tags
    ADD CONSTRAINT availability_tags_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: components components_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.components
    ADD CONSTRAINT components_pkey PRIMARY KEY (id);


--
-- Name: coupons coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT coupons_pkey PRIMARY KEY (id);


--
-- Name: credits credits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.credits
    ADD CONSTRAINT credits_pkey PRIMARY KEY (id);


--
-- Name: custom_assets custom_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_assets
    ADD CONSTRAINT custom_assets_pkey PRIMARY KEY (id);


--
-- Name: database_providers database_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.database_providers
    ADD CONSTRAINT database_providers_pkey PRIMARY KEY (id);


--
-- Name: event_price_categories event_price_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_price_categories
    ADD CONSTRAINT event_price_categories_pkey PRIMARY KEY (id);


--
-- Name: event_themes event_themes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_themes
    ADD CONSTRAINT event_themes_pkey PRIMARY KEY (id);


--
-- Name: events_event_themes events_event_themes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_event_themes
    ADD CONSTRAINT events_event_themes_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: exports exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports
    ADD CONSTRAINT exports_pkey PRIMARY KEY (id);


--
-- Name: footprint_debugs footprint_debugs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.footprint_debugs
    ADD CONSTRAINT footprint_debugs_pkey PRIMARY KEY (id);


--
-- Name: friendly_id_slugs friendly_id_slugs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friendly_id_slugs
    ADD CONSTRAINT friendly_id_slugs_pkey PRIMARY KEY (id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: history_values history_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history_values
    ADD CONSTRAINT history_values_pkey PRIMARY KEY (id);


--
-- Name: i_calendar_events i_calendar_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.i_calendar_events
    ADD CONSTRAINT i_calendar_events_pkey PRIMARY KEY (id);


--
-- Name: i_calendars i_calendars_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.i_calendars
    ADD CONSTRAINT i_calendars_pkey PRIMARY KEY (id);


--
-- Name: imports imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imports
    ADD CONSTRAINT imports_pkey PRIMARY KEY (id);


--
-- Name: invoice_items invoice_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoice_items
    ADD CONSTRAINT invoice_items_pkey PRIMARY KEY (id);


--
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- Name: invoicing_profiles invoicing_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoicing_profiles
    ADD CONSTRAINT invoicing_profiles_pkey PRIMARY KEY (id);


--
-- Name: licences licences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.licences
    ADD CONSTRAINT licences_pkey PRIMARY KEY (id);


--
-- Name: machines_availabilities machines_availabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machines_availabilities
    ADD CONSTRAINT machines_availabilities_pkey PRIMARY KEY (id);


--
-- Name: machines machines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.machines
    ADD CONSTRAINT machines_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: o_auth2_mappings o_auth2_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.o_auth2_mappings
    ADD CONSTRAINT o_auth2_mappings_pkey PRIMARY KEY (id);


--
-- Name: o_auth2_providers o_auth2_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.o_auth2_providers
    ADD CONSTRAINT o_auth2_providers_pkey PRIMARY KEY (id);


--
-- Name: offer_days offer_days_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offer_days
    ADD CONSTRAINT offer_days_pkey PRIMARY KEY (id);


--
-- Name: open_api_calls_count_tracings open_api_calls_count_tracings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.open_api_calls_count_tracings
    ADD CONSTRAINT open_api_calls_count_tracings_pkey PRIMARY KEY (id);


--
-- Name: open_api_clients open_api_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.open_api_clients
    ADD CONSTRAINT open_api_clients_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: payment_gateway_objects payment_gateway_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_gateway_objects
    ADD CONSTRAINT payment_gateway_objects_pkey PRIMARY KEY (id);


--
-- Name: payment_schedule_items payment_schedule_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_schedule_items
    ADD CONSTRAINT payment_schedule_items_pkey PRIMARY KEY (id);


--
-- Name: payment_schedules payment_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_schedules
    ADD CONSTRAINT payment_schedules_pkey PRIMARY KEY (id);


--
-- Name: plans_availabilities plans_availabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans_availabilities
    ADD CONSTRAINT plans_availabilities_pkey PRIMARY KEY (id);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: price_categories price_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.price_categories
    ADD CONSTRAINT price_categories_pkey PRIMARY KEY (id);


--
-- Name: prices prices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prices
    ADD CONSTRAINT prices_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: project_steps project_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_steps
    ADD CONSTRAINT project_steps_pkey PRIMARY KEY (id);


--
-- Name: project_users project_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_users
    ADD CONSTRAINT project_users_pkey PRIMARY KEY (id);


--
-- Name: projects_components projects_components_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects_components
    ADD CONSTRAINT projects_components_pkey PRIMARY KEY (id);


--
-- Name: projects_machines projects_machines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects_machines
    ADD CONSTRAINT projects_machines_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: projects_spaces projects_spaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects_spaces
    ADD CONSTRAINT projects_spaces_pkey PRIMARY KEY (id);


--
-- Name: projects_themes projects_themes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects_themes
    ADD CONSTRAINT projects_themes_pkey PRIMARY KEY (id);


--
-- Name: reservations reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: slots slots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slots
    ADD CONSTRAINT slots_pkey PRIMARY KEY (id);


--
-- Name: slots_reservations slots_reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slots_reservations
    ADD CONSTRAINT slots_reservations_pkey PRIMARY KEY (id);


--
-- Name: spaces_availabilities spaces_availabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spaces_availabilities
    ADD CONSTRAINT spaces_availabilities_pkey PRIMARY KEY (id);


--
-- Name: spaces spaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spaces
    ADD CONSTRAINT spaces_pkey PRIMARY KEY (id);


--
-- Name: statistic_custom_aggregations statistic_custom_aggregations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_custom_aggregations
    ADD CONSTRAINT statistic_custom_aggregations_pkey PRIMARY KEY (id);


--
-- Name: statistic_fields statistic_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_fields
    ADD CONSTRAINT statistic_fields_pkey PRIMARY KEY (id);


--
-- Name: statistic_graphs statistic_graphs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_graphs
    ADD CONSTRAINT statistic_graphs_pkey PRIMARY KEY (id);


--
-- Name: statistic_indices statistic_indices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_indices
    ADD CONSTRAINT statistic_indices_pkey PRIMARY KEY (id);


--
-- Name: statistic_profile_trainings statistic_profile_trainings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_profile_trainings
    ADD CONSTRAINT statistic_profile_trainings_pkey PRIMARY KEY (id);


--
-- Name: statistic_profiles statistic_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_profiles
    ADD CONSTRAINT statistic_profiles_pkey PRIMARY KEY (id);


--
-- Name: statistic_sub_types statistic_sub_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_sub_types
    ADD CONSTRAINT statistic_sub_types_pkey PRIMARY KEY (id);


--
-- Name: statistic_type_sub_types statistic_type_sub_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_type_sub_types
    ADD CONSTRAINT statistic_type_sub_types_pkey PRIMARY KEY (id);


--
-- Name: statistic_types statistic_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_types
    ADD CONSTRAINT statistic_types_pkey PRIMARY KEY (id);


--
-- Name: stylesheets stylesheets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stylesheets
    ADD CONSTRAINT stylesheets_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: themes themes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.themes
    ADD CONSTRAINT themes_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- Name: trainings_availabilities trainings_availabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trainings_availabilities
    ADD CONSTRAINT trainings_availabilities_pkey PRIMARY KEY (id);


--
-- Name: trainings_machines trainings_machines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trainings_machines
    ADD CONSTRAINT trainings_machines_pkey PRIMARY KEY (id);


--
-- Name: trainings trainings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trainings
    ADD CONSTRAINT trainings_pkey PRIMARY KEY (id);


--
-- Name: trainings_pricings trainings_pricings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trainings_pricings
    ADD CONSTRAINT trainings_pricings_pkey PRIMARY KEY (id);


--
-- Name: user_tags user_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tags
    ADD CONSTRAINT user_tags_pkey PRIMARY KEY (id);


--
-- Name: users_credits users_credits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_credits
    ADD CONSTRAINT users_credits_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: wallet_transactions wallet_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT wallet_transactions_pkey PRIMARY KEY (id);


--
-- Name: wallets wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_pkey PRIMARY KEY (id);


--
-- Name: index_abuses_on_signaled_type_and_signaled_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_abuses_on_signaled_type_and_signaled_id ON public.abuses USING btree (signaled_type, signaled_id);


--
-- Name: index_age_ranges_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_age_ranges_on_slug ON public.age_ranges USING btree (slug);


--
-- Name: index_availability_tags_on_availability_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_availability_tags_on_availability_id ON public.availability_tags USING btree (availability_id);


--
-- Name: index_availability_tags_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_availability_tags_on_tag_id ON public.availability_tags USING btree (tag_id);


--
-- Name: index_categories_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_categories_on_slug ON public.categories USING btree (slug);


--
-- Name: index_credits_on_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_credits_on_plan_id ON public.credits USING btree (plan_id);


--
-- Name: index_event_price_categories_on_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_price_categories_on_event_id ON public.event_price_categories USING btree (event_id);


--
-- Name: index_event_price_categories_on_price_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_event_price_categories_on_price_category_id ON public.event_price_categories USING btree (price_category_id);


--
-- Name: index_event_themes_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_event_themes_on_slug ON public.event_themes USING btree (slug);


--
-- Name: index_events_event_themes_on_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_event_themes_on_event_id ON public.events_event_themes USING btree (event_id);


--
-- Name: index_events_event_themes_on_event_theme_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_event_themes_on_event_theme_id ON public.events_event_themes USING btree (event_theme_id);


--
-- Name: index_events_on_availability_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_availability_id ON public.events USING btree (availability_id);


--
-- Name: index_events_on_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_category_id ON public.events USING btree (category_id);


--
-- Name: index_events_on_recurrence_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_recurrence_id ON public.events USING btree (recurrence_id);


--
-- Name: index_exports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exports_on_user_id ON public.exports USING btree (user_id);


--
-- Name: index_friendly_id_slugs_on_slug_and_sluggable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_friendly_id_slugs_on_slug_and_sluggable_type ON public.friendly_id_slugs USING btree (slug, sluggable_type);


--
-- Name: index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope ON public.friendly_id_slugs USING btree (slug, sluggable_type, scope);


--
-- Name: index_friendly_id_slugs_on_sluggable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_friendly_id_slugs_on_sluggable_id ON public.friendly_id_slugs USING btree (sluggable_id);


--
-- Name: index_friendly_id_slugs_on_sluggable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_friendly_id_slugs_on_sluggable_type ON public.friendly_id_slugs USING btree (sluggable_type);


--
-- Name: index_groups_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_groups_on_slug ON public.groups USING btree (slug);


--
-- Name: index_history_values_on_invoicing_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_history_values_on_invoicing_profile_id ON public.history_values USING btree (invoicing_profile_id);


--
-- Name: index_history_values_on_setting_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_history_values_on_setting_id ON public.history_values USING btree (setting_id);


--
-- Name: index_i_calendar_events_on_i_calendar_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_i_calendar_events_on_i_calendar_id ON public.i_calendar_events USING btree (i_calendar_id);


--
-- Name: index_invoice_items_on_invoice_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invoice_items_on_invoice_id ON public.invoice_items USING btree (invoice_id);


--
-- Name: index_invoices_on_coupon_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invoices_on_coupon_id ON public.invoices USING btree (coupon_id);


--
-- Name: index_invoices_on_invoice_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invoices_on_invoice_id ON public.invoices USING btree (invoice_id);


--
-- Name: index_invoices_on_invoicing_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invoices_on_invoicing_profile_id ON public.invoices USING btree (invoicing_profile_id);


--
-- Name: index_invoices_on_statistic_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invoices_on_statistic_profile_id ON public.invoices USING btree (statistic_profile_id);


--
-- Name: index_invoices_on_wallet_transaction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invoices_on_wallet_transaction_id ON public.invoices USING btree (wallet_transaction_id);


--
-- Name: index_invoicing_profiles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invoicing_profiles_on_user_id ON public.invoicing_profiles USING btree (user_id);


--
-- Name: index_machines_availabilities_on_availability_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_machines_availabilities_on_availability_id ON public.machines_availabilities USING btree (availability_id);


--
-- Name: index_machines_availabilities_on_machine_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_machines_availabilities_on_machine_id ON public.machines_availabilities USING btree (machine_id);


--
-- Name: index_machines_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_machines_on_slug ON public.machines USING btree (slug);


--
-- Name: index_notifications_on_notification_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_notification_type_id ON public.notifications USING btree (notification_type_id);


--
-- Name: index_notifications_on_receiver_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_receiver_id ON public.notifications USING btree (receiver_id);


--
-- Name: index_o_auth2_mappings_on_o_auth2_provider_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_o_auth2_mappings_on_o_auth2_provider_id ON public.o_auth2_mappings USING btree (o_auth2_provider_id);


--
-- Name: index_offer_days_on_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_offer_days_on_subscription_id ON public.offer_days USING btree (subscription_id);


--
-- Name: index_open_api_calls_count_tracings_on_open_api_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_open_api_calls_count_tracings_on_open_api_client_id ON public.open_api_calls_count_tracings USING btree (open_api_client_id);


--
-- Name: index_organizations_on_invoicing_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_organizations_on_invoicing_profile_id ON public.organizations USING btree (invoicing_profile_id);


--
-- Name: index_payment_gateway_objects_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_gateway_objects_on_item_type_and_item_id ON public.payment_gateway_objects USING btree (item_type, item_id);


--
-- Name: index_payment_schedule_items_on_invoice_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_schedule_items_on_invoice_id ON public.payment_schedule_items USING btree (invoice_id);


--
-- Name: index_payment_schedule_items_on_payment_schedule_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_schedule_items_on_payment_schedule_id ON public.payment_schedule_items USING btree (payment_schedule_id);


--
-- Name: index_payment_schedules_on_coupon_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_schedules_on_coupon_id ON public.payment_schedules USING btree (coupon_id);


--
-- Name: index_payment_schedules_on_invoicing_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_schedules_on_invoicing_profile_id ON public.payment_schedules USING btree (invoicing_profile_id);


--
-- Name: index_payment_schedules_on_operator_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_schedules_on_operator_profile_id ON public.payment_schedules USING btree (operator_profile_id);


--
-- Name: index_payment_schedules_on_scheduled_type_and_scheduled_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_schedules_on_scheduled_type_and_scheduled_id ON public.payment_schedules USING btree (scheduled_type, scheduled_id);


--
-- Name: index_payment_schedules_on_statistic_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_schedules_on_statistic_profile_id ON public.payment_schedules USING btree (statistic_profile_id);


--
-- Name: index_payment_schedules_on_wallet_transaction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_payment_schedules_on_wallet_transaction_id ON public.payment_schedules USING btree (wallet_transaction_id);


--
-- Name: index_plans_availabilities_on_availability_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plans_availabilities_on_availability_id ON public.plans_availabilities USING btree (availability_id);


--
-- Name: index_plans_availabilities_on_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plans_availabilities_on_plan_id ON public.plans_availabilities USING btree (plan_id);


--
-- Name: index_plans_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plans_on_group_id ON public.plans USING btree (group_id);


--
-- Name: index_prices_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prices_on_group_id ON public.prices USING btree (group_id);


--
-- Name: index_prices_on_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prices_on_plan_id ON public.prices USING btree (plan_id);


--
-- Name: index_prices_on_priceable_type_and_priceable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_prices_on_priceable_type_and_priceable_id ON public.prices USING btree (priceable_type, priceable_id);


--
-- Name: index_profiles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_profiles_on_user_id ON public.profiles USING btree (user_id);


--
-- Name: index_project_steps_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_steps_on_project_id ON public.project_steps USING btree (project_id);


--
-- Name: index_project_users_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_users_on_project_id ON public.project_users USING btree (project_id);


--
-- Name: index_project_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_users_on_user_id ON public.project_users USING btree (user_id);


--
-- Name: index_projects_components_on_component_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_components_on_component_id ON public.projects_components USING btree (component_id);


--
-- Name: index_projects_components_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_components_on_project_id ON public.projects_components USING btree (project_id);


--
-- Name: index_projects_machines_on_machine_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_machines_on_machine_id ON public.projects_machines USING btree (machine_id);


--
-- Name: index_projects_machines_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_machines_on_project_id ON public.projects_machines USING btree (project_id);


--
-- Name: index_projects_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_projects_on_slug ON public.projects USING btree (slug);


--
-- Name: index_projects_spaces_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_spaces_on_project_id ON public.projects_spaces USING btree (project_id);


--
-- Name: index_projects_spaces_on_space_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_spaces_on_space_id ON public.projects_spaces USING btree (space_id);


--
-- Name: index_projects_themes_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_themes_on_project_id ON public.projects_themes USING btree (project_id);


--
-- Name: index_projects_themes_on_theme_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_projects_themes_on_theme_id ON public.projects_themes USING btree (theme_id);


--
-- Name: index_reservations_on_reservable_type_and_reservable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reservations_on_reservable_type_and_reservable_id ON public.reservations USING btree (reservable_type, reservable_id);


--
-- Name: index_reservations_on_statistic_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reservations_on_statistic_profile_id ON public.reservations USING btree (statistic_profile_id);


--
-- Name: index_roles_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_name ON public.roles USING btree (name);


--
-- Name: index_roles_on_name_and_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_name_and_resource_type_and_resource_id ON public.roles USING btree (name, resource_type, resource_id);


--
-- Name: index_settings_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_settings_on_name ON public.settings USING btree (name);


--
-- Name: index_slots_on_availability_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_slots_on_availability_id ON public.slots USING btree (availability_id);


--
-- Name: index_slots_reservations_on_reservation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_slots_reservations_on_reservation_id ON public.slots_reservations USING btree (reservation_id);


--
-- Name: index_slots_reservations_on_slot_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_slots_reservations_on_slot_id ON public.slots_reservations USING btree (slot_id);


--
-- Name: index_spaces_availabilities_on_availability_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_spaces_availabilities_on_availability_id ON public.spaces_availabilities USING btree (availability_id);


--
-- Name: index_spaces_availabilities_on_space_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_spaces_availabilities_on_space_id ON public.spaces_availabilities USING btree (space_id);


--
-- Name: index_statistic_custom_aggregations_on_statistic_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statistic_custom_aggregations_on_statistic_type_id ON public.statistic_custom_aggregations USING btree (statistic_type_id);


--
-- Name: index_statistic_fields_on_statistic_index_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statistic_fields_on_statistic_index_id ON public.statistic_fields USING btree (statistic_index_id);


--
-- Name: index_statistic_graphs_on_statistic_index_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statistic_graphs_on_statistic_index_id ON public.statistic_graphs USING btree (statistic_index_id);


--
-- Name: index_statistic_profile_trainings_on_statistic_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statistic_profile_trainings_on_statistic_profile_id ON public.statistic_profile_trainings USING btree (statistic_profile_id);


--
-- Name: index_statistic_profile_trainings_on_training_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statistic_profile_trainings_on_training_id ON public.statistic_profile_trainings USING btree (training_id);


--
-- Name: index_statistic_profiles_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statistic_profiles_on_group_id ON public.statistic_profiles USING btree (group_id);


--
-- Name: index_statistic_profiles_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statistic_profiles_on_role_id ON public.statistic_profiles USING btree (role_id);


--
-- Name: index_statistic_profiles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statistic_profiles_on_user_id ON public.statistic_profiles USING btree (user_id);


--
-- Name: index_statistic_type_sub_types_on_statistic_sub_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statistic_type_sub_types_on_statistic_sub_type_id ON public.statistic_type_sub_types USING btree (statistic_sub_type_id);


--
-- Name: index_statistic_type_sub_types_on_statistic_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statistic_type_sub_types_on_statistic_type_id ON public.statistic_type_sub_types USING btree (statistic_type_id);


--
-- Name: index_statistic_types_on_statistic_index_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statistic_types_on_statistic_index_id ON public.statistic_types USING btree (statistic_index_id);


--
-- Name: index_subscriptions_on_plan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_plan_id ON public.subscriptions USING btree (plan_id);


--
-- Name: index_subscriptions_on_statistic_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_subscriptions_on_statistic_profile_id ON public.subscriptions USING btree (statistic_profile_id);


--
-- Name: index_tags_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_name ON public.tags USING btree (name);


--
-- Name: index_tickets_on_event_price_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tickets_on_event_price_category_id ON public.tickets USING btree (event_price_category_id);


--
-- Name: index_tickets_on_reservation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tickets_on_reservation_id ON public.tickets USING btree (reservation_id);


--
-- Name: index_trainings_availabilities_on_availability_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trainings_availabilities_on_availability_id ON public.trainings_availabilities USING btree (availability_id);


--
-- Name: index_trainings_availabilities_on_training_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trainings_availabilities_on_training_id ON public.trainings_availabilities USING btree (training_id);


--
-- Name: index_trainings_machines_on_machine_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trainings_machines_on_machine_id ON public.trainings_machines USING btree (machine_id);


--
-- Name: index_trainings_machines_on_training_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trainings_machines_on_training_id ON public.trainings_machines USING btree (training_id);


--
-- Name: index_trainings_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_trainings_on_slug ON public.trainings USING btree (slug);


--
-- Name: index_trainings_pricings_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trainings_pricings_on_group_id ON public.trainings_pricings USING btree (group_id);


--
-- Name: index_trainings_pricings_on_training_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_trainings_pricings_on_training_id ON public.trainings_pricings USING btree (training_id);


--
-- Name: index_user_tags_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_tags_on_tag_id ON public.user_tags USING btree (tag_id);


--
-- Name: index_user_tags_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_tags_on_user_id ON public.user_tags USING btree (user_id);


--
-- Name: index_users_credits_on_credit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_credits_on_credit_id ON public.users_credits USING btree (credit_id);


--
-- Name: index_users_credits_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_credits_on_user_id ON public.users_credits USING btree (user_id);


--
-- Name: index_users_on_auth_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_auth_token ON public.users USING btree (auth_token);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_group_id ON public.users USING btree (group_id);


--
-- Name: index_users_on_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_provider ON public.users USING btree (provider);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_slug ON public.users USING btree (slug);


--
-- Name: index_users_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_uid ON public.users USING btree (uid);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON public.users USING btree (unlock_token);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_username ON public.users USING btree (username);


--
-- Name: index_users_roles_on_user_id_and_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_roles_on_user_id_and_role_id ON public.users_roles USING btree (user_id, role_id);


--
-- Name: index_wallet_transactions_on_invoicing_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wallet_transactions_on_invoicing_profile_id ON public.wallet_transactions USING btree (invoicing_profile_id);


--
-- Name: index_wallet_transactions_on_transactable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wallet_transactions_on_transactable ON public.wallet_transactions USING btree (transactable_type, transactable_id);


--
-- Name: index_wallet_transactions_on_wallet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wallet_transactions_on_wallet_id ON public.wallet_transactions USING btree (wallet_id);


--
-- Name: index_wallets_on_invoicing_profile_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wallets_on_invoicing_profile_id ON public.wallets USING btree (invoicing_profile_id);


--
-- Name: profiles_lower_unaccent_first_name_trgm_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profiles_lower_unaccent_first_name_trgm_idx ON public.profiles USING gin (lower(public.f_unaccent((first_name)::text)) public.gin_trgm_ops);


--
-- Name: profiles_lower_unaccent_last_name_trgm_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX profiles_lower_unaccent_last_name_trgm_idx ON public.profiles USING gin (lower(public.f_unaccent((last_name)::text)) public.gin_trgm_ops);


--
-- Name: projects_search_vector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX projects_search_vector_idx ON public.projects USING gin (search_vector);


--
-- Name: projects projects_search_content_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER projects_search_content_trigger BEFORE INSERT OR UPDATE ON public.projects FOR EACH ROW EXECUTE PROCEDURE public.fill_search_vector_for_project();


--
-- Name: payment_schedules fk_rails_00308dc223; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_schedules
    ADD CONSTRAINT fk_rails_00308dc223 FOREIGN KEY (wallet_transaction_id) REFERENCES public.wallet_transactions(id);


--
-- Name: o_auth2_mappings fk_rails_0b25d932a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.o_auth2_mappings
    ADD CONSTRAINT fk_rails_0b25d932a6 FOREIGN KEY (o_auth2_provider_id) REFERENCES public.o_auth2_providers(id);


--
-- Name: tickets fk_rails_0efe03a510; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT fk_rails_0efe03a510 FOREIGN KEY (event_price_category_id) REFERENCES public.event_price_categories(id);


--
-- Name: invoicing_profiles fk_rails_122b1ddaf2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoicing_profiles
    ADD CONSTRAINT fk_rails_122b1ddaf2 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: invoices fk_rails_13888eebf0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT fk_rails_13888eebf0 FOREIGN KEY (statistic_profile_id) REFERENCES public.statistic_profiles(id);


--
-- Name: wallet_transactions fk_rails_1548249e6b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT fk_rails_1548249e6b FOREIGN KEY (invoicing_profile_id) REFERENCES public.invoicing_profiles(id);


--
-- Name: statistic_custom_aggregations fk_rails_1742c38664; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_custom_aggregations
    ADD CONSTRAINT fk_rails_1742c38664 FOREIGN KEY (statistic_type_id) REFERENCES public.statistic_types(id);


--
-- Name: project_users fk_rails_1bf16ed5d0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_users
    ADD CONSTRAINT fk_rails_1bf16ed5d0 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: history_values fk_rails_1c79bec847; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history_values
    ADD CONSTRAINT fk_rails_1c79bec847 FOREIGN KEY (setting_id) REFERENCES public.settings(id);


--
-- Name: prices fk_rails_2385efc06e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prices
    ADD CONSTRAINT fk_rails_2385efc06e FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: slots_reservations fk_rails_246639af41; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slots_reservations
    ADD CONSTRAINT fk_rails_246639af41 FOREIGN KEY (reservation_id) REFERENCES public.reservations(id);


--
-- Name: i_calendar_events fk_rails_25e5a14f12; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.i_calendar_events
    ADD CONSTRAINT fk_rails_25e5a14f12 FOREIGN KEY (i_calendar_id) REFERENCES public.i_calendars(id);


--
-- Name: exports fk_rails_26b155474a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports
    ADD CONSTRAINT fk_rails_26b155474a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: payment_schedules fk_rails_27cdd051f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_schedules
    ADD CONSTRAINT fk_rails_27cdd051f7 FOREIGN KEY (statistic_profile_id) REFERENCES public.statistic_profiles(id);


--
-- Name: statistic_profiles fk_rails_2c8874d1a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_profiles
    ADD CONSTRAINT fk_rails_2c8874d1a1 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: invoices fk_rails_2f06166181; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT fk_rails_2f06166181 FOREIGN KEY (wallet_transaction_id) REFERENCES public.wallet_transactions(id);


--
-- Name: open_api_calls_count_tracings fk_rails_31925ce5e5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.open_api_calls_count_tracings
    ADD CONSTRAINT fk_rails_31925ce5e5 FOREIGN KEY (open_api_client_id) REFERENCES public.open_api_clients(id);


--
-- Name: subscriptions fk_rails_358a71f738; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_rails_358a71f738 FOREIGN KEY (statistic_profile_id) REFERENCES public.statistic_profiles(id);


--
-- Name: invoices fk_rails_40d78f8cf6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT fk_rails_40d78f8cf6 FOREIGN KEY (operator_profile_id) REFERENCES public.invoicing_profiles(id);


--
-- Name: projects_spaces fk_rails_43999be339; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects_spaces
    ADD CONSTRAINT fk_rails_43999be339 FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: spaces_availabilities fk_rails_4a1cac85d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spaces_availabilities
    ADD CONSTRAINT fk_rails_4a1cac85d2 FOREIGN KEY (availability_id) REFERENCES public.availabilities(id);


--
-- Name: projects_components fk_rails_4d88badb91; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects_components
    ADD CONSTRAINT fk_rails_4d88badb91 FOREIGN KEY (component_id) REFERENCES public.components(id);


--
-- Name: event_price_categories fk_rails_4dc2c47476; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_price_categories
    ADD CONSTRAINT fk_rails_4dc2c47476 FOREIGN KEY (price_category_id) REFERENCES public.price_categories(id);


--
-- Name: payment_schedule_items fk_rails_4e9d79c566; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_schedule_items
    ADD CONSTRAINT fk_rails_4e9d79c566 FOREIGN KEY (invoice_id) REFERENCES public.invoices(id);


--
-- Name: payment_schedules fk_rails_552bc65163; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_schedules
    ADD CONSTRAINT fk_rails_552bc65163 FOREIGN KEY (coupon_id) REFERENCES public.coupons(id);


--
-- Name: tickets fk_rails_65422fe751; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT fk_rails_65422fe751 FOREIGN KEY (reservation_id) REFERENCES public.reservations(id);


--
-- Name: spaces_availabilities fk_rails_6f123023fd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spaces_availabilities
    ADD CONSTRAINT fk_rails_6f123023fd FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: user_tags fk_rails_7156651ad8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tags
    ADD CONSTRAINT fk_rails_7156651ad8 FOREIGN KEY (tag_id) REFERENCES public.tags(id);


--
-- Name: events_event_themes fk_rails_725b0acd5b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_event_themes
    ADD CONSTRAINT fk_rails_725b0acd5b FOREIGN KEY (event_theme_id) REFERENCES public.event_themes(id);


--
-- Name: wallets fk_rails_7bfc904eec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT fk_rails_7bfc904eec FOREIGN KEY (invoicing_profile_id) REFERENCES public.invoicing_profiles(id);


--
-- Name: statistic_profiles fk_rails_7cf6dfadf2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_profiles
    ADD CONSTRAINT fk_rails_7cf6dfadf2 FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: history_values fk_rails_860e5a38df; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history_values
    ADD CONSTRAINT fk_rails_860e5a38df FOREIGN KEY (invoicing_profile_id) REFERENCES public.invoicing_profiles(id);


--
-- Name: projects_machines fk_rails_88b280c24c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects_machines
    ADD CONSTRAINT fk_rails_88b280c24c FOREIGN KEY (machine_id) REFERENCES public.machines(id);


--
-- Name: payment_schedules fk_rails_8b73dd8d7d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_schedules
    ADD CONSTRAINT fk_rails_8b73dd8d7d FOREIGN KEY (operator_profile_id) REFERENCES public.invoicing_profiles(id);


--
-- Name: availability_tags fk_rails_8cb4e921f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.availability_tags
    ADD CONSTRAINT fk_rails_8cb4e921f7 FOREIGN KEY (availability_id) REFERENCES public.availabilities(id);


--
-- Name: organizations fk_rails_8d4871c330; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT fk_rails_8d4871c330 FOREIGN KEY (invoicing_profile_id) REFERENCES public.invoicing_profiles(id);


--
-- Name: invoices fk_rails_8f2dfb47ee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT fk_rails_8f2dfb47ee FOREIGN KEY (coupon_id) REFERENCES public.coupons(id);


--
-- Name: invoices fk_rails_94eb61be79; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT fk_rails_94eb61be79 FOREIGN KEY (invoicing_profile_id) REFERENCES public.invoicing_profiles(id);


--
-- Name: project_users fk_rails_996d73fecd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_users
    ADD CONSTRAINT fk_rails_996d73fecd FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: prices fk_rails_9f0e94b0c3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prices
    ADD CONSTRAINT fk_rails_9f0e94b0c3 FOREIGN KEY (plan_id) REFERENCES public.plans(id);


--
-- Name: projects_themes fk_rails_9fd58ae797; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects_themes
    ADD CONSTRAINT fk_rails_9fd58ae797 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: projects_themes fk_rails_b021a22658; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects_themes
    ADD CONSTRAINT fk_rails_b021a22658 FOREIGN KEY (theme_id) REFERENCES public.themes(id);


--
-- Name: statistic_profiles fk_rails_bba64e5eb9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_profiles
    ADD CONSTRAINT fk_rails_bba64e5eb9 FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: events_event_themes fk_rails_bd1415f169; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events_event_themes
    ADD CONSTRAINT fk_rails_bd1415f169 FOREIGN KEY (event_id) REFERENCES public.events(id);


--
-- Name: projects_machines fk_rails_c1427daf48; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects_machines
    ADD CONSTRAINT fk_rails_c1427daf48 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: project_steps fk_rails_c6306005c3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_steps
    ADD CONSTRAINT fk_rails_c6306005c3 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: projects_components fk_rails_c80c60ead3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects_components
    ADD CONSTRAINT fk_rails_c80c60ead3 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: statistic_profile_trainings fk_rails_cb689a8d3d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_profile_trainings
    ADD CONSTRAINT fk_rails_cb689a8d3d FOREIGN KEY (statistic_profile_id) REFERENCES public.statistic_profiles(id);


--
-- Name: accounting_periods fk_rails_cc9abff81f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounting_periods
    ADD CONSTRAINT fk_rails_cc9abff81f FOREIGN KEY (closed_by) REFERENCES public.users(id);


--
-- Name: wallet_transactions fk_rails_d07bc24ce3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT fk_rails_d07bc24ce3 FOREIGN KEY (wallet_id) REFERENCES public.wallets(id);


--
-- Name: availability_tags fk_rails_d262715d11; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.availability_tags
    ADD CONSTRAINT fk_rails_d262715d11 FOREIGN KEY (tag_id) REFERENCES public.tags(id);


--
-- Name: payment_schedules fk_rails_d345f9b22a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_schedules
    ADD CONSTRAINT fk_rails_d345f9b22a FOREIGN KEY (invoicing_profile_id) REFERENCES public.invoicing_profiles(id);


--
-- Name: slots_reservations fk_rails_d4ced1b26d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slots_reservations
    ADD CONSTRAINT fk_rails_d4ced1b26d FOREIGN KEY (slot_id) REFERENCES public.slots(id);


--
-- Name: payment_schedule_items fk_rails_d6030dd0e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_schedule_items
    ADD CONSTRAINT fk_rails_d6030dd0e7 FOREIGN KEY (payment_schedule_id) REFERENCES public.payment_schedules(id);


--
-- Name: event_price_categories fk_rails_dcd2787d07; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_price_categories
    ADD CONSTRAINT fk_rails_dcd2787d07 FOREIGN KEY (event_id) REFERENCES public.events(id);


--
-- Name: reservations fk_rails_e409fe73aa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT fk_rails_e409fe73aa FOREIGN KEY (statistic_profile_id) REFERENCES public.statistic_profiles(id);


--
-- Name: statistic_profile_trainings fk_rails_e759406c68; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statistic_profile_trainings
    ADD CONSTRAINT fk_rails_e759406c68 FOREIGN KEY (training_id) REFERENCES public.trainings(id);


--
-- Name: projects fk_rails_e812590204; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_rails_e812590204 FOREIGN KEY (author_statistic_profile_id) REFERENCES public.statistic_profiles(id);


--
-- Name: user_tags fk_rails_ea0382482a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tags
    ADD CONSTRAINT fk_rails_ea0382482a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: projects_spaces fk_rails_f2103efed7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects_spaces
    ADD CONSTRAINT fk_rails_f2103efed7 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: events fk_rails_fd5598a81d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT fk_rails_fd5598a81d FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20140409083104'),
('20140409083610'),
('20140409153915'),
('20140410101026'),
('20140410140516'),
('20140410162151'),
('20140411152729'),
('20140414141134'),
('20140415104151'),
('20140415123625'),
('20140416130838'),
('20140422085949'),
('20140422090412'),
('20140513152025'),
('20140516083543'),
('20140516083909'),
('20140516093335'),
('20140522115617'),
('20140522175539'),
('20140522175714'),
('20140522180032'),
('20140522180930'),
('20140522181011'),
('20140522181148'),
('20140523083230'),
('20140526144327'),
('20140527092045'),
('20140528134944'),
('20140528140257'),
('20140529145140'),
('20140603084413'),
('20140603085817'),
('20140603164215'),
('20140604094514'),
('20140604113611'),
('20140604113919'),
('20140604132045'),
('20140605125131'),
('20140605142133'),
('20140605151442'),
('20140609092700'),
('20140609092827'),
('20140610153123'),
('20140610170446'),
('20140613150651'),
('20140620131525'),
('20140622121724'),
('20140622122944'),
('20140622145648'),
('20140623023557'),
('20140624123359'),
('20140624123814'),
('20140624124338'),
('20140703100457'),
('20140703231208'),
('20140703233420'),
('20140703233942'),
('20140703235739'),
('20140710144142'),
('20140710144427'),
('20140710144610'),
('20140711084809'),
('20140715095503'),
('20140717143735'),
('20140722162046'),
('20140722162309'),
('20140723075942'),
('20140723171547'),
('20140723172610'),
('20140724125605'),
('20140724131808'),
('20140724132655'),
('20140728110430'),
('20141002111736'),
('20141110131407'),
('20141215142044'),
('20141215153643'),
('20141217141648'),
('20141217172843'),
('20150107103903'),
('20150108082541'),
('20150112160349'),
('20150112160405'),
('20150112160425'),
('20150113112757'),
('20150114111132'),
('20150114111243'),
('20150114141926'),
('20150114142032'),
('20150115143750'),
('20150119082931'),
('20150119092557'),
('20150119093811'),
('20150119160758'),
('20150119161004'),
('20150127101521'),
('20150127155141'),
('20150127161235'),
('20150127172510'),
('20150128132219'),
('20150218154032'),
('20150428075148'),
('20150428091057'),
('20150506090921'),
('20150507075506'),
('20150507075620'),
('20150512123546'),
('20150520132030'),
('20150526130729'),
('20150527153312'),
('20150529113555'),
('20150601125944'),
('20150603104502'),
('20150603104658'),
('20150604081757'),
('20150604131525'),
('20150608142234'),
('20150609094336'),
('20150615135539'),
('20150617085623'),
('20150701090642'),
('20150702150754'),
('20150702151009'),
('20150706102547'),
('20150707135343'),
('20150713090542'),
('20150713151115'),
('20150715135751'),
('20150915144448'),
('20150915144939'),
('20150915152943'),
('20150916091131'),
('20150916093159'),
('20150921135557'),
('20150921135817'),
('20150922095921'),
('20150922100528'),
('20150924093917'),
('20150924094138'),
('20150924094427'),
('20150924141714'),
('20151005133841'),
('20151008152219'),
('20151105125623'),
('20151210113548'),
('20160119131623'),
('20160504085703'),
('20160504085905'),
('20160516090121'),
('20160516124056'),
('20160526095550'),
('20160526102307'),
('20160602075531'),
('20160613093842'),
('20160628092931'),
('20160628124538'),
('20160628131408'),
('20160628134211'),
('20160628134303'),
('20160629091649'),
('20160630083438'),
('20160630083556'),
('20160630083759'),
('20160630100137'),
('20160630140204'),
('20160704095606'),
('20160704165139'),
('20160714095018'),
('20160718165434'),
('20160720124355'),
('20160725131756'),
('20160725131950'),
('20160725135112'),
('20160726081931'),
('20160726111509'),
('20160726131152'),
('20160726144257'),
('20160728095026'),
('20160801145502'),
('20160801153454'),
('20160803085201'),
('20160803104701'),
('20160804073558'),
('20160808113850'),
('20160808113930'),
('20160824080717'),
('20160824084111'),
('20160825141326'),
('20160830154719'),
('20160831084443'),
('20160831084519'),
('20160905141858'),
('20160905142700'),
('20160906094739'),
('20160906094847'),
('20160915105234'),
('20161123104604'),
('20170109085345'),
('20170213100744'),
('20170213101541'),
('20170213103438'),
('20170213142543'),
('20170227104736'),
('20170227104934'),
('20170227113718'),
('20170227114634'),
('20170906100906'),
('20171004135605'),
('20171005141522'),
('20171010143708'),
('20171011100640'),
('20171011125217'),
('20181210105917'),
('20181217103256'),
('20181217103441'),
('20181217110454'),
('20190107103632'),
('20190107111749'),
('20190110150532'),
('20190211124135'),
('20190211124726'),
('20190225101256'),
('20190225102847'),
('20190227143153'),
('20190314095931'),
('20190320091148'),
('20190521122429'),
('20190521123642'),
('20190521124609'),
('20190521151142'),
('20190522115230'),
('20190523123916'),
('20190523140823'),
('20190528140012'),
('20190604064929'),
('20190604065348'),
('20190604070903'),
('20190604075717'),
('20190605141322'),
('20190606074050'),
('20190606074801'),
('20190730085826'),
('20190910131825'),
('20190910141336'),
('20190917123631'),
('20190924140726'),
('20191113103352'),
('20191127153729'),
('20191202135507'),
('20200127111404'),
('20200206132857'),
('20200218092221'),
('20200408101654'),
('20200415141809'),
('20200511075933'),
('20200622135401'),
('20200623134900'),
('20200623141305'),
('20200629123011'),
('20200721162939'),
('20201027092149'),
('20201027100746'),
('20201027101809'),
('20201112092002'),
('20210416073410'),
('20210416083610');


