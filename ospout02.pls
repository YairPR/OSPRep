  -- Wait Objects
  S1 := 'istats$waitobjects'; I1 := 1; I2 := 0;
  tab_exists(S1,I1,I2);
  IF I2 = 1
  THEN
    get_waitobj(DBID,INST_NUM,BID,EID);
  END IF;

  -- SQL by Gets
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
    FOR R_Statement IN C_GetSQL(R_SQL.hashval) LOOP
      L_LINE := R_Statement.sql_text;
      print(L_LINE);
    END LOOP;
    L_LINE := '</TD></TR>';
    print(L_LINE);
    get_plan(BID,EID,R_SQL.hashval);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- SQL by Reads
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
    FOR R_Statement IN C_GetSQL(R_SQL.hashval) LOOP
      L_LINE := trim(R_Statement.sql_text);
      print(L_LINE);
    END LOOP;
    L_LINE := '</TD></TR>';
    print(L_LINE);
    get_plan(BID,EID,R_SQL.hashval);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- SQL by Executions
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
    FOR R_Statement IN C_GetSQL(R_SQL.hashval) LOOP
      L_LINE := trim(R_Statement.sql_text);
      print(L_LINE);
    END LOOP;
    L_LINE := '</TD></TR>';
    print(L_LINE);
    get_plan(BID,EID,R_SQL.hashval);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- SQL by Parse
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
    FOR R_Statement IN C_GetSQL(R_SQL.hashval) LOOP
      L_LINE := trim(R_Statement.sql_text);
      print(L_LINE);
    END LOOP;
    L_LINE := '</TD></TR>';
    print(L_LINE);
    get_plan(BID,EID,R_SQL.hashval);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- Instance Activity
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="4"><A NAME="instact">Instance Activity Stats</A></TH></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">Statistic</TH><TH CLASS="th_sub">Total</TH>'||
	    '<TH CLASS="th_sub">per Second</TH><TH CLASS="th_sub">per TXN</TH></TR>';
  print(L_LINE);
  FOR R_Inst IN C_InstAct(DBID,INST_NUM,BID,EID,ELA,TRAN) LOOP
    L_LINE := ' <TR><TD CLASS="td_name">'||R_Inst.name||'</TD><TD ALIGN="right">'||
              R_Inst.total||'</TD><TD ALIGN="right">'||R_Inst.sec||
	      '</TD><TD ALIGN="right">'||R_Inst.txn||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- TS IO Summary
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="9"><A NAME="tsio">TableSpace IO Summary Statistics</A>'||
            '&nbsp;<A HREF="JavaScript:popup('||CHR(39)||'fileio'||CHR(39)||
	    ')"><IMG SRC="help/help.gif" BORDER="0" HEIGTH="12" VALIGN="middle"></A></TH></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD COLSPAN="9" ALIGN="center">Ordered by IOs (Reads + Writes)'||
	    ' desc</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">TableSpace</TH><TH CLASS="th_sub">Reads</TH>'||
	    '<TH CLASS="th_sub">AvgReads/s</TH><TH CLASS="th_sub">AvgRd (ms)</TH>'||
	    '<TH CLASS="th_sub">Avg Blks/Rd</TH>';
  print(L_LINE);
  L_LINE:= '<TH CLASS="th_sub">Writes</TH><TH CLASS="th_sub">Avg Wrt/s</TH>'||
           '<TH CLASS="th_sub">Buffer Waits</TH><TH CLASS="th_sub">Avg Buf Wt (ms)</TH></TR>';
  print(L_LINE);
  FOR R_TSIO IN C_TSIO(DBID,INST_NUM,BID,EID,ELA) LOOP
    L_LINE := ' <TR><TD CLASS="td_name">'||R_TSIO.tsname||'</TD><TD ALIGN="right">'||
              R_TSIO.reads||'</TD><TD ALIGN="right">'||R_TSIO.rps||
	      '</TD><TD ALIGN="right">'||R_TSIO.avgrd||'</TD><TD ALIGN="right">';
    print(L_LINE);
    L_LINE := R_TSIO.bpr||'</TD><TD ALIGN="right">'||R_TSIO.writes||
              '</TD><TD ALIGN="right">'||R_TSIO.wps||'</TD><TD ALIGN="right">'||
	      R_TSIO.waits||'</TD><TD ALIGN="right">'||R_TSIO.avgbw||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- File IO Summary
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="10"><A NAME="fileio">File IO Summary Statistics</A>'||
            '&nbsp;<A HREF="JavaScript:popup('||CHR(39)||'fileio'||CHR(39)||
	    ')"><IMG SRC="help/help.gif" BORDER="0" HEIGTH="12" VALIGN="middle"></TH></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD COLSPAN="10" ALIGN="center">Ordered by TableSpace, File'||
	    '</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">TableSpace</TH><TH CLASS="th_sub">Filename</TH>'||
            '<TH CLASS="th_sub">Reads</TH><TH CLASS="th_sub">AvgReads/s</TH>'||
	    '<TH CLASS="th_sub">AvgRd (ms)</TH>';
  print(L_LINE);
  L_LINE:= '<TH CLASS="th_sub">Avg Blks/Rd</TH><TH CLASS="th_sub">Writes</TH>'||
           '<TH CLASS="th_sub">Avg Wrt/s</TH><TH CLASS="th_sub">Buffer Waits</TH>'||
	   '<TH CLASS="th_sub">Avg Buf Wt (ms)</TH></TR>';
  print(L_LINE);
  FOR R_TSIO IN C_FileIO(DBID,INST_NUM,BID,EID,ELA) LOOP
    L_LINE := ' <TR><TD CLASS="td_name">'||R_TSIO.tsname||'</TD><TD CLASS="td_name">'||
              R_TSIO.filename||'</TD><TD ALIGN="right">'||
              R_TSIO.reads||'</TD><TD ALIGN="right">'||R_TSIO.rps||
	      '</TD><TD ALIGN="right">'||R_TSIO.avgrd||'</TD><TD ALIGN="right">';
    print(L_LINE);
    L_LINE := R_TSIO.bpr||'</TD><TD ALIGN="right">'||R_TSIO.writes||
              '</TD><TD ALIGN="right">'||R_TSIO.wps||'</TD><TD ALIGN="right">'||
	      R_TSIO.waits||'</TD><TD ALIGN="right">'||R_TSIO.avgbw||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- Buffer Pool
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="10"><A NAME="bufpool">Buffer Pool Statistics</A></TH></TR>'||
            ' <TR><TD COLSPAN="10" ALIGN="center">Standard Block Size Pools ';
  print(L_LINE);
  L_LINE := 'D:Default, K:Keep, R:Recycle<BR>Default Pools for other block '||
	    'sizes: 2k, 4k, 8k, 16k, 32k</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">Pool</TH><TH CLASS="th_sub"># of Buffers</TH>'||
            '<TH CLASS="th_sub">Cache Hit %</TH><TH CLASS="th_sub">Buffer Gets</TH>'||
	    '<TH CLASS="th_sub">PhyReads</TH>';
  print(L_LINE);
  L_LINE:= '<TH CLASS="th_sub">PhyWrites</TH><TH CLASS="th_sub">FreeBuf Waits</TH>'||
           '<TH CLASS="th_sub">Wrt complete Waits</TH><TH CLASS="th_sub">Buffer Busy Waits</TH>'||
	   '<TH CLASS="th_sub">HitRatio (%)</TH></TR>';
  print(L_LINE);
  FOR R_Buff IN C_BuffP(DBID,INST_NUM,BID,EID,BS) LOOP
    L_LINE := ' <TR><TD CLASS="td_name">'||R_Buff.name||'</TD><TD ALIGN="right">'||
              R_Buff.numbufs||'</TD><TD ALIGN="right">'||
              R_Buff.hitratio||'</TD><TD ALIGN="right">'||R_Buff.gets||
	      '</TD><TD ALIGN="right">'||R_Buff.phread||'</TD><TD ALIGN="right">';
    print(L_LINE);
    L_LINE := R_Buff.phwrite||'</TD><TD ALIGN="right">'||R_Buff.fbwait||
              '</TD><TD ALIGN="right">'||R_Buff.wcwait||'</TD><TD ALIGN="right">'||
	      R_Buff.bbwait||'</TD><TD ALIGN="right">'||R_Buff.ratio||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- Instance Recovery
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="9"><A NAME="recover">Instance Recovery Statistics</A></TH></TR>'||
            ' <TR><TD COLSPAN="9" ALIGN="center">B: Begin SnapShot, E: End SnapShot</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">&nbsp;</TH><TH CLASS="th_sub">Target MTTR (s)</TH>'||
            '<TH CLASS="th_sub">Estd MTTR (s)</TH><TH CLASS="th_sub">Recovery Estd IOs</TH>'||
	    '<TH CLASS="th_sub">Actual Redo Blks</TH>';
  print(L_LINE);
  L_LINE:= '<TH CLASS="th_sub">Target Redo Blks</TH><TH CLASS="th_sub">LogFile Size Redo Blks</TH>'||
           '<TH CLASS="th_sub">Log Ckpt Timeout Redo Blks</TH>'||
	   '<TH CLASS="th_sub">Log Ckpt Interval Redo Blks</TH></TR>';
  print(L_LINE);
  FOR R_Reco IN C_Recover(DBID,INST_NUM,BID,EID) LOOP
    L_LINE := ' <TR><TD CLASS="td_name">'||R_Reco.name||'</TD><TD ALIGN="right">'||
              R_Reco.tm||'</TD><TD ALIGN="right">'||R_Reco.em||
	      '</TD><TD ALIGN="right">'||R_Reco.rei||'</TD><TD ALIGN="right">'||
	      R_Reco.arb||'</TD><TD ALIGN="right">';
    print(L_LINE);
    L_LINE := R_Reco.trb||'</TD><TD ALIGN="right">'||R_Reco.lfrb||
              '</TD><TD ALIGN="right">'||R_Reco.lctrb||'</TD><TD ALIGN="right">'||
	      R_Reco.lcirb||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- Buffer Waits
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="5"><A NAME="bufwait">Buffer Wait Statistics</A>'||
            '&nbsp;<A HREF="JavaScript:popup('||CHR(39)||'buffwaits'||CHR(39)||
            ')"><IMG SRC="help/help.gif" BORDER="0" HEIGTH="12" VALIGN="middle"></A></TH></TR>';
  print(L_LINE);
  print(' <TR><TD COLSPAN="5" ALIGN="center">Ordered by Wait Time desc, Waits desc</TD></TR>');
  L_LINE := ' <TR><TH CLASS="th_sub">Class</TH><TH CLASS="th_sub">Waits</TH>'||
            '<TH CLASS="th_sub">Tot Wait Time (s)</TH>'||
	    '<TH CLASS="th_sub">Avg Wait Time (s)</TH>'||
	    '<TH CLASS="th_sub">Waits/s</TH></TR>';
  print(L_LINE);
  FOR R_Buff IN C_BuffW(DBID,INST_NUM,BID,EID) LOOP
    L_LINE := ' <TR><TD CLASS="td_name">'||R_Buff.class||'</TD><TD ALIGN="right">'||
              R_Buff.icnt||'</TD><TD ALIGN="right">'||R_Buff.itim||
	      '</TD><TD ALIGN="right">'||R_Buff.iavg;
    print(L_LINE);
    L_LINE := '</TD><TD ALIGN="right">'||R_Buff.wps||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- PGA Aggreg Target Memory
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="9"><A NAME="pga">PGA Aggreg Target Memory Statistics</A></TH></TR>'||
            ' <TR><TD COLSPAN="9" ALIGN="center">B: Begin SnapShot, E: End SnapShot</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">&nbsp;</TH><TH CLASS="th_sub">PGA Aggreg Target (M)</TH>'||
            '<TH CLASS="th_sub">PGA in Use (M)</TH><TH CLASS="th_sub">W/A PGA in Use (M)</TH>'||
	    '<TH CLASS="th_sub">1-Pass Mem Req (M)</TH>';
  print(L_LINE);
  L_LINE:= '<TH CLASS="th_sub">% Optim W/A Execs</TH><TH CLASS="th_sub">% Non-W/A PGA Memory</TH>'||
           '<TH CLASS="th_sub">% Auto W/A PGA Mem</TH>'||
	   '<TH CLASS="th_sub">% Manual W/A PGA Mem</TH></TR>';
  print(L_LINE);
  FOR R_PGAA IN C_PGAA(DBID,INST_NUM,BID,EID) LOOP
    L_LINE := ' <TR><TD CLASS="td_name">'||R_PGAA.snap||'</TD><TD ALIGN="right">'||
              R_PGAA.pgaat||'</TD><TD ALIGN="right">'||R_PGAA.tot_pga_used||
	      '</TD><TD ALIGN="right">'||R_PGAA.tot_tun_used;
    print(L_LINE);
    L_LINE := '</TD><TD ALIGN="right">'||R_PGAA.onepr||'</TD><TD ALIGN="right">'||
              R_PGAA.opt_pct||'</TD><TD ALIGN="right">'||R_PGAA.pct_unt||
	      '</TD><TD ALIGN="right">'||R_PGAA.pct_auto_tun||
	      '</TD><TD ALIGN="right">'||R_PGAA.pct_man_tun||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);

  -- PGA Memory
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="4">PGA Memory Statistics</TH></TR>'||
            ' <TR><TD COLSPAN="4" ALIGN="center">WorkArea (W/A) memory is used for: sort, bitmap merge, and hash join ops</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">Statistic</TH><TH CLASS="th_sub">Begin (M)</TH>'||
            '<TH CLASS="th_sub">End (M)</TH><TH CLASS="th_sub">% Diff</TH></TR>';
  print(L_LINE);
  FOR R_PGAM IN C_PGAM(DBID,INST_NUM,BID,EID) LOOP
    L_LINE := ' <TR><TD CLASS="td_name">'||R_PGAM.st||'</TD><TD ALIGN="right">'||
              R_PGAM.snap1||'</TD><TD ALIGN="right">'||R_PGAM.snap2||
	      '</TD><TD ALIGN="right">'||R_PGAM.diff||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- Enqueue Activity
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="8"><A NAME="enq">Enqueue Activity</A>'||
            '&nbsp;<A HREF="JavaScript:popup('||CHR(39)||'enqwaits'||CHR(39)||
	    ')"><IMG SRC="help/help.gif" BORDER="0" HEIGTH="12" VALIGN="middle"></A></TH></TR>';
  print(L_LINE);
  L_LINE:=  ' <TR><TD COLSPAN="8" ALIGN="center">Enqueue Stats gathered prior to 9i '||
	    'should not be compared with 9i data<BR>Ordered by Waits desc, Requests desc';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">Eq</TH><TH CLASS="th_sub">Requests</TH>'||
            '<TH CLASS="th_sub">Succ Gets</TH><TH CLASS="th_sub">Failed Gets</TH>'||
	    '<TH CLASS="th_sub">PctFail</TH>';
  print(L_LINE);
  L_LINE := '<TH CLASS="th_sub">Waits</TH><TH CLASS="th_sub">Avg Wt Time (ms)'||
            '</TH><TH CLASS="th_sub">Wait Time (s)</TH></TR>';
  print(L_LINE);
  FOR R_Enq IN C_Enq(DBID,INST_NUM,BID,EID) LOOP
    L_LINE := ' <TR><TD CLASS="td_name">'||R_Enq.name||'</TD><TD ALIGN="right">'||
              R_Enq.reqs||'</TD><TD ALIGN="right">'||R_Enq.sreq||
	      '</TD><TD ALIGN="right">'||R_Enq.freq||'</TD>';
    print(L_LINE);
    L_LINE := '<TD ALIGN="right">'||R_Enq.pctfail||'</TD><TD ALIGN="right">'||
              R_Enq.waits||'</TD><TD ALIGN="right">'||R_Enq.awttm||
              '</TD><TD ALIGN="right">'||R_Enq.wttm||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- RBS Stats
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="7"><A NAME="rbs">Rollback Segments Stats</A>'||
            '&nbsp;<A HREF="JavaScript:popup('||CHR(39)||'rollstat'||CHR(39)||
	    ')"><IMG SRC="help/help.gif" BORDER="0" HEIGTH="12" '||
	    'VALIGN="middle"></A></TH></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD COLSPAN="7" ALIGN="justify">A high value for "Pct Waits" '||
	    'suggests more rollback segments may be required. ';
  print(L_LINE);
  L_LINE := 'A large number of transaction table waits also results in high values '||
            'of "buffer busy waits" for undo segment header blocks; cross-reference '||
	    'with the <A HREF="#bufwait">Buffer Wait Statistics</A> ';
  print(L_LINE);
  L_LINE := 'to confirm this correlation.<DIV ALIGN="center">RBS stats may not '||
            'be accurate between begin and end snaps when using Auto Undo '||
            'Management, as RBS may be dynamically ';
  print(L_LINE);
  L_LINE := 'created and dropped as needed</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">RBS#</TH><TH CLASS="th_sub">Trans Table Gets</TH>'||
            '<TH CLASS="th_sub">Pct Waits</TH><TH CLASS="th_sub">Undo Bytes Written</TH>'||
	    '<TH CLASS="th_sub">Wraps</TH>';
  print(L_LINE);
  L_LINE := '<TH CLASS="th_sub">Shrinks</TH><TH CLASS="th_sub">'||
            'Extends</TH></TR>';
  print(L_LINE);
  FOR R_RBS IN C_RBS(DBID,INST_NUM,BID,EID) LOOP
    L_LINE := ' <TR><TD CLASS="td_name" ALIGN="right">'||R_RBS.rbs#||'</TD><TD ALIGN="right">'||
              R_RBS.gets||'</TD><TD ALIGN="right">'||R_RBS.waits||
	      '</TD><TD ALIGN="right">'||R_RBS.writes||'</TD>';
    print(L_LINE);
    L_LINE := '<TD ALIGN="right">'||R_RBS.wraps||'</TD><TD ALIGN="right">'||
              R_RBS.shrinks||'</TD><TD ALIGN="right">'||R_RBS.extends||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);

  -- RBS Storage
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="5">Rollback Segments Storage'||
            '&nbsp;<A HREF="JavaScript:popup('||CHR(39)||'rollstat'||CHR(39)||
	    ')"><IMG SRC="help/help.gif" BORDER="0" HEIGTH="12" '||
	    'VALIGN="middle"></A></TH></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD COLSPAN="5" ALIGN="center">Optimal Size should be larger '||
	    'than Avg Active</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">RBS#</TH><TH CLASS="th_sub">Segment Size</TH>'||
            '<TH CLASS="th_sub">Avg Active</TH><TH CLASS="th_sub">Optimal Size</TH>'||
	    '<TH CLASS="th_sub">Maximum Size</TH></TR>';
  print(L_LINE);
  FOR R_RBS IN C_RBST(DBID,INST_NUM,BID,EID) LOOP
    L_LINE := ' <TR><TD CLASS="td_name" ALIGN="right">'||R_RBS.rbs#||'</TD><TD ALIGN="right">'||
              R_RBS.rssize||'</TD><TD ALIGN="right">'||R_RBS.active||
	      '</TD><TD ALIGN="right">'||R_RBS.optsize||'</TD>';
    print(L_LINE);
    L_LINE := '<TD ALIGN="right">'||R_RBS.hwmsize||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- Undo Segs Summary
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="8"><A NAME="undo">Undo Segment Summary</A>'||
            '&nbsp;<A HREF="JavaScript:popup('||CHR(39)||'undoseg'||CHR(39)||
	    ')"><IMG SRC="help/help.gif" BORDER="0" HEIGTH="12" '||
	    'VALIGN="middle"></A></TH></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD COLSPAN="8" ALIGN="center">Undo Segment block stats<BR>'||
	    'uS - unexpired Stolen, uR - unexpired Released, uU - unexpired reUsed<BR>';
  print(L_LINE);
  L_LINE := 'eS - expired Stolen, eR - expired Released, eU - expired reUsed</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">Undo TS#</TH><TH CLASS="th_sub">Undo Blocks</TH>'||
            '<TH CLASS="th_sub"># TXN</TH><TH CLASS="th_sub">Max Qry Len (s)</TH>'||
	    '<TH CLASS="th_sub">Max Tx Concurcy</TH>';
  print(L_LINE);
  L_LINE := '<TH CLASS="th_sub">Snapshot Too Old</TH><TH CLASS="th_sub">'||
            'Out of Space</TH><TH CLASS="th_sub">uS/ur/uU / eS/eR/eU</TH></TR>';
  print(L_LINE);
  FOR R_USS IN C_USS(DBID,INST_NUM,BID,EID,BTIME,ETIME) LOOP
    L_LINE := ' <TR><TD CLASS="td_name" ALIGN="right">'||R_USS.undotsn||'</TD><TD ALIGN="right">'||
              R_USS.undob||'</TD><TD ALIGN="right">'||R_USS.txcnt||
	      '</TD><TD ALIGN="right">'||R_USS.maxq||'</TD>';
    print(L_LINE);
    L_LINE := '<TD ALIGN="right">'||R_USS.maxc||'</TD><TD ALIGN="right">'||
              R_USS.snol||'</TD><TD ALIGN="right">'||R_USS.nosp||'</TD><TD ALIGN="right">'||
	      R_USS.blkst||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);

  -- Undo Segs Stat
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="8">Undo Segment Statistics'||
            '&nbsp;<A HREF="JavaScript:popup('||CHR(39)||'undoseg'||CHR(39)||
	    ')"><IMG SRC="help/help.gif" BORDER="0" HEIGTH="12" '||
	    'VALIGN="middle"></A></TH></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD COLSPAN="8" ALIGN="center">Ordered by Time desc</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">End Time</TH><TH CLASS="th_sub">Undo Blocks</TH>'||
            '<TH CLASS="th_sub"># TXN</TH><TH CLASS="th_sub">Max Qry Len (s)</TH>'||
	    '<TH CLASS="th_sub">Max Tx Concurcy</TH>';
  print(L_LINE);
  L_LINE := '<TH CLASS="th_sub">Snapshot Too Old</TH><TH CLASS="th_sub">'||
            'Out of Space</TH><TH CLASS="th_sub">uS/ur/uU / eS/eR/eU</TH></TR>';
  print(L_LINE);
  FOR R_USS IN C_UST(DBID,INST_NUM,BID,EID,BTIME,ETIME) LOOP
    L_LINE := ' <TR><TD CLASS="td_name" ALIGN="right">'||R_USS.endt||'</TD><TD ALIGN="right">'||
              R_USS.undob||'</TD><TD ALIGN="right">'||R_USS.txcnt||
	      '</TD><TD ALIGN="right">'||R_USS.maxq||'</TD>';
    print(L_LINE);
    L_LINE := '<TD ALIGN="right">'||R_USS.maxc||'</TD><TD ALIGN="right">'||
              R_USS.snol||'</TD><TD ALIGN="right">'||R_USS.nosp||'</TD><TD ALIGN="right">'||
	      R_USS.blkst||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- Latch Activity
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="7"><A NAME="latches">Latch Activity</A>'||
            '&nbsp;<A HREF="JavaScript:popup('||CHR(39)||'latches'||CHR(39)||
		')"><IMG SRC="help/help.gif" BORDER="0" HEIGTH="12" VALIGN="middle"></A></TH></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD COLSPAN="7" ALIGN="center">"Get Requests", "Pct Get Miss"'||
	    ' and "Avg Slps/Miss" are statistics for willing-to-wait '||
            'latch get requests<BR>"NoWait Requests", "Pct NoWait Miss" are ';
  print(L_LINE);
  L_LINE := 'for no-wait latch get requests<BR>"Pct Misses" for both should be '||
	    'very close to 0.0<BR>Ordered by Wait Time desc, Avg Slps/Miss, '||
            'Pct NoWait Miss desc</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">Latch</TH><TH CLASS="th_sub">Get Requests</TH>'||
            '<TH CLASS="th_sub">Pct Get Miss</TH><TH CLASS="th_sub">Avg Slps/Miss</TH>'||
	    '<TH CLASS="th_sub">Wait Time (s)</TH>';
  print(L_LINE);
  L_LINE := '<TH CLASS="th_sub">NoWait Requests</TH><TH CLASS="th_sub">'||
            'Pct NoWait Miss</TH></TR>';
  print(L_LINE);
  FOR R_LA IN C_LAA(DBID,INST_NUM,BID,EID) LOOP
    L_LINE := ' <TR><TD CLASS="td_name">'||R_LA.name||'</TD><TD ALIGN="right">'||
              R_LA.gets||'</TD><TD ALIGN="right">'||R_LA.missed||
	      '</TD><TD ALIGN="right">'||R_LA.sleeps||'</TD>';
    print(L_LINE);
    L_LINE := '<TD ALIGN="right">'||R_LA.wt||'</TD><TD ALIGN="right">'||
              R_LA.nowai||'</TD><TD ALIGN="right">'||R_LA.imiss||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);

  -- Latch Sleep Breakdown
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="7">Latch Sleep Breakdown'||
            '&nbsp;<A HREF="JavaScript:popup('||CHR(39)||'latches'||CHR(39)||
		')"><IMG SRC="help/help.gif" BORDER="0" HEIGTH="12" VALIGN="middle"></A></TH></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD COLSPAN="7" ALIGN="center">Ordered by Misses desc</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">Latch Name</TH><TH CLASS="th_sub">Get Requests</TH>'||
            '<TH CLASS="th_sub">Misses</TH><TH CLASS="th_sub">PctMiss</TH>'||
            '<TH CLASS="th_sub">Sleeps</TH>';
  print(L_LINE);
  L_LINE := '<TH CLASS="th_sub">PctSleep</TH><TH CLASS="th_sub">'||
            'Spin & Sleeps 1-&gt;4</TH></TR>';
  print(L_LINE);
  FOR R_LA IN C_LAS(DBID,INST_NUM,BID,EID) LOOP
    L_LINE := ' <TR><TD CLASS="td_name">'||R_LA.name||'</TD><TD ALIGN="right">'||
              R_LA.gets||'</TD><TD ALIGN="right">'||R_LA.misses||
	      '</TD><TD ALIGN="right">'||R_LA.pctmiss||'</TD>';
    print(L_LINE);
    L_LINE := '</TD><TD ALIGN="right">'||R_LA.sleeps||'</TD><TD ALIGN="right">'||
              R_LA.pctsleep||'<TD ALIGN="center">'||R_LA.sleep4||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);

  -- Latch Miss Sources
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="5">Latch Miss Sources'||
            '&nbsp;<A HREF="JavaScript:popup('||CHR(39)||'latches'||CHR(39)||
		')"><IMG SRC="help/help.gif" BORDER="0" HEIGTH="12" VALIGN="middle"></A></TH></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD COLSPAN="5" ALIGN="center">Only Latches with Sleeps are '||
	    'shown<BR>Ordered by Name, Sleeps desc</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">Latch Name</TH><TH CLASS="th_sub">Where</TH>'||
            '<TH CLASS="th_sub">NoWait Misses</TH><TH CLASS="th_sub">Sleeps</TH>'||
	    '<TH CLASS="th_sub">Waiter Sleeps</TH></TR>';
  print(L_LINE);
  FOR R_LA IN C_LAM(DBID,INST_NUM,BID,EID) LOOP
    L_LINE := ' <TR><TD CLASS="td_name">'||R_LA.parent||'</TD><TD>'||
              R_LA.where_from||'</TD><TD ALIGN="right">'||R_LA.nwmisses||
	      '</TD><TD ALIGN="right">'||R_LA.sleeps||'</TD>';
    print(L_LINE);
    L_LINE := '<TD ALIGN="right">'||R_LA.waiter_sleeps||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- Dictionary Cache
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="8"><A NAME="caches">Dictionary Cache</A></TH></TR>'||
            ' <TR><TD COLSPAN="8" ALIGN="center">"Pct Misses" should be very '||
	    ' low (&lt; 2% in most cases)<BR>';
  print(L_LINE);
  L_LINE := '"Cache Usage" is the number of cache entries being used<BR>'||
            '"Pct SGA" is the ratio of usage to allocated size for that cache</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">Cache</TH><TH CLASS="th_sub">Get Requests</TH>'||
            '<TH CLASS="th_sub">Pct Miss</TH><TH CLASS="th_sub">Scan Reqs</TH>'||
	    '<TH CLASS="th_sub">Pct Miss</TH>';
  print(L_LINE);
  L_LINE := '<TH CLASS="th_sub">Mod Reqs</TH><TH CLASS="th_sub">Final Usage</TH>'||
            '<TH CLASS="th_sub">Pct SGA</TH></TR>';
  print(L_LINE);
  FOR R_CA IN C_CAD(DBID,INST_NUM,BID,EID) LOOP
    L_LINE := ' <TR><TD CLASS="td_name">'||R_CA.param||'</TD><TD ALIGN="right">'||
              R_CA.gets||'</TD><TD ALIGN="right">'||R_CA.getm||
	      '</TD><TD ALIGN="right">'||R_CA.scans||'</TD>';
    print(L_LINE);
    L_LINE := '<TD ALIGN="right">'||R_CA.scanm||'</TD><TD ALIGN="right">'||
              R_CA.mods||'</TD><TD ALIGN="right">'||R_CA.usage||
	      '</TD><TD ALIGN="right">'||R_CA.sgapct||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);

  -- Library Cache
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="7">Library Cache'||
            '&nbsp;<A HREF="JavaScript:popup('||CHR(39)||'libcache'||CHR(39)||
		')"><IMG SRC="help/help.gif" BORDER="0" HEIGTH="12" VALIGN="middle"></A></TH></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD COLSPAN="7" ALIGN="center">"Pct Misses" should '||
	    'be very low (&lt; 10%), "Reloads" should not be significantly high.</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">NameSpace</TH><TH CLASS="th_sub">Get Requests</TH>'||
            '<TH CLASS="th_sub">Pct Miss</TH><TH CLASS="th_sub">Pin Reqs</TH>'||
	    '<TH CLASS="th_sub">Pct Miss</TH>';
  print(L_LINE);
  L_LINE := '<TH CLASS="th_sub">Reloads</TH><TH CLASS="th_sub">Invalidations</TH></TR>';
  print(L_LINE);
  FOR R_CA IN C_CAM(DBID,INST_NUM,BID,EID) LOOP
    L_LINE := ' <TR><TD CLASS="td_name">'||R_CA.namespace||'</TD><TD ALIGN="right">'||
              R_CA.gets||'</TD><TD ALIGN="right">'||R_CA.getm||
	      '</TD><TD ALIGN="right">'||R_CA.pins||'</TD>';
    print(L_LINE);
    L_LINE := '<TD ALIGN="right">'||R_CA.pinm||'</TD><TD ALIGN="right">'||
              R_CA.reloads||'</TD><TD ALIGN="right">'||R_CA.inv||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- SGA Memory Summary
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="2"><A NAME="sga">SGA Memory Summary</A></TH></TR>'||
            ' <TR><TD COLSPAN="2" ALIGN="center">Values at the time of the End SnapShot</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">SGA Region</TH><TH CLASS="th_sub">Size in Bytes</TH>';
  print(L_LINE);
  I1 := 0;
  FOR R_SGASum in C_SGASum(DBID,INST_NUM,BID,EID) LOOP
    I1 := I1 + R_SGASum.rawval;
    L_LINE := ' <TR><TD CLASS="td_name">'||R_SGASum.name||'</TD><TD ALIGN="right">'||
              R_SGASum.val||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := ' <TR><TD>Sum</TD><TD ALIGN="right">'||to_char(I1,'999,999,999,990')||
            '</TD></TR>'||TABLE_CLOSE;
  print(L_LINE);

  -- SGA breakdown diff
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="5">SGA BreakDown Difference</TH></TR>'||
            ' <TR><TH CLASS="th_sub">Pool</TH><TH CLASS="th_sub">Name</TH>'||
	    '<TH CLASS="th_sub">Begin Value</TH>';
  print(L_LINE);
  L_LINE := '<TH CLASS="th_sub">End Value</TH><TH CLASS="th_sub">% Diff</TH></TR>';
  print(L_LINE);
  FOR R_SGASum in C_SGABreak(DBID,INST_NUM,BID,EID) LOOP
    L_LINE := ' <TR><TD CLASS="td_name">'||R_SGASum.pool||'</TD><TD CLASS="td_name">'||
              R_SGASum.name||'</TD><TD ALIGN="right">'||R_SGASum.snap1||
	      '</TD><TD ALIGN="right">'||R_SGASum.snap2||'</TD><TD ALIGN="right">'||
	      R_SGASum.diff||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- Resource Limits
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="5"><A NAME="resourcelimits">Resource Limits</A></TH></TR>'||
            ' <TR><TD COLSPAN="5" ALIGN="center">"Current" is the time of the End SnapShot</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TH CLASS="th_sub">Resource</TH><TH CLASS="th_sub">Curr Utilization</TH>'||
	    '<TH CLASS="th_sub">Max Utilization</TH><TH CLASS="th_sub">'||
	    'Init Allocation</TH><TH CLASS="th_sub">Limit</TH></TR>';
  print(L_LINE);
  FOR R_RLim in C_RLim(DBID,INST_NUM,BID,EID) LOOP
    L_LINE := ' <TR><TD CLASS="td_name">'||R_RLim.rname||'</TD><TD ALIGN="right">'||
              R_RLim.curu||'</TD><TD ALIGN="right">'||R_RLim.maxu||
	      '</TD><TD ALIGN="right">'||R_RLim.inita||'</TD><TD ALIGN="right">'||
	      R_RLim.lim||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- Init.Ora Params
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="3"><A NAME="initora">Initialization Parameters (init.ora)</A></TH></TR>'||
            ' <TR><TH CLASS="th_sub">Parameter Name</TH><TH CLASS="th_sub">Begin Value</TH>'||
	    '<TH CLASS="th_sub">End Value (if different)</TH></TR>';
  print(L_LINE);
  FOR R_IParm in C_IParm(DBID,INST_NUM,BID,EID) LOOP
    L_LINE := ' <TR><TD CLASS="td_name">'||R_IParm.name||'</TD><TD>'||
              R_IParm.bval||'</TD><TD>'||R_IParm.eval||'</TD></TR>';
    print(L_LINE);
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);


  -- Page Ending
  L_LINE := '<HR>'||CHR(10)||TABLE_OPEN;
  print(L_LINE);
  L_LINE := '<TR><TD><DIV CLASS="small">Created by OSPRep v'||OSPVER||' &copy; 2003-2004 by '||
	    '<A HREF="http://www.qumran.org/homes/izzy/" TARGET="_blank">Itzchak Rehberg</A> '||
            '&amp; <A HREF="http://www.izzysoft.de" TARGET="_blank">IzzySoft</A></DIV></TD></TR>';
  print(L_LINE);
  print(TABLE_CLOSE);
  L_LINE := '</BODY></HTML>'||CHR(10);
  print(L_LINE);

END;
/

SPOOL off
