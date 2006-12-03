--
-- PostgreSQL database dump
--

SET client_encoding = 'SQL_ASCII';
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pgbuildfarm
--

COMMENT ON SCHEMA public IS 'Standard public schema';


SET search_path = public, pg_catalog;

--
-- Name: plperl_call_handler(); Type: FUNCTION; Schema: public; Owner: pgbuildfarm
--

CREATE FUNCTION plperl_call_handler() RETURNS language_handler
    AS '$libdir/plperl', 'plperl_call_handler'
    LANGUAGE c;


ALTER FUNCTION public.plperl_call_handler() OWNER TO pgbuildfarm;

--
-- Name: plperl; Type: PROCEDURAL LANGUAGE; Schema: public; Owner: 
--

CREATE TRUSTED PROCEDURAL LANGUAGE plperl HANDLER plperl_call_handler;


--
-- Name: plperlu; Type: PROCEDURAL LANGUAGE; Schema: public; Owner: 
--

CREATE PROCEDURAL LANGUAGE plperlu HANDLER plperl_call_handler;


--
-- Name: plpgsql_call_handler(); Type: FUNCTION; Schema: public; Owner: pgbuildfarm
--

CREATE FUNCTION plpgsql_call_handler() RETURNS language_handler
    AS '$libdir/plpgsql', 'plpgsql_call_handler'
    LANGUAGE c;


ALTER FUNCTION public.plpgsql_call_handler() OWNER TO pgbuildfarm;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: public; Owner: 
--

CREATE TRUSTED PROCEDURAL LANGUAGE plpgsql HANDLER plpgsql_call_handler;


--
-- Name: pending; Type: TYPE; Schema: public; Owner: pgbuildfarm
--

CREATE TYPE pending AS (
	name text,
	operating_system text,
	os_version text,
	compiler text,
	compiler_version text,
	architecture text,
	owner_email text
);


ALTER TYPE public.pending OWNER TO pgbuildfarm;

--
-- Name: pending2; Type: TYPE; Schema: public; Owner: pgbuildfarm
--

CREATE TYPE pending2 AS (
	name text,
	operating_system text,
	os_version text,
	compiler text,
	compiler_version text,
	architecture text,
	owner_email text,
	"owner" text,
	status_ts timestamp without time zone
);


ALTER TYPE public.pending2 OWNER TO pgbuildfarm;

--
-- Name: approve(text, text); Type: FUNCTION; Schema: public; Owner: pgbuildfarm
--

CREATE FUNCTION approve(text, text) RETURNS void
    AS $_$update buildsystems set name = $2, status ='approved' where name = $1 and status = 'pending'$_$
    LANGUAGE sql;


ALTER FUNCTION public.approve(text, text) OWNER TO pgbuildfarm;

--
-- Name: approve2(text, text); Type: FUNCTION; Schema: public; Owner: pgbuildfarm
--

CREATE FUNCTION approve2(text, text) RETURNS text
    AS $_$ update buildsystems set name = $2, status = 'approved' where name = $1 and status = 'pending'; select owner_email || ':' || name || ':' || secret from buildsystems where name = $2;$_$
    LANGUAGE sql;


ALTER FUNCTION public.approve2(text, text) OWNER TO pgbuildfarm;

--
-- Name: pending(); Type: FUNCTION; Schema: public; Owner: pgbuildfarm
--

CREATE FUNCTION pending() RETURNS SETOF pending2
    AS $$select name,operating_system,os_version,compiler,compiler_version,architecture,owner_email, sys_owner, status_ts from buildsystems where status = 'pending' order by status_ts $$
    LANGUAGE sql;


ALTER FUNCTION public.pending() OWNER TO pgbuildfarm;

--
-- Name: prevstat(text, text, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: pgbuildfarm
--

CREATE FUNCTION prevstat(text, text, timestamp without time zone) RETURNS text
    AS $_$
   select coalesce((select distinct on (snapshot) stage
                  from build_status
                  where sysname = $1 and branch = $2 and snapshot < $3
                  order by snapshot desc
                  limit 1), 'NEW') as prev_status
$_$
    LANGUAGE sql;


ALTER FUNCTION public.prevstat(text, text, timestamp without time zone) OWNER TO pgbuildfarm;

SET default_tablespace = '';

SET default_with_oids = true;

--
-- Name: alerts; Type: TABLE; Schema: public; Owner: pgbuildfarm; Tablespace: 
--

CREATE TABLE alerts (
    sysname text NOT NULL,
    branch text NOT NULL,
    first_alert timestamp without time zone,
    last_notification timestamp without time zone
);


ALTER TABLE public.alerts OWNER TO pgbuildfarm;

--
-- Name: build_status; Type: TABLE; Schema: public; Owner: pgbuildfarm; Tablespace: 
--

CREATE TABLE build_status (
    sysname text NOT NULL,
    snapshot timestamp without time zone NOT NULL,
    status integer,
    stage text,
    log text,
    conf_sum text,
    branch text,
    changed_this_run text,
    changed_since_success text,
    log_archive bytea,
    log_archive_filenames text[],
    build_flags text[],
    report_time timestamp with time zone DEFAULT ('now'::text)::timestamp(6) with time zone
);


ALTER TABLE public.build_status OWNER TO pgbuildfarm;

--
-- Name: build_status_export; Type: VIEW; Schema: public; Owner: pgbuildfarm
--

CREATE VIEW build_status_export AS
    SELECT build_status.sysname AS name, build_status.snapshot, build_status.stage, build_status.branch, build_status.build_flags FROM build_status;


ALTER TABLE public.build_status_export OWNER TO pgbuildfarm;

--
-- Name: build_status_log; Type: TABLE; Schema: public; Owner: pgbuildfarm; Tablespace: 
--

CREATE TABLE build_status_log (
    sysname text NOT NULL,
    snapshot timestamp without time zone NOT NULL,
    branch text NOT NULL,
    log_stage text NOT NULL,
    log_text text,
    stage_duration interval
);


ALTER TABLE public.build_status_log OWNER TO pgbuildfarm;

--
-- Name: buildsystems; Type: TABLE; Schema: public; Owner: pgbuildfarm; Tablespace: 
--

CREATE TABLE buildsystems (
    name text NOT NULL,
    secret text NOT NULL,
    operating_system text NOT NULL,
    os_version text NOT NULL,
    compiler text NOT NULL,
    compiler_version text NOT NULL,
    architecture text NOT NULL,
    status text NOT NULL,
    sys_owner text NOT NULL,
    owner_email text NOT NULL,
    status_ts timestamp without time zone DEFAULT (('now'::text)::timestamp(6) with time zone)::timestamp without time zone
);


ALTER TABLE public.buildsystems OWNER TO pgbuildfarm;

--
-- Name: buildsystems_export; Type: VIEW; Schema: public; Owner: pgbuildfarm
--

CREATE VIEW buildsystems_export AS
    SELECT buildsystems.name, buildsystems.operating_system, buildsystems.os_version, buildsystems.compiler, buildsystems.compiler_version, buildsystems.architecture FROM buildsystems WHERE (buildsystems.status = 'approved'::text);


ALTER TABLE public.buildsystems_export OWNER TO pgbuildfarm;

--
-- Name: list_subscriptions; Type: TABLE; Schema: public; Owner: pgbuildfarm; Tablespace: 
--

CREATE TABLE list_subscriptions (
    addr text
);


ALTER TABLE public.list_subscriptions OWNER TO pgbuildfarm;

--
-- Name: penguin_save; Type: TABLE; Schema: public; Owner: pgbuildfarm; Tablespace: 
--

CREATE TABLE penguin_save (
    branch text,
    snapshot timestamp without time zone,
    stage text
);


ALTER TABLE public.penguin_save OWNER TO pgbuildfarm;

--
-- Name: personality; Type: TABLE; Schema: public; Owner: pgbuildfarm; Tablespace: 
--

CREATE TABLE personality (
    name text NOT NULL,
    os_version text NOT NULL,
    compiler_version text NOT NULL,
    effective_date timestamp with time zone DEFAULT ('now'::text)::timestamp(6) with time zone NOT NULL
);


ALTER TABLE public.personality OWNER TO pgbuildfarm;

--
-- Name: alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: pgbuildfarm; Tablespace: 
--

ALTER TABLE ONLY alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (sysname, branch);


ALTER INDEX public.alerts_pkey OWNER TO pgbuildfarm;

--
-- Name: build_status_log_pkey; Type: CONSTRAINT; Schema: public; Owner: pgbuildfarm; Tablespace: 
--

ALTER TABLE ONLY build_status_log
    ADD CONSTRAINT build_status_log_pkey PRIMARY KEY (sysname, snapshot, log_stage);


ALTER INDEX public.build_status_log_pkey OWNER TO pgbuildfarm;

--
-- Name: build_status_pkey; Type: CONSTRAINT; Schema: public; Owner: pgbuildfarm; Tablespace: 
--

ALTER TABLE ONLY build_status
    ADD CONSTRAINT build_status_pkey PRIMARY KEY (sysname, snapshot);


ALTER INDEX public.build_status_pkey OWNER TO pgbuildfarm;

--
-- Name: buildsystems_pkey; Type: CONSTRAINT; Schema: public; Owner: pgbuildfarm; Tablespace: 
--

ALTER TABLE ONLY buildsystems
    ADD CONSTRAINT buildsystems_pkey PRIMARY KEY (name);


ALTER INDEX public.buildsystems_pkey OWNER TO pgbuildfarm;

--
-- Name: personality_pkey; Type: CONSTRAINT; Schema: public; Owner: pgbuildfarm; Tablespace: 
--

ALTER TABLE ONLY personality
    ADD CONSTRAINT personality_pkey PRIMARY KEY (name, effective_date);


ALTER INDEX public.personality_pkey OWNER TO pgbuildfarm;

--
-- Name: bs_branch_snapshot_idx; Type: INDEX; Schema: public; Owner: pgbuildfarm; Tablespace: 
--

CREATE INDEX bs_branch_snapshot_idx ON build_status USING btree (branch, snapshot);


ALTER INDEX public.bs_branch_snapshot_idx OWNER TO pgbuildfarm;

--
-- Name: bs_status_idx; Type: INDEX; Schema: public; Owner: pgbuildfarm; Tablespace: 
--

CREATE INDEX bs_status_idx ON buildsystems USING btree (status);


ALTER INDEX public.bs_status_idx OWNER TO pgbuildfarm;

--
-- Name: bs_sysname_branch_idx; Type: INDEX; Schema: public; Owner: pgbuildfarm; Tablespace: 
--

CREATE INDEX bs_sysname_branch_idx ON build_status USING btree (sysname, branch);


ALTER INDEX public.bs_sysname_branch_idx OWNER TO pgbuildfarm;

--
-- Name: bs_sysname_branch_report_idx; Type: INDEX; Schema: public; Owner: pgbuildfarm; Tablespace: 
--

CREATE INDEX bs_sysname_branch_report_idx ON build_status USING btree (sysname, branch, report_time);


ALTER INDEX public.bs_sysname_branch_report_idx OWNER TO pgbuildfarm;

--
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: pgbuildfarm
--

ALTER TABLE ONLY personality
    ADD CONSTRAINT "$1" FOREIGN KEY (name) REFERENCES buildsystems(name) ON DELETE CASCADE;


--
-- Name: bs_fk; Type: FK CONSTRAINT; Schema: public; Owner: pgbuildfarm
--

ALTER TABLE ONLY build_status
    ADD CONSTRAINT bs_fk FOREIGN KEY (sysname) REFERENCES buildsystems(name) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: build_status_log_sysname_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgbuildfarm
--

ALTER TABLE ONLY build_status_log
    ADD CONSTRAINT build_status_log_sysname_fkey FOREIGN KEY (sysname, snapshot) REFERENCES build_status(sysname, snapshot) ON DELETE CASCADE;


--
-- Name: public; Type: ACL; Schema: -; Owner: pgbuildfarm
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM pgbuildfarm;
GRANT ALL ON SCHEMA public TO pgbuildfarm;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: build_status; Type: ACL; Schema: public; Owner: pgbuildfarm
--

REVOKE ALL ON TABLE build_status FROM PUBLIC;
REVOKE ALL ON TABLE build_status FROM pgbuildfarm;
GRANT ALL ON TABLE build_status TO pgbuildfarm;
GRANT INSERT,SELECT ON TABLE build_status TO pgbfweb;
GRANT SELECT ON TABLE build_status TO rssfeed;


--
-- Name: build_status_log; Type: ACL; Schema: public; Owner: pgbuildfarm
--

REVOKE ALL ON TABLE build_status_log FROM PUBLIC;
REVOKE ALL ON TABLE build_status_log FROM pgbuildfarm;
GRANT ALL ON TABLE build_status_log TO pgbuildfarm;
GRANT INSERT,SELECT,UPDATE,DELETE ON TABLE build_status_log TO pgbfweb;
GRANT SELECT ON TABLE build_status_log TO rssfeed;


--
-- Name: buildsystems; Type: ACL; Schema: public; Owner: pgbuildfarm
--

REVOKE ALL ON TABLE buildsystems FROM PUBLIC;
REVOKE ALL ON TABLE buildsystems FROM pgbuildfarm;
GRANT ALL ON TABLE buildsystems TO pgbuildfarm;
GRANT INSERT,SELECT ON TABLE buildsystems TO pgbfweb;
GRANT SELECT ON TABLE buildsystems TO rssfeed;


--
-- Name: personality; Type: ACL; Schema: public; Owner: pgbuildfarm
--

REVOKE ALL ON TABLE personality FROM PUBLIC;
REVOKE ALL ON TABLE personality FROM pgbuildfarm;
GRANT ALL ON TABLE personality TO pgbuildfarm;
GRANT INSERT,SELECT ON TABLE personality TO pgbfweb;
GRANT SELECT ON TABLE personality TO rssfeed;


--
-- PostgreSQL database dump complete
--

