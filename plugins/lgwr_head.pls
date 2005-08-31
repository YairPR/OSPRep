
  PROCEDURE lgwr IS
    pcomment VARCHAR2(2000);
    FUNCTION dbstat(first IN VARCHAR2) RETURN NUMBER IS
      erg NUMBER;
      BEGIN
        SELECT a.val INTO erg
          FROM (
           SELECT decode(e.name,first,e.value) - decode (b.name,first,b.value) val
            FROM stats$sysstat b, stats$sysstat e
           WHERE b.snap_id = BID
             AND e.snap_id = EID
             AND b.dbid    = DB_ID
             AND e.dbid    = DB_ID
             AND b.dbid    = e.dbid
             AND b.instance_number = INST_NUM
             AND e.instance_number = INST_NUM
             AND b.instance_number = e.instance_number
             AND decode(e.name,first,e.value) IS NOT NULL
             AND decode(b.name, first,b.value) IS NOT NULL ) a;
        RETURN erg;
      EXCEPTION
        WHEN OTHERS THEN RETURN 0;
      END;
    FUNCTION dbstats(first IN VARCHAR2, last IN VARCHAR2) RETURN NUMBER IS
      erg NUMBER;
      BEGIN
        SELECT ( a.val / b.val ) INTO erg
          FROM (
           SELECT decode(e.name,first,e.value) - decode (b.name,first,b.value) val
            FROM stats$sysstat b, stats$sysstat e
           WHERE b.snap_id = BID
             AND e.snap_id = EID
             AND b.dbid    = DB_ID
             AND e.dbid    = DB_ID
             AND b.dbid    = e.dbid
             AND b.instance_number = INST_NUM
             AND e.instance_number = INST_NUM
             AND b.instance_number = e.instance_number
             AND decode(e.name,first,e.value) IS NOT NULL
             AND decode(b.name, first,b.value) IS NOT NULL ) a, (
           SELECT decode(e.name,last,e.value) - decode (b.name,last,b.value) val
            FROM stats$sysstat b, stats$sysstat e
           WHERE b.snap_id = BID
             AND e.snap_id = EID
             AND b.dbid    = DB_ID
             AND e.dbid    = DB_ID
             AND b.dbid    = e.dbid
             AND b.instance_number = INST_NUM
             AND e.instance_number = INST_NUM
             AND b.instance_number = e.instance_number
             AND decode(e.name,last,e.value) IS NOT NULL
             AND decode(b.name, last,b.value) IS NOT NULL ) b
          WHERE b.val > 0;
        RETURN erg;
      EXCEPTION
        WHEN OTHERS THEN RETURN 0;
      END;
    PROCEDURE writerow(val1 IN VARCHAR2, val2 IN VARCHAR2, val3 IN VARCHAR2) IS
      BEGIN
        L_LINE := ' <TR><TD CLASS="td_name" STYLE="width:22em">'||val1||'</TD>'||
                  '<TD ALIGN="right">'||val2||'</TD><TD ALIGN="justify">'||val3||'</TD></TR>';
        print(L_LINE);
      EXCEPTION
        WHEN OTHERS THEN NULL;
      END;
    FUNCTION numformat (val IN NUMBER) RETURN VARCHAR2 IS
      BEGIN
        RETURN to_char(val,'9,999,999,990');
      EXCEPTION
        WHEN OTHERS THEN RETURN NULL;
      END;
    FUNCTION decformat (val IN NUMBER) RETURN VARCHAR2 IS
      BEGIN
        RETURN to_char(round(val,2),'9,999,999,990.00');
      EXCEPTION
        WHEN OTHERS THEN RETURN NULL;
      END;
    PROCEDURE swrite(first IN VARCHAR2, scomment IN VARCHAR2) IS
      erg VARCHAR2(20);
      BEGIN
        erg := numformat( dbstat(first));
        writerow(first,erg,scomment);
      EXCEPTION
        WHEN OTHERS THEN NULL;
      END;
    BEGIN
      L_LINE := TABLE_OPEN||'<TR><TH COLSPAN="3"><A NAME="lgwr"></A>Log Writer Statistics</TH></TR>'||
                ' <TR><TH CLASS="th_sub">Statistic</TH><TH CLASS="th_sub">Value</TH>'||
                '<TH CLASS="th_sub">Comment</TH></TR>';
      print(L_LINE);
      pcomment := 'The active logfile had been full, and Oracle had waited for disk space to '||
                  'be allocated for the redolog entries by performing log switches. High values '||
                  'indicate high amount of log switches.';
      swrite('redo log space requests',pcomment);
      I1 := round ( dbstat('redo log space requests') / (ELA/3600),2 );
      S1 := to_char(I1,'9,990.00');
      writerow('redo log space requests / h',S1,'This number should be as low as possible. '||
               'When encountering high values here, the reason could be e.g. one of these:<UL>'||
               '<LI>too small log files</LI><LI>not enough redo log groups</LI><LI>too many '||
               'checkpoints / log file switches (also indicated by high redo wastage, see below)'||
               '</LI></UL>');
      pcomment := 'Total wait time waiting for completion of redo log space requests in 1/10 ms. '||
                  'High values cause <i>log file switch...</i> related wait events. If there are '||
                  'many processes waiting for log switch completion, it is possible to see '||
                  '<i>log buffer space wait</i> event after log switch is completed. Since redo '||
                  'generation is disabled during log switch, there can be high volume of redo '||
                  'generation after log switch. This may cause <i>log buffer space</i> wait event.';
      swrite('redo log space wait time',pcomment);
      pcomment := 'ms/request. If this ratio is high, check the followings:<UL><LI>Increase the size of '||
                  'redolog files and/or add new redolog groups</LI><LI>Ensure that log switches '||
                  'occurring not more frequent than around all 20-30 minutes</LI></UL>';
      I1 := round ( (dbstat('redo log space wait time')/10) / dbstat('redo log space requests'), 2);
      S1 := to_char(I1,'9,990.00');
      writerow('redo log space wait time / redo log space requests',S1,pcomment);
      pcomment := 'Percentage of redo bytes written "unnecessarily" (<i>redo wastage</i> '||
                  'describes the log buffer blocks had been needed to be flushed out to disk before '||
                  'they were completely full, which does not mean a problem: high values just '||
                  'indicate high LGWR activity). Naturally, this should be very low; if it '||
                  'exceeds 20..30% plus you have many log writer wait events, you should check '||
                  'for unnecessary checkpoints/log switches.';
      I1 := round( dbstat('redo wastage') * 100 / dbstat('redo size'),2);
      S1 := to_char(I1,'9,990.00');
      S2 := alert_gt_warn(I1,AR_RWP,WR_RWP);
      L_LINE := ' <TR><TD CLASS="td_name" STYLE="width:22em">redo wastage percentage</TD>'||
                '<TD ALIGN="right"'||S2||'>'||S1||'%</TD><TD ALIGN="justify">'||pcomment||'</TD></TR>';
      print(L_LINE);
      pcomment := 'Changes to redolog buffer had been flushed out to disk immediately such as '||
                  '<code>COMMIT</code> / <code>ROLLBACK</code>.';
      swrite('redo synch writes',pcomment);
      pcomment := 'Elapsed time of all redo synch writes in 1/10 ms. High values cause '||
                  '<i>log file sync</i> wait event.';
      swrite('redo synch time',pcomment);
      pcomment := 'Milliseconds per write. If this ratio is high, check the followings:<UL>'||
                  '<LI>Do not set <code>LOG_BUFFER</code> to value higher than 1Mb. High '||
                  '<i>LOG_BUFFER</i> parameter may cause <i>log file sync</i> wait event. This '||
                  'impacts <code>COMMIT</code> / <code>ROLLBACK</code> response time, and possibly '||
                  'DBWR performance.</LI><LI>Reduce <code>COMMIT</code> / <code>ROLLBACK</code> '||
                  'frequency.</LI><LI>If there are other redolog related wait events, check them. '||
                  'They may indirectly cause <i>log file sync</i> wait event.';
      I1 := round( (dbstat('redo synch time') / 10) * 1000 / dbstat('redo synch writes'), 2 );
      S1 := to_char(I1,'9,990.00');
      writerow('redo synch time / redo synch writes',S1,pcomment);
      pcomment := 'Number of retries per hour necessary to allocate space in the redo buffer. '||
                  'Retries are needed either because the redo writer has fallen behind or because '||
                  'an event such as a log switch is occurring.';
      I1 := dbstat('redo buffer allocation retries') / (ELA/3600);
      S1 := to_char(I1,'9,990.00');
      writerow('redo buffer allocation retries / h',S1,pcomment);
      S1 := decformat(dbstats('redo blocks written','redo writes'));
      writerow('redo blocks written / redo writes',S1,'Number of blocks per write');
      I1 := dbstat('redo size') / (ELA/60);
      S1 := format_fsize(I1)||'/min';
      writerow('redo emergence',S1,'How much redo information is written on average '||
               'during the snapshot interval given.');
      I1 := dbstat('redo write time') /(10*1000);
      I2 := round(I1 * 100 / ELA,2);
      S2 := decformat(I2)||'%';
      writerow('redo time used',S2,'Rate of time spent for writing redo information '||
               'during the snapshot interval given. This value should be close to 0%.');
      I1 := dbstat('redo size');
      S1 := format_fsize(I1);
      writerow('redo size',S1,'Total amount of redo generated');
      print(TABLE_CLOSE);
    EXCEPTION
      WHEN OTHERS THEN print(TABLE_CLOSE||SQLERRM||'<br>'||I3||' ('||S3||')');
    END;

