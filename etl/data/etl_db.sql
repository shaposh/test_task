--
-- PostgreSQL database dump
--

-- Dumped from database version 14.8 (Ubuntu 14.8-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.2

-- Started on 2023-07-02 14:48:51

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
-- TOC entry 3360 (class 1262 OID 16384)
-- Name: etl; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE etl WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'ru_RU.UTF-8';


ALTER DATABASE etl OWNER TO postgres;

\connect etl

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
-- TOC entry 223 (class 1255 OID 16392)
-- Name: gen_uuid(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.gen_uuid() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  if (new.id is null) then
  	new.id = gen_random_uuid();
  end if;
  new.verdate = current_timestamp;
  new.isvalid = (new.dosage_number = new.package_dosage * new.package_number);
  return (NEW);
END;
$$;


ALTER FUNCTION public.gen_uuid() OWNER TO postgres;

--
-- TOC entry 222 (class 1255 OID 16524)
-- Name: overdue_clear(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.overdue_clear() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM public.overdue;
END;
$$;


ALTER FUNCTION public.overdue_clear() OWNER TO postgres;

--
-- TOC entry 221 (class 1255 OID 16395)
-- Name: overdue_import(character varying, character varying, character varying, character varying, character varying, character varying, character varying, integer, integer, integer, date, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.overdue_import(IN i_subject character varying, IN i_mo character varying, IN i_inn character varying, IN i_status character varying, IN i_outtype character varying, IN i_gtin character varying, IN i_ser character varying, IN i_package_dosage integer, IN i_package_number integer, IN i_dosage_number integer, IN i_expdate date, IN i_overdays integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO public.overdue (  subject,   mo,   inn,   status,   outtype,   gtin,   ser,   package_dosage,   package_number,   dosage_number,   expdate,   overdays)
       VALUES                (i_subject, i_mo, i_inn, i_status, i_outtype, i_gtin, i_ser, i_package_dosage, i_package_number, i_dosage_number, i_expdate, i_overdays)
  ON CONFLICT (inn,gtin,ser,outtype)
    DO UPDATE
          SET subject = i_subject
            , mo = i_mo
            , inn = i_inn
            , status = i_status
            , outtype = i_outtype
            , gtin = i_gtin
            , ser = i_ser
            , package_dosage = i_package_dosage
            , package_number = i_package_number
            , dosage_number = i_dosage_number
            , expdate = i_expdate
            , overdays = i_overdays;
END;
$$;


ALTER PROCEDURE public.overdue_import(IN i_subject character varying, IN i_mo character varying, IN i_inn character varying, IN i_status character varying, IN i_outtype character varying, IN i_gtin character varying, IN i_ser character varying, IN i_package_dosage integer, IN i_package_number integer, IN i_dosage_number integer, IN i_expdate date, IN i_overdays integer) OWNER TO postgres;

--
-- TOC entry 224 (class 1255 OID 16543)
-- Name: overdue_report(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.overdue_report(i_mode character varying) RETURNS TABLE(subject character varying, mo character varying, gtin character varying, ser character varying, dosage_count integer, overdays numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
    overdays_now numeric;
    nowMode boolean;
BEGIN
  i_mode = coalesce(i_mode, '');
  i_mode = trim(i_mode);
  i_mode = upper(i_mode);
  nowMode = POSITION('NOW' in i_mode) > 0;
  i_mode = REPLACE(i_mode, '_NOW', '');

  if (i_mode = '') then i_mode = 'SUB'; end if;
  
  if (i_mode = 'ALL') then i_mode = 'SUB'; end if;

  if (i_mode = 'SUB') then
   mo   = '{ВСЕ}';
   gtin = '{ВСЕ}';
   ser  = '{ВСЕ}';
   FOR subject
      , dosage_count
      , overdays
      , overdays_now
     IN SELECT T.subject, sum(T.dosage_number), avg(T.overdays), avg(current_date - T.expdate) FROM overdue T GROUP BY 1 ORDER BY 1
  	    LOOP
 		  if (nowMode = true) then overdays = overdays_now; end if;		       
          overdays = round(overdays, 1);
     	  RETURN NEXT;
  	    END LOOP;
  end if;

  if (i_mode = 'MO') then
   gtin = '{ВСЕ}';
   ser = '{ВСЕ}';
   FOR subject, mo, dosage_count, overdays, overdays_now
     IN SELECT T.subject, T.MO, sum(T.dosage_number), avg(T.overdays), avg(current_date - T.expdate) FROM overdue T GROUP BY 1,2 ORDER BY 1,2
  	    LOOP
 		  if (nowMode = true) then overdays = overdays_now; end if;		       
          overdays = round(overdays, 1);
     	  RETURN NEXT;
  	    END LOOP;
  end if;

  if (i_mode = 'GTIN') then
    ser = '{ВСЕ}';
    FOR subject, mo, gtin, dosage_count, overdays, overdays_now
     IN SELECT T.subject, T.MO, T.gtin, sum(T.dosage_number), avg(T.overdays), avg(current_date - T.expdate) FROM overdue T GROUP BY 1, 2, 3 ORDER BY 1, 2, 3
  	    LOOP
 		  if (nowMode = true) then overdays = overdays_now; end if;		       
          overdays = round(overdays, 1);
     	  RETURN NEXT;
  	    END LOOP;
  end if;

  if (i_mode = 'SER') then
    FOR subject, mo, gtin, ser, dosage_count, overdays, overdays_now
     IN SELECT T.subject, T.MO, T.gtin, T.ser, sum(T.dosage_number), avg(T.overdays), avg(current_date - T.expdate) FROM overdue T GROUP BY 1, 2, 3, 4 ORDER BY  1, 2, 3, 4
  	    LOOP
 		  if (nowMode = true) then overdays = overdays_now; end if;		       
          overdays = round(overdays, 1);
     	  RETURN NEXT;
  	    END LOOP;
  end if;





  
END;
$$;


ALTER FUNCTION public.overdue_report(i_mode character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 209 (class 1259 OID 16385)
-- Name: overdue; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.overdue (
    id uuid NOT NULL,
    subject character varying(255),
    mo character varying(1000),
    inn character varying(12),
    status character varying(255),
    outtype character varying(40),
    gtin character varying(14),
    ser character varying(40),
    package_dosage integer,
    package_number integer,
    dosage_number integer,
    expdate date,
    overdays integer,
    verdate timestamp(0) without time zone NOT NULL,
    isvalid boolean
);
ALTER TABLE ONLY public.overdue ALTER COLUMN id SET STATISTICS 0;


ALTER TABLE public.overdue OWNER TO postgres;

--
-- TOC entry 3214 (class 2606 OID 16391)
-- Name: overdue overdue_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.overdue
    ADD CONSTRAINT overdue_pkey PRIMARY KEY (id);


--
-- TOC entry 3212 (class 1259 OID 16420)
-- Name: overdue_idx_inn_gtin_ser_outtype; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX overdue_idx_inn_gtin_ser_outtype ON public.overdue USING btree (inn, gtin, ser, outtype);


--
-- TOC entry 3215 (class 2620 OID 16396)
-- Name: overdue overdue$version; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "overdue$version" BEFORE INSERT OR UPDATE ON public.overdue FOR EACH ROW EXECUTE FUNCTION public.gen_uuid();


-- Completed on 2023-07-02 14:48:51

--
-- PostgreSQL database dump complete
--

