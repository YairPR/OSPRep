  -- SnapShot Info
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="6"><A NAME="snapinfo">SnapShot Info</A></TH></TR>'||CHR(10)||
            ' <TR><TH CLASS="th_sub">&nbsp;</TH><TH CLASS="th_sub">Snap ID</TH>';
  print(L_LINE);
  L_LINE := ' <TH CLASS="th_sub">Snap Time</TH><TH CLASS="th_sub">Sessions</TH>'||
            '<TH CLASS="th_sub">Curs/Sess</TH><TH CLASS="th_sub">Comment</TH></TR>';
  print(L_LINE);
  FOR Rec_SnapInfo IN C_SnapInfo(DBID,INST_NUM,BID,EID) LOOP
    L_LINE := ' <TR><TD>Start</TD><TD ALIGN="right">'||Rec_SnapInfo.begin_snap_id||'</TD><TD>'||
              Rec_SnapInfo.begin_snap_time||'</TD><TD ALIGN="right">'||BLOG||'</TD><TD ALIGN="right">'||
	      to_char(BOCUR/BLOG,'9,990.00')||'<TD>'||Rec_SnapInfo.begin_snap_comment||'</TD></TR>';
    print(L_LINE);
    L_LINE := ' <TR><TD>End</TD><TD ALIGN="right">'||Rec_SnapInfo.end_snap_id||'</TD><TD>'||
              Rec_SnapInfo.end_snap_time||'</TD><TD ALIGN="right">'||ELOG||'</TD><TD ALIGN="right">'||
	      to_char(EOCUR/ELOG,'9,990.00')||'<TD>'||Rec_SnapInfo.end_snap_comment||'</TD></TR>';
    print(L_LINE);
    L_LINE := ' <TR><TD COLSPAN="6" ALIGN="center">Elapsed: '||Rec_SnapInfo.elapsed||
              ' min</TD></TR>';
    print(L_LINE);
    ELA  := Rec_SnapInfo.ela;
    EBGT := Rec_SnapInfo.ebgt;
    EDRT := Rec_SnapInfo.edrt;
    EET  := Rec_SnapInfo.eet;
    EPC  := Rec_SnapInfo.epc;
    BTIME:= Rec_SnapInfo.begin_snap_time;
    ETIME:= Rec_SnapInfo.end_snap_time;
  END LOOP;
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- Cache Sizes
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="2"><A NAME="cachesizes">Cache Sizes (End)</A></TH></TR>'||CHR(10)||
            ' <TR><TH CLASS="th_sub">Cache</TH><TH CLASS="th_sub">Size</TH></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD>Buffer Cache</TD><TD ALIGN="right">'||to_char(round(BC/1024/1024),'999,999')||' M</TD></TR>'||
            ' <TR><TD>Std Block Size</TD><TD ALIGN="right">'||to_char(round(BS/1024),'999,999')||' K</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD>Shared Pool Size</TD><TD ALIGN="right">'||to_char(round(SP/1024/1024),'999,999')||' M</TD></TR>'||
            ' <TR><TD>Log Buffer</TD><TD ALIGN="right">'||to_char(round(LB/1024),'999,999')||' K</TD></TR>';
  print(L_LINE);
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- Load Profile
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="3"><A NAME="loads">Load Profile</A></TH></TR>'||CHR(10)||
            ' <TR><TH CLASS="th_sub">&nbsp;</TH><TH CLASS="th_sub">Per Second</TH><TH CLASS="th_sub">Per Transaction</TH></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD CLASS="td_name">Redo Size</TD><TD ALIGN="right">'||
            to_char(round(RSIZ/ELA,2),'99,999,999,990.00')||
            '</TD><TD ALIGN="right">'||
	    to_char(round(RSIZ/TRAN,2),'9,999,990.00')||'</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD CLASS="td_name">Logical Reads</TD><TD ALIGN="right">'||
            to_char(round(GETS/ELA,2),'99,999,999,990.00')||
            '</TD><TD ALIGN="right">'||
	    to_char(round(GETS/TRAN,2),'9,999,990.00')||'</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD CLASS="td_name">Block Changes</TD><TD ALIGN="right">'||
            to_char(round(CHNG/ELA,2),'99,999,999,990.00')||
            '</TD><TD ALIGN="right">'||
	    to_char(round(CHNG/TRAN,2),'9,999,990.00')||'</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD CLASS="td_name">Physical Reads</TD><TD ALIGN="right">'||
            to_char(round(PHYR/ELA,2),'99,999,999,990.00')||
            '</TD><TD ALIGN="right">'||
	    to_char(round(PHYR/TRAN,2),'9,999,990.00')||'</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD CLASS="td_name">Physical Writes</TD><TD ALIGN="right">'||
            to_char(round(PHYW/ELA,2),'99,999,999,990.00')||
            '</TD><TD ALIGN="right">'||
	    to_char(round(PHYW/TRAN,2),'9,999,990.00')||'</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD CLASS="td_name">User Calls</TD><TD ALIGN="right">'||
            to_char(round(UCAL/ELA,2),'99,999,999,990.00')||
            '</TD><TD ALIGN="right">'||
	    to_char(round(UCAL/TRAN,2),'9,999,990.00')||'</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD CLASS="td_name">Parses</TD><TD ALIGN="right">'||
            to_char(round(PRSE/ELA,2),'99,999,999,990.00')||
            '</TD><TD ALIGN="right">'||
	    to_char(round(PRSE/TRAN,2),'9,999,990.00')||'</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD CLASS="td_name">Hard Parses</TD><TD ALIGN="right">'||
            to_char(round(HPRS/ELA,2),'99,999,999,990.00')||
            '</TD><TD ALIGN="right">'||
	    to_char(round(HPRS/TRAN,2),'9,999,990.00')||'</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD CLASS="td_name">Sorts</TD><TD ALIGN="right">'||
            to_char(round((SRTM+SRTD)/ELA,2),'99,999,999,990.00')||
            '</TD><TD ALIGN="right">'||
	    to_char(round((SRTM+SRTD)/TRAN,2),'9,999,990.00')||'</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD CLASS="td_name">Logons</TD><TD ALIGN="right">'||
            to_char(round(LOGC/ELA,2),'99,999,999,990.00')||
            '</TD><TD ALIGN="right">'||
	    to_char(round(LOGC/TRAN,2),'9,999,990.00')||'</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD CLASS="td_name">Executes</TD><TD ALIGN="right">'||
            to_char(round(EXE/ELA,2),'99,999,999,990.00')||
            '</TD><TD ALIGN="right">'||
	    to_char(round(EXE/TRAN,2),'9,999,990.00')||'</TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD CLASS="td_name">Transactions</TD><TD ALIGN="right">'||
            to_char(round(TRAN/ELA,2),'99,999,999,990.00')||
            '</TD><TD ALIGN="right">&nbsp;</TD></TR>';
  print(L_LINE);
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

  -- Instance Efficiency Percentages
  L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="3"><A NAME="efficiency">Instance Efficiency Percentages (Target: 100%)</A></TH></TR>'||CHR(10)||
            ' <TR><TH CLASS="th_sub">Event</TH><TH CLASS="th_sub">Efficiency (%)</TH>'||
	    '<TH CLASS="th_sub">Comment</TH></TR>';
  print(L_LINE);
  S2 := alert_lt_warn(100*(1-BFWT/GETS),AR_IE_BUFFNW,WR_IE_BUFFNW);
  L_LINE := ' <TR><TD><DIV STYLE="width:13em">Buffer Nowait</DIV></TD><TD ALIGN="right"'||
            S2||'>'||to_char(round(100*(1-BFWT/GETS),2),'990.00');
  print(L_LINE);
  L_LINE := '</TD><TD><DIV ALIGN="justify">If this ratio is low, check the '||
            '<A HREF="#bufwait">Buffer Wait Stats</A> section for more detail '||
	    'on which type of block is being contended for.</DIV></TD></TR>';
  print(L_LINE);
  IF RENT = 0
  THEN S1 := '&nbsp;';
  ELSE S1 := to_char(round(100*(1-BFWT/GETS),2),'990.00');
       S2 := alert_lt_warn(100*(1-BFWT/GETS),AR_IE_REDONW,WR_IE_REDONW);
  END IF;
  L_LINE := ' <TR><TD>Redo Nowait</TD><TD ALIGN="right"'||S2||'>'||S1||
            '</TD><TD><DIV ALIGN="justify">A value close to 100% indicates minimal '||
	    'time spent waiting for redo logs ';
  print(L_LINE);
  L_LINE := 'to become available, either because the logs are not filling up '||
            'very often or because the database is able to switch to a new log '||
	    'quickly whenever the current log fills up.</DIV></TD></TR>';
  print(L_LINE);
  S2 := alert_lt_warn(100*(1-(PHYR-PHYRD-PHYRDL)/GETS),AR_IE_BUFFHIT,WR_IE_BUFFHIT);
  L_LINE := ' <TR><TD>Buffer Hit</TD><TD ALIGN="right"'||S2||'>'||
            to_char(round(100*(1-(PHYR-PHYRD-PHYRDL)/GETS),2),'990.00');
  print(L_LINE);
  L_LINE := '</TD><TD><DIV ALIGN="justify">A low buffer hit ratio does not necessarily '||
            'mean the cache is too small: it may very well be that potentially '||
	    'valid full-table-scans are artificially ';
  print(L_LINE);
  L_LINE := 'reducing what is otherwise a good ratio. A too-small buffer cache '||
            'can sometimes be identified by the appearance of write complete waits '||
	    'event indicating hot blocks ';
  print(L_LINE);
  L_LINE := '(i.e. blocks still being modified) are aging out of the cache while '||
            'they are still needed; check the <A HREF="#waitevents">Wait Events</A> '||
	    'list for evidence of this event.</DIV></TD></TR>';
  print(L_LINE);
  IF (SRTM+SRTD) = 0
  THEN S1 := '&nbsp;';
  ELSE S1 := to_char(round(100*SRTM/(SRTD+SRTM),2),'990.00');
       S2 := alert_lt_warn(100*SRTM/(SRTD+SRTM),AR_IE_IMSORT,WR_IE_IMSORT);
  END IF;
  L_LINE := ' <TR><TD>In-Memory Sort</TD><TD ALIGN="right"'||S2||'>'||S1||
            '</TD><TD><DIV ALIGN="justify">A too low ratio indicates too many '||
	    'disk sorts appearing. One possible ';
  print(L_LINE);
  L_LINE := 'solution could be increasing the sort area/SGA size.</DIV></TD></TR>';
  print(L_LINE);
  S2 := alert_lt_warn(100*LHTR,AR_IE_LIBHIT,WR_IE_LIBHIT);
  L_LINE := ' <TR><TD>Library Hit</TD><TD ALIGN="right"'||S2||'>'||
            to_char(round(100*LHTR,2),'990.00');
  print(L_LINE);
  L_LINE := '</TD><TD><DIV ALIGN="justify">A low library hit ratio could imply that '||
            'SQL is prematurely aging out of a too-small shared pool, or that '||
	    'non-shareable SQL is being used. ';
  print(L_LINE);
  L_LINE := 'If the soft parse ratio is also low, check whether there is a '||
            'parsing issue.</DIV></TD></TR>';
  print(L_LINE);
  S2 := alert_lt_warn(100*(1-HPRS/PRSE),AR_IE_SOFTPRS,WR_IE_SOFTPRS);
  L_LINE := ' <TR><TD>Soft Parse</TD><TD ALIGN="right"'||S2||'>'||
            to_char(round(100*(1-HPRS/PRSE),2),'990.00')||'</TD><TD><DIV ALIGN="justify">'||
            'When the <A HREF="JavaScript:popup('||CHR(39)||'softparse'||CHR(39)||
	    ')">soft parse</A> ';
  print(L_LINE);
  L_LINE := ' ratio falls much below 80%, investigate whether you can share '||
            'SQL by using bind variables or force cursor sharing. But before '||
            'drawing any conclusions, compare the soft parse ';
  print(L_LINE);
  L_LINE := 'ratio against the actual hard and soft parse rates shown in the '||
            '<A HREF="#loads">Loads Profile</A>. Furthermore, investigate the '||
            'number of <I>Parse CPU to Parse Elapsed</I> below.</DIV></TD></TR>';
  print(L_LINE);
  L_LINE := ' <TR><TD>Execute to Parse</TD><TD ALIGN="right">'||
            to_char(round(100*(1-PRSE/EXE),2),'990.00')||
	    '</TD><TD>A low value here indicates that there is no much '||
	    're-usable SQL. See <I>Soft Parse</I> for possible actions.</TD></TR>';
  print(L_LINE);
  S2 := alert_lt_warn(100*(1-LHR),AR_IE_LAHIT,WR_IE_LAHIT);
  L_LINE := ' <TR><TD>Latch Hit</TD><TD ALIGN="right"'||S2||'>'||
            to_char(round(100*(1-LHR),2),'990.00');
  print(L_LINE);
  L_LINE := '</TD><TD ALIGN="justify">A low value for this ratio indicates a '||
            'latching problem, whereas a high value is generally good. However, '||
	    'a high latch hit ratio can artificially mask a low ';
  print(L_LINE);
  L_LINE := 'get rate on a specific latch. Cross-check this value with the '||
            '<A HREF="#top5wait">Top 5 Wait Events</A> to see if latch free is '||
	    'in the list, and refer to the ';
  print(L_LINE);
  L_LINE := '<A HREF="#latches">Latch</A> sections of this report.</TD></TR>';
  print(L_LINE);
  IF PRSELA = 0
  THEN S1 := '&nbsp;';
  ELSE S1 := to_char(round(100*PRSCPU/PRSELA,2),'990.00');
       S3 := alert_lt_warn(100*PRSCPU/PRSELA,AR_IE_PRSC2E,WR_IE_PRSC2E);
  END IF;
  IF TCPU = 0
  THEN S2 := '&nbsp;';
  ELSE S2 := to_char(round(100*(1-(PRSCPU/TCPU)),2),'990.00');
  END IF;
  L_LINE := ' <TR><TD>Parse CPU to Parse Elapsed</TD><TD ALIGN="right"'||S3||'>'||
            S1||'</TD><TD>See <I>Soft Parse</I> above.</TD></TR>'||
            ' <TR><TD>Non-Parse CPU</TD><TD ALIGN="right">'||
            S2||'</TD><TD>&nbsp;</TD></TR>';
  print(L_LINE);
  L_LINE := TABLE_CLOSE;
  print(L_LINE);
  print('<HR>');

