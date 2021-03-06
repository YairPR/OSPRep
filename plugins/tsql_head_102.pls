  -- Get and print an SQL statement
  PROCEDURE print_tsql(id IN VARCHAR2) IS
    stmt VARCHAR2(16200);
    CURSOR C_GetSQL (sqlid IN VARCHAR2) IS
      SELECT replace(replace(sql_text,'<','&lt;'),'>','&gt;') AS sql_text
        FROM stats$sqltext WHERE sql_id=sqlid
       ORDER BY piece;
    PROCEDURE hlite(stmt IN OUT VARCHAR2) IS
      CURSOR C_KWords IS
        SELECT keyword
          FROM v$reserved_words
         WHERE length>1;
      BEGIN
        FOR kw IN C_KWords LOOP
          stmt := regexp_replace(stmt,'(^|\s)('||kw.keyword||')(\s)','\1<SPAN CLASS="keyword">\2</SPAN>\3',1,0,'i');
        END LOOP;
        stmt := replace(replace(stmt,CHR(10),'<BR>'),CHR(13),'<BR>');
      EXCEPTION
        WHEN OTHERS THEN NULL;
      END;
    BEGIN
      stmt := '';
      FOR R_Statement IN C_GetSQL(id) LOOP
        stmt := stmt || R_Statement.sql_text;
        IF LENGTH(stmt)>SQL_MAXLEN THEN
          hlite(stmt);
          print(stmt);
          RETURN;
          stmt := '';
        END IF;
      END LOOP;
      hlite(stmt);
      print(stmt);
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;

  -- Get and print the Execution Plan
  PROCEDURE get_plan (sqlid IN VARCHAR2) IS
    HASHID NUMBER; CI NUMBER; SI NUMBER; OSIZE VARCHAR2(50); IND VARCHAR2(255);
    CW NUMBER; TDI VARCHAR2(20);
    CURSOR C_PGet (hash_val IN VARCHAR2) IS
      SELECT operation,options,object_owner,object_name,optimizer,cost,
             NVL(TO_CHAR(cost,'999,999,990'),'&nbsp;') vcost,
             bytes,cpu_cost,io_cost,depth
        FROM stats$sql_plan,
             ( SELECT MAX(snap_id) maxid FROM stats$sql_plan
                WHERE snap_id BETWEEN BID AND EID
                  AND plan_hash_value = hash_val ) id
       WHERE plan_hash_value = hash_val
       ORDER BY id;
    BEGIN
      SELECT MAX(snap_id) INTO SI
        FROM ( SELECT plan_hash_value,snap_id
                 FROM stats$sql_plan_usage
                WHERE sql_id = sqlid
                  AND snap_id BETWEEN BID AND EID );
      SELECT MAX(plan_hash_value) INTO HASHID
        FROM ( SELECT plan_hash_value,snap_id
                 FROM stats$sql_plan_usage
                WHERE sql_id = sqlid
                  AND snap_id=SI );
      IF HASHID > 0 THEN
      IND := 'SELECT COUNT(snap_id) FROM stats$sql_plan'||
             ' WHERE plan_hash_value = :HASHID'||
             '   AND rownum = 1'||
             '   AND object_owner NOT IN ('||EXCLUDE_OWNERS||')';
      EXECUTE IMMEDIATE IND INTO CI USING HASHID;
      ELSE CI := 0;
      END IF;
      IF CI > 0
      THEN
        CW := 20;
        print('<TR><TD>&nbsp;</TD><TD COLSPAN="9">');
        print(TABLE_OPEN||'<TR><TH CLASS="th_sub2">Operation</TH><TH CLASS="th_sub2">'||
              'Object</TH><TH CLASS="th_sub2">');
        print('Optimizer</TH><TH CLASS="th_sub2">Cost</TH><TH CLASS="th_sub2">'||
              'CPUCost</TH><TH CLASS="th_sub2">IOCost</TH><TH CLASS="th_sub2">'||
              'Size</TH></TR>');
        FOR rplan IN C_PGet(HASHID) LOOP
          IF NVL(rplan.bytes,0) < 1024
          THEN
            OSIZE := TO_CHAR(rplan.bytes,'9,990');
            IF NVL(OSIZE,'X') = 'X'
            THEN
              OSIZE := '&nbsp;';
            ELSE
              OSIZE := OSIZE||' b';
            END IF;
          ELSE
            OSIZE := format_fsize(rplan.bytes,'990');
          END IF;
          IND := '';
          FOR CI IN 1..rplan.depth LOOP
            IND := IND||'. ';
          END LOOP;
          SI := 11*(LENGTH(rplan.operation) + LENGTH(rplan.options) + 2*rplan.depth)/9;
          CI := 4*(LENGTH(TRIM(OSIZE))+2)/10 +0.5;
          IF SI > CW THEN CW := SI; END IF;
          IF rplan.operation||' '||rplan.options = 'TABLE ACCESS FULL' THEN
            IF rplan.cost > AR_EP_FTS THEN
              S1 := ' CLASS="alert"';
            ELSE
              S1 := ' CLASS="warn"';
            END IF;
            TDI := '';
          ELSE
            S1  := '';
            TDI := ' CLASS="inner"';
          END IF;
          print('<TR'||S1||'><TD'||TDI||'><DIV STYLE="width:'||5*CW/9||'em"><CODE>'||IND||rplan.operation||' '||rplan.options||
                '</CODE></DIV></TD><TD'||TDI||'>'||rplan.object_owner||'.'||rplan.object_name||
                '</TD><TD'||TDI||'>'||NVL(rplan.optimizer,'&nbsp;'));
          print('</TD><TD ALIGN="right"'||TDI||'>'||rplan.vcost||'</TD><TD ALIGN="right"'||TDI||'>'||
                NVL(TO_CHAR(rplan.cpu_cost,'9,999,999,999,990'),'&nbsp;')||
                '</TD><TD ALIGN="right"'||TDI||'>'||NVL(TO_CHAR(rplan.io_cost,'999,999,990'),'&nbsp;')||
                '</TD><TD ALIGN="right"'||TDI||'><DIV STYLE="width:'||CI||'em">'||OSIZE||'</DIV></TD></TR>');
        END LOOP;
        print('</TABLE></TD></TR>');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;

  -- Get CPU parse of all sessions
  PROCEDURE get_parsecpupct (oval OUT VARCHAR2) IS
    BEGIN
     SELECT to_char((100*a.total/b.total),'999,999,990.00')||'%' INTO oval FROM
       ( SELECT (e.value - b.value) total
           FROM stats$sysstat b, stats$sysstat e
          WHERE b.snap_id = BID
            AND e.snap_id = EID
            AND b.dbid    = DB_ID
            AND e.dbid    = DB_ID
            AND b.instance_number = INST_NUM
            AND e.instance_number = INST_NUM
            AND b.name    = e.name
            AND e.name    = 'parse time cpu'
            AND e.value   > b.value
            AND e.value   > 0 ) a,
       ( SELECT (e.value - b.value) total
           FROM stats$sysstat b, stats$sysstat e
          WHERE b.snap_id = BID
            AND e.snap_id = EID
            AND b.dbid    = DB_ID
            AND e.dbid    = DB_ID
            AND b.instance_number = INST_NUM
            AND e.instance_number = INST_NUM
            AND b.name    = e.name
            AND e.name    = 'CPU used by this session'
            AND e.value   > b.value
            AND e.value   > 0 ) b;
    END;


  -- SQL by Gets
  PROCEDURE sqlbygets IS
    WARN VARCHAR2(50);
    CURSOR C_SQLByGets (gets IN NUMBER) IS
      SELECT bufgets,execs,getsperexec,pcttotal,cputime,elapsed,exe,ela,sql_id,hashval,oldhashval,last_active,modul
        FROM ( SELECT /*+ ordered use_nl (b st) */
                  to_char((e.buffer_gets - nvl(b.buffer_gets,0)),'99,999,999,990') bufgets,
                  to_char((e.executions - nvl(b.executions,0)),'999,999,999') execs,
                  e.executions - nvl(b.executions,0) exe,
                  to_char(decode(e.executions - nvl(b.executions,0),
                                 0, '&nbsp;',
                                 (e.buffer_gets - nvl(b.buffer_gets,0)) / (e.executions - nvl(b.executions,0))),
                                 '99,999,999,990.0') getsperexec,
                  to_char(100*(e.buffer_gets - nvl(b.buffer_gets,0))/gets,
                          '999,999,990.0') pcttotal,
                  (e.cpu_time - nvl(b.cpu_time,0))/1000 cputime,
                  (e.elapsed_time - nvl(b.elapsed_time,0))/1000 elapsed,
                  NVL((e.elapsed_time - nvl(b.elapsed_time,0))/1000000,0) ela,
                  NVL ( e.hash_value,0 ) hashval,
                  NVL ( e.old_hash_value,0 ) oldhashval,
                  NVL ( e.sql_id,0 ) sql_id,
                  to_char(e.last_active_time,'YYYY-MM-DD HH24:MI') last_active,
                  NVL(e.module,'&nbsp;') modul
              FROM stats$sql_summary e, stats$sql_summary b
             WHERE b.snap_id(+)  = BID
               AND b.dbid(+)     = e.dbid
               AND b.instance_number(+) = e.instance_number
               AND b.hash_value(+)      = e.hash_value
               AND b.address(+)  = e.address
               AND b.text_subset(+)     = e.text_subset
               AND e.snap_id     = EID
               AND e.dbid        = DB_ID
               AND e.instance_number    = INST_NUM
               AND e.executions  > nvl(b.executions,0)
             ORDER BY (e.buffer_gets - nvl(b.buffer_gets,0)) desc, e.hash_value
           )
       WHERE rownum <= TOP_N_SQL;
    BEGIN
      L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="10"><A NAME="sqlbygets">Top '||TOP_N_SQL||' SQL ordered by Gets</A></TH></TR>'||
                CHR(10)||' <TR><TD COLSPAN="10" ALIGN="center">End Buffer Gets Treshold: '||EBGT;
      print(L_LINE);
      L_LINE := '<P ALIGN="justify" STYLE="margin-top:4">Note that resources reported for PL/SQL includes the '||
                'resources used by all SQL statements called within the PL/SQL code.'||
                ' As individual SQL statements are also reported, ';
      print(L_LINE);
      L_LINE := 'it is possible and valid for the summed total % to exceed 100.<BR>'||
                'If your primary tuning goal is reducing resource usage, start tuning '||
                'these statements/objects ';
      print(L_LINE);
      L_LINE := '(CPU) plus <A HREF="#sqlbyreads">SQL by Reads</A> (File IO).</P></TD></TR>'||CHR(10)||
                ' <TR><TH CLASS="th_sub">Buffer Gets</TH><TH CLASS="th_sub">Executions</TH>';
      print(L_LINE);
      L_LINE := '<TH CLASS="th_sub">Gets per Exec</TH>'||
                '<TH CLASS="th_sub">Total</TH><TH CLASS="th_sub">CPU Time</TH>'||
                '<TH CLASS="th_sub">Elapsed Time</TH><TH CLASS="th_sub">SQL ID</TH>';
      print(L_LINE);
      L_LINE := '<TH CLASS="th_sub">Hash Value</TD>'||
                '<TH CLASS="th_sub">Last Active</TH><TH CLASS="th_sub">Module</TH></TR>';
      print(L_LINE);
      FOR R_SQL IN C_SQLByGets(GETS) LOOP
        WARN := alert_gt_warn(R_SQL.ela/R_SQL.exe,AR_ET,WR_ET);
        L_LINE := ' <TR'||WARN||'><TD ALIGN="right" TITLE="Buffer Gets">'||R_SQL.bufgets||'</TD><TD ALIGN="right" TITLE="Executions">'||
                  R_SQL.execs||'</TD><TD ALIGN="right" TITLE="Gets/Exec">'||R_SQL.getsperexec||
                  '</TD><TD ALIGN="right">'||R_SQL.pcttotal||'%</TD><TD ALIGN="right" TITLE="CPU Time">';
        print(L_LINE);
        L_LINE := format_stime(R_SQL.cputime,1000)||'</TD><TD ALIGN="right" TITLE="Elapsed Time">'||
                  format_stime(R_SQL.elapsed,1000)||'</TD><TD ALIGN="right" TITLE="SQL ID">'||
                  R_SQL.sql_id||'</TD><TD ALIGN="right" TITLE="Hash Value">'||R_SQL.hashval||'</TD>';
        print(L_LINE);
        L_LINE := '</TD><TD ALIGN="right" TITLE="Last Seen">'||R_SQL.last_active||'</TD><TD TITLE="Modul">'||R_SQL.modul||'</TD></TR>'||
                  CHR(10)||' <TR'||WARN||'><TD>&nbsp;</TD><TD COLSPAN="9" CLASS="icode">';
        print(L_LINE);
        print_tsql(R_SQL.sql_id);
        print('</TD></TR>');
        IF MK_EP = 1 THEN
          get_plan(R_SQL.sql_id);
        END IF;
      END LOOP;
      print(TABLE_CLOSE||'<HR>');
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;

  -- SQL by Reads
  PROCEDURE sqlbyreads IS
    WARN VARCHAR2(50);
    CURSOR C_SQLByReads IS
      SELECT phyreads,execs,readsperexec,pcttotal,cputime,elapsed,hashval,exe,ela,sql_id,last_active,modul
        FROM ( SELECT /*+ ordered use_nl (b st) */
                  to_char((e.disk_reads - nvl(b.disk_reads,0)),'99,999,999,990') phyreads,
                  to_char((e.executions - nvl(b.executions,0)),'999,999,999') execs,
                  e.executions - nvl(b.executions,0) exe,
                  to_char(decode(e.executions - nvl(b.executions,0),
                             0, '&nbsp;',
                             (e.disk_reads - nvl(b.disk_reads,0)) / (e.executions - nvl(b.executions,0))),
                             '999,999,990.0') readsperexec,
                  to_char(100*(e.disk_reads - nvl(b.disk_reads,0))/phyr,
                          '999,999,990.0') pcttotal,
                  (e.cpu_time - nvl(b.cpu_time,0))/1000 cputime,
                  (e.elapsed_time - nvl(b.elapsed_time,0))/1000 elapsed,
                  NVL((e.elapsed_time - nvl(b.elapsed_time,0))/1000000,0) ela,
                  NVL ( e.hash_value,0 ) hashval,
                  NVL ( e.sql_id,0 ) sql_id,
                  to_char(e.last_active_time,'YYYY-MM-DD HH24:MI') last_active,
                  NVL(e.module,'&nbsp;') modul
              FROM stats$sql_summary e, stats$sql_summary b
             WHERE b.snap_id(+)  = BID
               AND b.dbid(+)     = e.dbid
               AND b.instance_number(+) = e.instance_number
               AND b.hash_value(+)      = e.hash_value
               AND b.address(+)  = e.address
               AND b.text_subset(+)     = e.text_subset
               AND e.snap_id     = EID
               AND e.dbid        = DB_ID
               AND e.instance_number    = INST_NUM
               AND e.executions  > nvl(b.executions,0)
               AND phyr          > 0
             ORDER BY (e.disk_reads - nvl(b.disk_reads,0)) desc, e.hash_value
           )
       WHERE rownum <= TOP_N_SQL;
    BEGIN
      L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="10"><A NAME="sqlbyreads">Top '||TOP_N_SQL||' SQL ordered by Reads</A></TH></TR>'||CHR(10)||
                ' <TR><TD COLSPAN="10" ALIGN="center">End Disk Reads Treshold: '||EDRT||
                '<BR>If your primary tuning ';
      print(L_LINE);
      L_LINE := 'goal is to reduce resource usage, start by tuning these '||
                'statements/objects (File IO) plus <A HREF="#sqlbygets">SQL by '||
                'Gets (CPU)</A>.</TD></TR>';
      print(L_LINE);
      L_LINE := ' <TR><TH CLASS="th_sub">Pysical Reads</TH><TH CLASS="th_sub">Executions</TH>'||
                '<TH CLASS="th_sub">Reads per Exec</TH><TH CLASS="th_sub">Total</TH>';
      print(L_LINE);
      L_LINE := '<TH CLASS="th_sub">CPU Time</TH><TH CLASS="th_sub">'||
                'Elapsed Time</TH><TH CLASS="th_sub">SQL ID</TH><TH CLASS="th_sub">Hash Value</TH>'||
                '<TH CLASS="th_sub">Last Active</TH><TH CLASS="th_sub">Module</TH></TR>';
      print(L_LINE);
      FOR R_SQL IN C_SQLByReads LOOP
        WARN := alert_gt_warn(R_SQL.ela/R_SQL.exe,AR_ET,WR_ET);
        L_LINE := ' <TR'||WARN||'><TD ALIGN="right" TITLE="Physical Reads">'||R_SQL.phyreads||'</TD><TD ALIGN="right" TITLE="Executions">'||
                  R_SQL.execs||'</TD><TD ALIGN="right" TITLE="Reads/Exec">'||R_SQL.readsperexec||
                  '</TD><TD ALIGN="right">'||R_SQL.pcttotal||'%</TD><TD ALIGN="right" TITLE="CPU Time">';
        print(L_LINE);
        L_LINE := format_stime(R_SQL.cputime,1000)||'</TD><TD ALIGN="right" TITLE="Elapsed Time">'||
                  format_stime(R_SQL.elapsed,1000)||'</TD><TD ALIGN="right" TITLE="SQL ID">'||
                  R_SQL.sql_id||'</TD><TD ALIGN="right" TITLE="Hash Value">'||R_SQL.hashval||'</TD>';
        print(L_LINE);
        L_LINE := '</TD><TD ALIGN="right" TITLE="Last Seen">'||R_SQL.last_active||'</TD><TD TITLE="Modul">'||R_SQL.modul||'</TD></TR>'||
                  CHR(10)||' <TR'||WARN||'><TD>&nbsp;</TD><TD COLSPAN="9" CLASS="icode">';
        print(L_LINE);
        print_tsql(R_SQL.sql_id);
        print('</TD></TR>');
        IF MK_EP = 1 THEN
          get_plan(R_SQL.sql_id);
        END IF;
      END LOOP;
      print(TABLE_CLOSE||'<HR>');
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;

  -- SQL by Executions
  PROCEDURE sqlbyexec IS
    WARN VARCHAR2(50);
    CURSOR C_SQLByExec IS
      SELECT execs,rowsproc,rowsperexec,cputime,elapsed,hashval,ela,sql_id,last_active,modul
        FROM ( SELECT /*+ ordered use_nl (b st) */
                  to_char((e.executions - nvl(b.executions,0)),'999,999,999') execs,
                  to_char((nvl(e.rows_processed,0) - nvl(b.rows_processed,0)),
                         '99,999,999,999') rowsproc,
                  to_char(decode(nvl(e.rows_processed,0) - nvl(b.rows_processed,0),
                         0, 0,
                         (e.rows_processed - nvl(b.rows_processed,0)) / (e.executions - nvl(b.executions,0))),
                         '9,999,999,990.0') rowsperexec,
                  (e.cpu_time - nvl(b.cpu_time,0)) / (e.executions - nvl(b.executions,0)) / 1000 cputime,
                  (e.elapsed_time - nvl(b.elapsed_time,0)) / (e.executions - nvl(b.executions,0)) / 1000 elapsed,
                  NVL ( e.hash_value,0 ) hashval,
                  NVL ( e.sql_id,0 ) sql_id,
                  to_char(e.last_active_time,'YYYY-MM-DD HH24:MI') last_active,
                  NVL(e.module,'&nbsp;') modul
              FROM stats$sql_summary e, stats$sql_summary b
             WHERE b.snap_id(+)  = BID
               AND b.dbid(+)     = e.dbid
               AND b.instance_number(+) = e.instance_number
               AND b.hash_value(+)      = e.hash_value
               AND b.address(+)  = e.address
               AND b.text_subset(+)     = e.text_subset
               AND e.snap_id     = EID
               AND e.dbid        = DB_ID
               AND e.instance_number    = INST_NUM
               AND e.executions  > nvl(b.executions,0)
               AND phyr          > 0
             ORDER BY (e.executions - nvl(b.executions,0)) desc,
                      e.hash_value
           )
       WHERE rownum <= TOP_N_SQL;
    BEGIN
      L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="9"><A NAME="sqlbyexec">Top '||TOP_N_SQL||' SQL ordered by Executions</A></TH></TR>'||CHR(10)||
                ' <TR><TD COLSPAN="9" ALIGN="center">End Executions Treshold: '||EET||
                '<BR>Start with tuning these ';
      print(L_LINE);
      L_LINE := 'statements if your primary goal is to increase the response time.</TD></TR>';
      print(L_LINE);
      L_LINE := ' <TR><TH CLASS="th_sub">Executions</TH><TH CLASS="th_sub">Rows Processed</TH>'||
                '<TH CLASS="th_sub">Rows per Exec</TH><TH CLASS="th_sub">CPU per Exec</TH>';
      print(L_LINE);
      L_LINE := '<TH CLASS="th_sub">Elap per Exec</TH><TH CLASS="th_sub">SQL ID</TH><TH CLASS="th_sub">Hash Value</TH>'||
                '<TH CLASS="th_sub">Last Active</TH><TH CLASS="th_sub">Module</TH></TR>';
      print(L_LINE);
      FOR R_SQL IN C_SQLByExec LOOP
        WARN := alert_gt_warn(R_SQL.elapsed,AR_ET,WR_ET);
        L_LINE := ' <TR'||WARN||'><TD ALIGN="right" TITLE="Executions">'||R_SQL.execs||'</TD><TD ALIGN="right" TITLE="Rows Processed">'||
                  R_SQL.rowsproc||'</TD><TD ALIGN="right" TITLE="Rows/Exec">'||R_SQL.rowsperexec||
                  '</TD><TD ALIGN="right" TITLE="CPU Time">'||format_stime(R_SQL.cputime,1000)||
                  '</TD><TD ALIGN="right" TITLE="Elapsed Time">';
        print(L_LINE);
        L_LINE := format_stime(R_SQL.elapsed,1000)||'</TD><TD ALIGN="right" TITLE="SQL ID">'||
                  R_SQL.sql_id||'</TD><TD ALIGN="right" TITLE="Hash Value">'||R_SQL.hashval||'</TD>';
        print(L_LINE);
        L_LINE := '</TD><TD ALIGN="right" TITLE="Last Seen">'||R_SQL.last_active||'</TD><TD TITLE="Modul">'||R_SQL.modul||'</TD></TR>'||
                  CHR(10)||' <TR'||WARN||'><TD>&nbsp;</TD><TD COLSPAN="8" CLASS="icode">';
        print(L_LINE);
        print_tsql(R_SQL.sql_id);
        print('</TD></TR>');
        IF MK_EP = 1 THEN
          get_plan(R_SQL.sql_id);
        END IF;
      END LOOP;
      print(TABLE_CLOSE||'<HR>');
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;

  -- SQL by Parse
  PROCEDURE sqlbyparse IS
    CURSOR C_SQLByParse IS
      SELECT parses,execs,CASE parsenum WHEN 0 THEN '&nbsp;' ELSE to_char(execnum/parsenum,'999,990.0') END execsperparse,pctparses,hashval,sql_id,last_active,modul
        FROM ( SELECT /*+ ordered use_nl (b st) */
                  to_char((e.parse_calls - nvl(b.parse_calls,0)),'999,999,990') parses,
                  to_char((e.executions - nvl(b.executions,0)),'999,999,990') execs,
                  NVL(e.executions,0) - NVL(b.executions,0) execnum,
                  NVL(e.parse_calls,0) - NVL(b.parse_calls,0) parsenum,
                  to_char((nvl(e.parse_calls,0) - nvl(b.parse_calls,0))/PRSE, '990.00') pctparses,
                  NVL ( e.hash_value,0 ) hashval,
                  NVL ( e.sql_id,0 ) sql_id,
                  to_char(e.last_active_time,'YYYY-MM-DD HH24:MI') last_active,
                  NVL(e.module,'&nbsp;') modul
              FROM stats$sql_summary e, stats$sql_summary b
             WHERE b.snap_id(+)  = BID
               AND b.dbid(+)     = e.dbid
               AND b.instance_number(+) = e.instance_number
               AND b.hash_value(+)      = e.hash_value
               AND b.address(+)     = e.address
               AND b.text_subset(+) = e.text_subset
               AND e.snap_id     = EID
               AND e.dbid        = DB_ID
               AND e.instance_number    = INST_NUM
             ORDER BY (e.parse_calls - nvl(b.parse_calls,0)) desc, e.hash_value
           )
       WHERE rownum <= TOP_N_SQL;
    BEGIN
      get_parsecpupct(S1);
      L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="8"><A NAME="sqlbyparse">Top '||TOP_N_SQL||' SQL ordered by Parse Calls</A>&nbsp;<A HREF="JavaScript:popup('||CHR(39)||'parse'||CHR(39)||')"><IMG SRC="help/help.gif" BORDER="0" HEIGHT="16" ALIGN="top" ALT="Help"></TH></TR>'||CHR(10)||
                ' <TR><TD COLSPAN="8" ALIGN="center">End Parse Calls Treshold: '||EPC||
                '<BR>Consider tuning these ';
      print(L_LINE);
      L_LINE := 'statements/objects, if the percentage of CPU used for parsing is high. '||
                'Currently, parsing takes avg. '||S1||'% of all CPU usage by all sessions.</TD></TR>';
      print(L_LINE);
      L_LINE := ' <TR><TH CLASS="th_sub">Parse Calls</TH><TH CLASS="th_sub">Executions</TH><TH CLASS="th_sub">Exec / Parse</TH>'||
                '<TH CLASS="th_sub">Total Parses</TH><TH CLASS="th_sub">SQL ID</TH><TH CLASS="th_sub">Hash Value</TH>'||
                '<TH CLASS="th_sub">Last Active</TH><TH CLASS="th_sub">Module</TH></TR>';
      print(L_LINE);
      FOR R_SQL IN C_SQLByParse LOOP
        L_LINE := ' <TR><TD ALIGN="right" TITLE="Parse Calls">'||R_SQL.parses||'</TD><TD ALIGN="right" TITLE="Executions">'||
                  R_SQL.execs||'</TD><TD ALIGN="right" TITLE="Exec/Parse">'||R_SQL.execsperparse||'</TD><TD ALIGN="right">'||R_SQL.pctparses||
                  '%</TD><TD ALIGN="right" TITLE="SQL ID">'||R_SQL.sql_id||'</TD><TD ALIGN="right" TITLE="Hash Value">'||R_SQL.hashval;
        print(L_LINE);
        L_LINE := '</TD><TD ALIGN="right" TITLE="Last Seen">'||R_SQL.last_active||'</TD><TD TITLE="Modul">'||R_SQL.modul||'</TD></TR>'||
                  '</TD></TR>'||CHR(10)||' <TR><TD>&nbsp;</TD><TD COLSPAN="7" CLASS="icode">';
        print(L_LINE);
        print_tsql(R_SQL.sql_id);
        print('</TD></TR>');
        IF MK_EP = 1 THEN
          get_plan(R_SQL.sql_id);
        END IF;
      END LOOP;
      print(TABLE_CLOSE||'<HR>');
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;


  -- SQL by CPU usage
  PROCEDURE sqlbycpu IS
    WARN VARCHAR2(50);
    CURSOR C_SQLByCPU IS
      SELECT execs,pctparses,rowsperexec,cputime,elapsed,hashval,ela,sql_id,last_active,modul
        FROM ( SELECT /*+ ordered use_nl (b st) */
                  to_char((e.executions - nvl(b.executions,0)),'999,999,999') execs,
                  to_char((nvl(e.parse_calls,0) - nvl(b.parse_calls,0))/PRSE, '990.00') pctparses,
                  to_char(decode(nvl(e.rows_processed,0) - nvl(b.rows_processed,0),
                         0, 0,
                         (e.rows_processed - nvl(b.rows_processed,0)) / (e.executions - nvl(b.executions,0))),
                         '9,999,999,990.0') rowsperexec,
                  (e.cpu_time - nvl(b.cpu_time,0)) / (e.executions - nvl(b.executions,0)) / 1000 cputime,
                  (e.elapsed_time - nvl(b.elapsed_time,0)) / (e.executions - nvl(b.executions,0)) / 1000 elapsed,
                  NVL ( e.hash_value,0 ) hashval,
                  NVL ( e.sql_id,0 ) sql_id,
                  to_char(e.last_active_time,'YYYY-MM-DD HH24:MI') last_active,
                  NVL(e.module,'&nbsp;') modul
              FROM stats$sql_summary e, stats$sql_summary b
             WHERE b.snap_id(+)  = BID
               AND b.dbid(+)     = e.dbid
               AND b.instance_number(+) = e.instance_number
               AND b.hash_value(+)      = e.hash_value
               AND b.address(+)  = e.address
               AND b.text_subset(+)     = e.text_subset
               AND e.snap_id     = EID
               AND e.dbid        = DB_ID
               AND e.instance_number    = INST_NUM
               AND e.executions  > nvl(b.executions,0)
               AND phyr          > 0
             ORDER BY (e.cpu_time - nvl(b.cpu_time,0)) / (e.executions - nvl(b.executions,0)) desc,
                      e.hash_value
           )
       WHERE rownum <= TOP_N_SQL;
    BEGIN
      L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="9"><A NAME="sqlbycpu">Top '||TOP_N_SQL||' SQL ordered by CPU Time</A>&nbsp;<a href="JavaScript:popup('||CHR(39)||'cputime'||CHR(39)||')"><img src="help/help.gif" alt="Help" align="top" border="0" height="16"></a></TH></TR>'||CHR(10);
      print(L_LINE);
      L_LINE := ' <TR><TH CLASS="th_sub">CPU per Exec</TH><TH CLASS="th_sub">Executions</TH>'||
                '<TH CLASS="th_sub">Total Parses</TH><TH CLASS="th_sub">Rows per Exec</TH>';
      print(L_LINE);
      L_LINE := '<TH CLASS="th_sub">Elap per Exec</TH><TH CLASS="th_sub">SQL ID</TH><TH CLASS="th_sub">Hash Value</TH>'||
                '<TH CLASS="th_sub">Last Active</TH><TH CLASS="th_sub">Module</TH></TR>';
      print(L_LINE);
      FOR R_SQL IN C_SQLByCPU LOOP
        WARN := alert_gt_warn(R_SQL.elapsed,AR_ET,WR_ET);
        L_LINE := ' <TR'||WARN||'><TD ALIGN="right" TITLE="CPU Time">'||format_stime(R_SQL.cputime,1000)||'<TD ALIGN="right" TITLE="Executions">'||
                  R_SQL.execs||'</TD><TD ALIGN="right" TITLE="Total Parses">'||R_SQL.pctparses||'</TD><TD ALIGN="right" TITLE="Rows/Exec">'||
                  R_SQL.rowsperexec||'</TD></TD><TD ALIGN="right" TITLE="Elapsed Time">';
        print(L_LINE);
        L_LINE := format_stime(R_SQL.elapsed,1000)||'</TD><TD ALIGN="right" TITLE="SQL ID">'||
                  R_SQL.sql_id||'</TD><TD ALIGN="right" TITLE="Hash Value">'||R_SQL.hashval||
                  '</TD><TD ALIGN="right" TITLE="Last Seen">'||R_SQL.last_active||'</TD><TD TITLE="Modul">'||R_SQL.modul||'</TD></TR>'||
                  CHR(10)||' <TR'||WARN||'><TD>&nbsp;</TD><TD COLSPAN="8" CLASS="icode">';
        print(L_LINE);
        print_tsql(R_SQL.sql_id);
        print('</TD></TR>');
        IF MK_EP = 1 THEN
          get_plan(R_SQL.sql_id);
        END IF;
      END LOOP;
      print(TABLE_CLOSE||'<HR>');
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;


  -- SQL by Time Elapsed
  PROCEDURE sqlbyela IS
    WARN VARCHAR2(50);
    CURSOR C_SQLByEla IS
      SELECT execs,readsperexec,rowsperexec,cputime,elapsed,hashval,ela,sql_id,last_active,modul
        FROM ( SELECT /*+ ordered use_nl (b st) */
                  to_char((e.executions - nvl(b.executions,0)),'999,999,999') execs,
                  to_char(decode(e.executions - nvl(b.executions,0),
                             0, '&nbsp;',
                             (e.disk_reads - nvl(b.disk_reads,0)) / (e.executions - nvl(b.executions,0))),
                             '999,999,990.0') readsperexec,
                  to_char(decode(nvl(e.rows_processed,0) - nvl(b.rows_processed,0),
                         0, 0,
                         (e.rows_processed - nvl(b.rows_processed,0)) / (e.executions - nvl(b.executions,0))),
                         '9,999,999,990.0') rowsperexec,
                  (e.cpu_time - nvl(b.cpu_time,0)) / (e.executions - nvl(b.executions,0)) / 1000 cputime,
                  (e.elapsed_time - nvl(b.elapsed_time,0)) / (e.executions - nvl(b.executions,0)) / 1000 elapsed,
                  NVL ( e.hash_value,0 ) hashval,
                  NVL ( e.sql_id,0 ) sql_id,
                  to_char(e.last_active_time,'YYYY-MM-DD HH24:MI') last_active,
                  NVL(e.module,'&nbsp;') modul
              FROM stats$sql_summary e, stats$sql_summary b
             WHERE b.snap_id(+)  = BID
               AND b.dbid(+)     = e.dbid
               AND b.instance_number(+) = e.instance_number
               AND b.hash_value(+)      = e.hash_value
               AND b.address(+)  = e.address
               AND b.text_subset(+)     = e.text_subset
               AND e.snap_id     = EID
               AND e.dbid        = DB_ID
               AND e.instance_number    = INST_NUM
               AND e.executions  > nvl(b.executions,0)
               AND phyr          > 0
             ORDER BY (e.elapsed_time - nvl(b.elapsed_time,0)) / (e.executions - nvl(b.executions,0)) desc,
                      e.hash_value
           )
       WHERE rownum <= TOP_N_SQL;
    BEGIN
      L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="9"><A NAME="sqlbyela">Top '||TOP_N_SQL||' SQL ordered by Time Elapsed</A></TH></TR>'||CHR(10)||
                ' <TR><TD COLSPAN="9" ALIGN="center">Statements may consume much time either waiting for resources or wasting them - check the Reads and CPU to find out which applies.</TD></TR>';
      print(L_LINE);
      L_LINE := ' <TR><TH CLASS="th_sub">Elap per Exec</TH><TH CLASS="th_sub">Executions</TH>'||
                '<TH CLASS="th_sub">Reads per Exec</TH><TH CLASS="th_sub">Rows per Exec</TH>';
      print(L_LINE);
      L_LINE := '<TH CLASS="th_sub">CPU per Exec</TH><TH CLASS="th_sub">SQL ID</TH><TH CLASS="th_sub">Hash Value</TH>'||
                '<TH CLASS="th_sub">Last Active</TH><TH CLASS="th_sub">Module</TH></TR>';
      print(L_LINE);
      FOR R_SQL IN C_SQLByEla LOOP
        WARN := alert_gt_warn(R_SQL.elapsed,AR_ET,WR_ET);
        L_LINE := ' <TR'||WARN||'><TD ALIGN="right" TITLE="Elapsed Time">'||format_stime(R_SQL.elapsed,1000)||'</TD><TD ALIGN="right" TITLE="Executions">'||
                  R_SQL.execs||'</TD><TD ALIGN="right" TITLE="Reads/Exec">'||R_SQL.readsperexec||'</TD><TD ALIGN="right" TITLE="Rows/Exec">'||
                  R_SQL.rowsperexec||'</TD><TD ALIGN="right" TITLE="CPU Time">'||format_stime(R_SQL.cputime,1000);
        print(L_LINE);
        L_LINE := '</TD><TD ALIGN="right" TITLE="SQL ID">'||R_SQL.sql_id||'</TD><TD ALIGN="right" TITLE="Hash Value">'||R_SQL.hashval||'</TD>';
        print(L_LINE);
        L_LINE := '<TD ALIGN="right" TITLE="Last Seen">'||R_SQL.last_active||'</TD><TD TITLE="Modul">'||R_SQL.modul||'</TD></TR>'||
                  CHR(10)||' <TR'||WARN||'><TD>&nbsp;</TD><TD COLSPAN="8" CLASS="icode">';
        print(L_LINE);
        print_tsql(R_SQL.sql_id);
        print('</TD></TR>');
        IF MK_EP = 1 THEN
          get_plan(R_SQL.sql_id);
        END IF;
      END LOOP;
      print(TABLE_CLOSE||'<HR>');
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;


  -- SQL by Invalidations
  PROCEDURE sqlbyinv IS
    WARN VARCHAR2(50);
    SI NUMBER;
    CURSOR C_SQLByInv IS
      SELECT execs,invals,rowsperexec,cputime,elapsed,hashval,ela,sql_id,last_active,modul
        FROM ( SELECT /*+ ordered use_nl (b st) */
                  to_char((e.executions - nvl(b.executions,0)),'999,999,999') execs,
                  to_char((nvl(e.invalidations,0) - nvl(b.invalidations,0)),
                         '99,999,999,999') invals,
                  to_char(decode(nvl(e.rows_processed,0) - nvl(b.rows_processed,0),
                         0, 0,
                         (e.rows_processed - nvl(b.rows_processed,0)) / (e.executions - nvl(b.executions,0))),
                         '9,999,999,990.0') rowsperexec,
                  (e.cpu_time - nvl(b.cpu_time,0)) / (e.executions - nvl(b.executions,0)) / 1000 cputime,
                  (e.elapsed_time - nvl(b.elapsed_time,0)) / (e.executions - nvl(b.executions,0)) / 1000 elapsed,
                  NVL ( e.hash_value,0 ) hashval,
                  NVL ( e.sql_id,0 ) sql_id,
                  to_char(e.last_active_time,'YYYY-MM-DD HH24:MI') last_active,
                  NVL(e.module,'&nbsp;') modul
              FROM stats$sql_summary e, stats$sql_summary b
             WHERE b.snap_id(+)  = BID
               AND b.dbid(+)     = e.dbid
               AND b.instance_number(+) = e.instance_number
               AND b.hash_value(+)      = e.hash_value
               AND b.address(+)  = e.address
               AND b.text_subset(+)     = e.text_subset
               AND e.snap_id     = EID
               AND e.dbid        = DB_ID
               AND e.instance_number    = INST_NUM
               AND e.executions  > nvl(b.executions,0)
               AND e.invalidations > nvl(b.invalidations,0)
               AND phyr          > 0
             ORDER BY (nvl(e.invalidations,0) - nvl(b.invalidations,0)) desc,
                      e.hash_value
           )
       WHERE rownum <= TOP_N_SQL;
    BEGIN
      L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="9"><A NAME="sqlbyinv">Top '||TOP_N_SQL||' SQL ordered by Invalidations</A>&nbsp;<a href="JavaScript:popup('||CHR(39)||'invalidations'||CHR(39)||')"><img src="help/help.gif" alt="Help" align="top" border="0" height="16"></a></TH></TR>'||CHR(10)||
                ' <TR><TD COLSPAN="9" ALIGN="center">Invalidations usually mean changes on underlying objects.</TD></TR>';
      print(L_LINE);
      L_LINE := ' <TR><TH CLASS="th_sub">Invalidations</TH><TH CLASS="th_sub">Executions</TH>'||
                '<TH CLASS="th_sub">Elap per Exec</TH><TH CLASS="th_sub">Rows per Exec</TH>';
      print(L_LINE);
      L_LINE := '<TH CLASS="th_sub">CPU per Exec</TH><TH CLASS="th_sub">SQL ID</TH><TH CLASS="th_sub">Hash Value</TH>'||
                '<TH CLASS="th_sub">Last Active</TH><TH CLASS="th_sub">Module</TH></TR>';
      print(L_LINE);
      FOR R_SQL IN C_SQLByInv LOOP
        WARN := alert_gt_warn(R_SQL.elapsed,AR_ET,WR_ET);
        L_LINE := ' <TR'||WARN||'><TD ALIGN="right" TITLE="Invalidations">'||R_SQL.invals||'</TD><TD ALIGN="right" TITLE="Executions">'||
                  R_SQL.execs||'</TD><TD ALIGN="right" TITLE="Elapsed Time">'||format_stime(R_SQL.elapsed,1000)||
                  '</TD><TD ALIGN="right" TITLE="Rows/Exec">'||R_SQL.rowsperexec||
                  '</TD><TD ALIGN="right" TITLE="CPU Time">'||format_stime(R_SQL.cputime,1000);
        print(L_LINE);
        L_LINE := '</TD><TD ALIGN="right" TITLE="SQL ID">'||R_SQL.sql_id||'</TD><TD ALIGN="right" TITLE="Hash Value">'||R_SQL.hashval||'</TD>';
        print(L_LINE);
        L_LINE := '<TD ALIGN="right" TITLE="Last Seen">'||R_SQL.last_active||'</TD><TD TITLE="Modul">'||R_SQL.modul||'</TD></TR>'||
                  CHR(10)||' <TR'||WARN||'><TD>&nbsp;</TD><TD COLSPAN="8" CLASS="icode">';
        print(L_LINE);
        print_tsql(R_SQL.sql_id);
        print('</TD></TR>');
        IF MK_EP = 1 THEN
          get_plan(R_SQL.sql_id);
        END IF;
        SI := SI +1;
      END LOOP;
      IF SI = 0 THEN
        L_LINE := ' <TR><TD ALIGN="center" COLSPAN="9">No matching statements found.</TD></TR>';
        print(L_LINE);
      END IF;
      print(TABLE_CLOSE||'<HR>');
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;
