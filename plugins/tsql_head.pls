  -- Get and print an SQL statement
  PROCEDURE print_tsql(thash IN VARCHAR2) IS
    CURSOR C_GetSQL (hv IN NUMBER) IS
      SELECT replace(replace(sql_text,'<','&lt;'),'>','&gt;') AS sql_text
        FROM stats$sqltext WHERE hash_value=hv
       ORDER BY piece;
    BEGIN
      FOR R_Statement IN C_GetSQL(thash) LOOP
        print(R_Statement.sql_text);
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;

  -- Get and print the Execution Plan
  PROCEDURE get_plan (bid IN NUMBER, eid IN NUMBER, hashval IN VARCHAR2) IS
    HASHID NUMBER; CI NUMBER; SI NUMBER; OSIZE VARCHAR2(50); IND VARCHAR2(255);
    CW NUMBER;
    CURSOR C_PGet (bid IN NUMBER, eid IN NUMBER, hash_val IN VARCHAR2) IS
      SELECT operation,options,object_owner,object_name,optimizer,cost,
             NVL(TO_CHAR(cost,'999,990'),'&nbsp;') vcost,
             bytes,cpu_cost,io_cost,depth
        FROM stats$sql_plan,
	     ( SELECT MAX(snap_id) maxid FROM stats$sql_plan
	        WHERE snap_id BETWEEN bid AND eid
		  AND plan_hash_value = hash_val ) id
       WHERE plan_hash_value = hash_val
       ORDER BY id;
    BEGIN
      SELECT MAX(snap_id) INTO SI
        FROM ( SELECT plan_hash_value,snap_id
                 FROM stats$sql_plan_usage
                WHERE hash_value = hashval
                  AND snap_id BETWEEN bid AND eid );
      SELECT MAX(plan_hash_value) INTO HASHID
        FROM ( SELECT plan_hash_value,snap_id
                 FROM stats$sql_plan_usage
                WHERE hash_value = hashval
                  AND snap_id=SI );
      IF HASHID > 0 THEN
      IND := 'SELECT COUNT(snap_id) FROM stats$sql_plan'||
             ' WHERE plan_hash_value = '||HASHID||
	     '   AND rownum = 1'||
             '   AND object_owner NOT IN ('||EXCLUDE_OWNERS||')';
      EXECUTE IMMEDIATE IND INTO CI;
      ELSE CI := 0;
      END IF;
      IF CI > 0
      THEN
        CW := 20;
        print('<TR><TD>&nbsp;</TD><TD COLSPAN="6">');
        print(TABLE_OPEN||'<TR><TH CLASS="th_sub">Operation</TH><TH CLASS="th_sub">'||
              'Object</TH><TH CLASS="th_sub">');
        print('Optimizer</TH><TH CLASS="th_sub">Cost</TH><TH CLASS="th_sub">'||
              'CPUCost</TH><TH CLASS="th_sub">IOCost</TH><TH CLASS="th_sub">'||
              'Size</TH></TR>');
        FOR rplan IN C_PGet(bid,eid,HASHID) LOOP
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
            OSIZE := TO_CHAR(rplan.bytes/1024,'999,999,990')||' k';
          END IF;
	  IND := '';
	  FOR CI IN 1..rplan.depth LOOP
	    IND := IND||'. ';
	  END LOOP;
	  SI := 11*(LENGTH(rplan.operation) + LENGTH(rplan.options) + 2*rplan.depth)/9;
	  CI := 3*(LENGTH(OSIZE)+1)/10;
	  IF SI > CW THEN CW := SI; END IF;
	  IF rplan.operation||' '||rplan.options = 'TABLE ACCESS FULL' THEN
	    IF rplan.cost > AR_EP_FTS THEN
	      S1 := ' CLASS="alert"';
	    ELSE
	      S1 := ' CLASS="warn"';
	    END IF;
	  ELSE
	    S1 := '';
	  END IF;
          print('<TR'||S1||'><TD><DIV STYLE="width:'||5*CW/9||'em"><CODE>'||IND||rplan.operation||' '||rplan.options||
                '</CODE></DIV></TD><TD>'||rplan.object_owner||'.'||rplan.object_name||
                '</TD><TD>'||NVL(rplan.optimizer,'&nbsp;'));
          print('</TD><TD ALIGN="right">'||rplan.vcost||'</TD><TD ALIGN="right">'||
                NVL(TO_CHAR(rplan.cpu_cost,'999,990'),'&nbsp;')||
                '</TD><TD ALIGN="right">'||NVL(TO_CHAR(rplan.io_cost,'999,990'),'&nbsp;')||
                '</TD><TD ALIGN="right"><DIV STYLE="width:'||CI||'em">'||OSIZE||'</DIV></TD></TR>');
        END LOOP;
        print('</TABLE></TD></TR>');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;

  -- Get CPU parse of all sessions
  PROCEDURE get_parsecpupct (db_id IN NUMBER, instnum IN NUMBER, bid IN NUMBER, eid IN NUMBER, oval OUT VARCHAR2) IS
    BEGIN
     SELECT to_char((100*a.total/b.total),'990.00') INTO oval FROM
       ( SELECT (e.value - b.value) total
           FROM stats$sysstat b, stats$sysstat e
          WHERE b.snap_id = bid
            AND e.snap_id = eid
            AND b.dbid    = db_id
            AND e.dbid    = db_id
            AND b.instance_number = instnum
            AND e.instance_number = instnum
            AND b.name    = e.name
            AND e.name    = 'parse time cpu'
            AND e.value   > b.value
            AND e.value   > 0 ) a,
       ( SELECT (e.value - b.value) total
           FROM stats$sysstat b, stats$sysstat e
          WHERE b.snap_id = bid
            AND e.snap_id = eid
            AND b.dbid    = db_id
            AND e.dbid    = db_id
            AND b.instance_number = instnum
            AND e.instance_number = instnum
            AND b.name    = e.name
            AND e.name    = 'CPU used by this session'
            AND e.value   > b.value
            AND e.value   > 0 ) b;
    END;


  -- SQL by Gets
  PROCEDURE sqlbygets IS
    CURSOR C_SQLByGets (db_id IN NUMBER, instnum IN NUMBER, bid IN NUMBER, eid IN NUMBER, gets IN NUMBER) IS
      SELECT bufgets,execs,getsperexec,pcttotal,cputime,elapsed,hashval
        FROM ( SELECT /*+ ordered use_nl (b st) */
              to_char((e.buffer_gets - nvl(b.buffer_gets,0)),'99,999,999,990') bufgets,
	      to_char((e.executions - nvl(b.executions,0)),'999,999,999') execs,
	      to_char(decode(e.executions - nvl(b.executions,0),
			         0, '&nbsp;',
				 (e.buffer_gets - nvl(b.buffer_gets,0)) /
				 (e.executions - nvl(b.executions,0))),
				 '999,999,990.0') getsperexec,
	      to_char(100*(e.buffer_gets - nvl(b.buffer_gets,0))/gets,
			  '990.0') pcttotal,
	      nvl(to_char( (e.cpu_time - nvl(b.cpu_time,0))/1000000,
			  '99,990.00'),'0.00') cputime,
	      nvl(to_char( (e.elapsed_time - nvl(b.elapsed_time,0))
			/ 1000000,'99,990.00'), '0.00') elapsed,
	      NVL ( e.hash_value,0 ) hashval
	      FROM stats$sql_summary e, stats$sql_summary b
	     WHERE b.snap_id(+)  = bid
	       AND b.dbid(+)     = e.dbid
	       AND b.instance_number(+) = e.instance_number
	       AND b.hash_value(+)      = e.hash_value
	       AND b.address(+)  = e.address
	       AND b.text_subset(+)     = e.text_subset
	       AND e.snap_id     = eid
	       AND e.dbid        = db_id
	       AND e.instance_number    = instnum
	       AND e.executions  > nvl(b.executions,0)
	     ORDER BY (e.buffer_gets - nvl(b.buffer_gets,0)) desc,
	              e.hash_value
	   )
       WHERE rownum <= TOP_N_SQL;
    BEGIN
      L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="7"><A NAME="sqlbygets">Top '||TOP_N_SQL||' SQL ordered by Gets</A></TH></TR>'||
                CHR(10)||' <TR><TD COLSPAN="7" ALIGN="center">End Buffer Gets Treshold: '||EBGT;
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
                '<TH CLASS="th_sub">% Total</TH><TH CLASS="th_sub">CPU Time (s)</TH>'||
                '<TH CLASS="th_sub">Elapsed Time (s)</TH><TH CLASS="th_sub">Hash Value</TH></TR>';
      print(L_LINE);
      FOR R_SQL IN C_SQLByGets(DBID,INST_NUM,BID,EID,GETS) LOOP
        L_LINE := ' <TR><TD ALIGN="right">'||R_SQL.bufgets||'</TD><TD ALIGN="right">'||
                  R_SQL.execs||'</TD><TD ALIGN="right">'||R_SQL.getsperexec||
	          '</TD><TD ALIGN="right">'||R_SQL.pcttotal||'</TD><TD ALIGN="right">';
        print(L_LINE);
        L_LINE := R_SQL.cputime||'</TD><TD ALIGN="right">'||R_SQL.elapsed||
                  '</TD><TD ALIGN="right">'||R_SQL.hashval||'</TD></TR>'||CHR(10)||
	          ' <TR><TD>&nbsp;</TD><TD COLSPAN="6">';
        print(L_LINE);
	print_tsql(R_SQL.hashval);
        print('</TD></TR>');
        IF MK_EP = 1 THEN
          get_plan(BID,EID,R_SQL.hashval);
        END IF;
      END LOOP;
      print(TABLE_CLOSE||'<HR>');
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;

  -- SQL by Reads
  PROCEDURE sqlbyreads IS
    CURSOR C_SQLByReads (db_id IN NUMBER, instnum IN NUMBER, bid IN NUMBER, eid IN NUMBER, phyr IN NUMBER) IS
      SELECT phyreads,execs,readsperexec,pcttotal,cputime,elapsed,hashval
        FROM ( SELECT /*+ ordered use_nl (b st) */
              to_char((e.disk_reads - nvl(b.disk_reads,0)),'99,999,999,990') phyreads,
	      to_char((e.executions - nvl(b.executions,0)),'999,999,999') execs,
	      to_char(decode(e.executions - nvl(b.executions,0),
			         0, '&nbsp;',
				 (e.disk_reads - nvl(b.disk_reads,0)) /
				 (e.executions - nvl(b.executions,0))),
				 '999,999,990.0') readsperexec,
	      to_char(100*(e.buffer_gets - nvl(b.buffer_gets,0))/phyr,
			  '990.0') pcttotal,
	      nvl(to_char( (e.cpu_time - nvl(b.cpu_time,0))/1000000,
			  '99,990.00'),'0.00') cputime,
	      nvl(to_char( (e.elapsed_time - nvl(b.elapsed_time,0))
			/ 1000000,'99,990.00'), '0.00') elapsed,
	      NVL ( e.hash_value,0 ) hashval
	      FROM stats$sql_summary e, stats$sql_summary b
	     WHERE b.snap_id(+)  = bid
	       AND b.dbid(+)     = e.dbid
	       AND b.instance_number(+) = e.instance_number
	       AND b.hash_value(+)      = e.hash_value
	       AND b.address(+)  = e.address
	       AND b.text_subset(+)     = e.text_subset
	       AND e.snap_id     = eid
	       AND e.dbid        = db_id
	       AND e.instance_number    = instnum
	       AND e.executions  > nvl(b.executions,0)
	       AND phyr          > 0
	     ORDER BY (e.disk_reads - nvl(b.disk_reads,0)) desc,
	              e.hash_value
	   )
       WHERE rownum <= TOP_N_SQL;
    BEGIN
      L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="7"><A NAME="sqlbyreads">Top '||TOP_N_SQL||' SQL ordered by Reads</A></TH></TR>'||CHR(10)||
                ' <TR><TD COLSPAN="7" ALIGN="center">End Disk Reads Treshold: '||EDRT||
	        '<BR>If your primary tuning ';
      print(L_LINE);
      L_LINE := 'goal is to reduce resource usage, start by tuning these '||
                'statements/objects (File IO) plus <A HREF="#sqlbygets">SQL by '||
	        'Gets (CPU)</A>.</TD></TR>';
      print(L_LINE);
      L_LINE := ' <TR><TH CLASS="th_sub">Pysical Reads</TH><TH CLASS="th_sub">Executions</TH>'||
                '<TH CLASS="th_sub">Reads per Exec</TH><TH CLASS="th_sub">% Total</TH>';
      print(L_LINE);
      L_LINE := '<TH CLASS="th_sub">CPU Time (s)</TH><TH CLASS="th_sub">'||
                'Elapsed Time (s)</TH><TH CLASS="th_sub">Hash Value</TH></TR>';
      print(L_LINE);
      FOR R_SQL IN C_SQLByReads(DBID,INST_NUM,BID,EID,PHYR) LOOP
        L_LINE := ' <TR><TD ALIGN="right">'||R_SQL.phyreads||'</TD><TD ALIGN="right">'||
                  R_SQL.execs||'</TD><TD ALIGN="right">'||R_SQL.readsperexec||
	          '</TD><TD ALIGN="right">'||R_SQL.pcttotal||'</TD><TD ALIGN="right">';
        print(L_LINE);
        L_LINE := R_SQL.cputime||'</TD><TD ALIGN="right">'||R_SQL.elapsed||
                  '</TD><TD ALIGN="right">'||R_SQL.hashval||'</TD></TR>'||CHR(10)||
	          ' <TR><TD>&nbsp;</TD><TD COLSPAN="6">';
        print(L_LINE);
	print_tsql(R_SQL.hashval);
        print('</TD></TR>');
        IF MK_EP = 1 THEN
          get_plan(BID,EID,R_SQL.hashval);
        END IF;
      END LOOP;
      print(TABLE_CLOSE||'<HR>');
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;

  -- SQL by Executions
  PROCEDURE sqlbyexec IS
    CURSOR C_SQLByExec (db_id IN NUMBER, instnum IN NUMBER, bid IN NUMBER, eid IN NUMBER) IS
      SELECT execs,rowsproc,rowsperexec,cputime,elapsed,hashval
        FROM ( SELECT /*+ ordered use_nl (b st) */
	      to_char((e.executions - nvl(b.executions,0)),'999,999,999') execs,
	      to_char((nvl(e.rows_processed,0) - nvl(b.rows_processed,0)),
	             '99,999,999,999') rowsproc,
	      to_char(decode(nvl(e.rows_processed,0) - nvl(b.rows_processed,0),
			         0, 0,
				 (e.rows_processed - nvl(b.rows_processed,0)) /
				 (e.executions - nvl(b.executions,0))),
				 '9,999,999,990.0') rowsperexec,
	      nvl(to_char( (e.cpu_time - nvl(b.cpu_time,0)) /
	                   (e.executions - nvl(b.executions,0)),
			  '9,999,999,990.00'),'0.00') cputime,
	      nvl(to_char( (e.elapsed_time - nvl(b.elapsed_time,0)) /
	                   (e.executions - nvl(b.executions,0)),
			'999,990.00'), '0.00') elapsed,
	      NVL ( e.hash_value,0 ) hashval
	      FROM stats$sql_summary e, stats$sql_summary b
	     WHERE b.snap_id(+)  = bid
	       AND b.dbid(+)     = e.dbid
	       AND b.instance_number(+) = e.instance_number
	       AND b.hash_value(+)      = e.hash_value
	       AND b.address(+)  = e.address
	       AND b.text_subset(+)     = e.text_subset
	       AND e.snap_id     = eid
	       AND e.dbid        = db_id
	       AND e.instance_number    = instnum
	       AND e.executions  > nvl(b.executions,0)
	       AND phyr          > 0
	     ORDER BY (e.executions - nvl(b.executions,0)) desc,
	              e.hash_value
	   )
       WHERE rownum <= TOP_N_SQL;
    BEGIN
      L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="6"><A NAME="sqlbyexec">Top '||TOP_N_SQL||' SQL ordered by Executions</A></TH></TR>'||CHR(10)||
                ' <TR><TD COLSPAN="6" ALIGN="center">End Executions Treshold: '||EET||
	        '<BR>Start with tuning these ';
      print(L_LINE);
      L_LINE := 'statements if your primary goal is to increase the response time.</TD></TR>';
      print(L_LINE);
      L_LINE := ' <TR><TH CLASS="th_sub">Executions</TH><TH CLASS="th_sub">Rows Processed</TH>'||
                '<TH CLASS="th_sub">Rows per Exec</TH><TH CLASS="th_sub">CPU per Exec (s)</TH>';
      print(L_LINE);
      L_LINE := '<TH CLASS="th_sub">Elap per Exec (s)</TH><TH CLASS="th_sub">Hash Value</TH></TR>';
      print(L_LINE);
      FOR R_SQL IN C_SQLByExec(DBID,INST_NUM,BID,EID) LOOP
        L_LINE := ' <TR><TD ALIGN="right">'||R_SQL.execs||'</TD><TD ALIGN="right">'||
                  R_SQL.rowsproc||'</TD><TD ALIGN="right">'||R_SQL.rowsperexec||
                  '</TD><TD ALIGN="right">'||R_SQL.cputime||'</TD><TD ALIGN="right">';
        print(L_LINE);
        L_LINE := R_SQL.elapsed||'</TD><TD ALIGN="right">'||R_SQL.hashval||
                  '</TD></TR>'||CHR(10)||' <TR><TD>&nbsp;</TD><TD COLSPAN="6">';
        print(L_LINE);
	print_tsql(R_SQL.hashval);
        print('</TD></TR>');
        IF MK_EP = 1 THEN
          get_plan(BID,EID,R_SQL.hashval);
        END IF;
      END LOOP;
      print(TABLE_CLOSE||'<HR>');
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;

  -- SQL by Parse
  PROCEDURE sqlbyparse IS
    CURSOR C_SQLByParse (db_id IN NUMBER, instnum IN NUMBER, bid IN NUMBER, eid IN NUMBER, prse IN NUMBER) IS
      SELECT parses,execs,pctparses,hashval
        FROM ( SELECT /*+ ordered use_nl (b st) */
              to_char((e.parse_calls - nvl(b.parse_calls,0)),'999,999,990') parses,
	      to_char((e.executions - nvl(b.executions,0)),'999,999,990') execs,
	      to_char((nvl(e.parse_calls,0) - nvl(b.parse_calls,0))/prse,
	             '990.00') pctparses,
	      NVL ( e.hash_value,0 ) hashval
	      FROM stats$sql_summary e, stats$sql_summary b
	     WHERE b.snap_id(+)  = bid
	       AND b.dbid(+)     = e.dbid
	       AND b.instance_number(+) = e.instance_number
	       AND b.hash_value(+)      = e.hash_value
	       AND b.address(+)  = e.address
	       AND b.text_subset(+)     = e.text_subset
	       AND e.snap_id     = eid
	       AND e.dbid        = db_id
	       AND e.instance_number    = instnum
	     ORDER BY (e.parse_calls - nvl(b.parse_calls,0)) desc,
	              e.hash_value
	   )
       WHERE rownum <= TOP_N_SQL;
    BEGIN
      get_parsecpupct(DBID,INST_NUM,BID,EID,S1);
      L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="4"><A NAME="sqlbyparse">Top '||TOP_N_SQL||' SQL ordered by Parse Calls</A></TH></TR>'||CHR(10)||
                ' <TR><TD COLSPAN="4" ALIGN="center">End Parse Calls Treshold: '||EPC||
	        '<BR>Consider tuning these ';
      print(L_LINE);
      L_LINE := 'statements/objects, if the percentage of CPU used for parsing is high. '||
                'Currently, parsing takes avg. '||S1||'% of all CPU usage by all sessions.</TD></TR>';
      print(L_LINE);
      L_LINE := ' <TR><TH CLASS="th_sub">Parse Calls</TH><TH CLASS="th_sub">Executions</TH>'||
                '<TH CLASS="th_sub">% Total Parses</TH><TH CLASS="th_sub">Hash Value</TH></TR>';
      print(L_LINE);
      FOR R_SQL IN C_SQLByParse(DBID,INST_NUM,BID,EID,PRSE) LOOP
        L_LINE := ' <TR><TD ALIGN="right">'||R_SQL.parses||'</TD><TD ALIGN="right">'||
                  R_SQL.execs||'</TD><TD ALIGN="right">'||R_SQL.pctparses||
	          '</TD><TD ALIGN="right">'||R_SQL.hashval||
                  '</TD></TR>'||CHR(10)||' <TR><TD>&nbsp;</TD><TD COLSPAN="6">';
        print(L_LINE);
	print_tsql(R_SQL.hashval);
        print('</TD></TR>');
        IF MK_EP = 1 THEN
          get_plan(BID,EID,R_SQL.hashval);
        END IF;
      END LOOP;
      print(TABLE_CLOSE||'<HR>');
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;
