
  PROCEDURE reco IS
    CURSOR C_Recover (db_id IN NUMBER, instnum IN NUMBER, bid IN NUMBER, eid IN NUMBER) IS
      SELECT 'B' name,
             to_char(target_mttr,'999,999') tm,
             to_char(estimated_mttr,'999,999') em,
	     to_char(recovery_estimated_ios,'9,999,999') rei,
             to_char(actual_redo_blks,'99,999,999') arb,
	     to_char(target_redo_blks,'99,999,999') trb,
             to_char(log_file_size_redo_blks,'99,999,999') lfrb,
	     to_char(log_chkpt_timeout_redo_blks,'99,999,999') lctrb,
             to_char(log_chkpt_interval_redo_blks,'99,999,999,999') lcirb,
	     snap_id snid
        FROM stats$instance_recovery b
       WHERE b.snap_id = bid
         AND b.dbid    = db_id
         AND b.instance_number = instnum
      UNION SELECT 'E' name,
             to_char(target_mttr,'999,999') tm,
             to_char(estimated_mttr,'999,999') em,
	     to_char(recovery_estimated_ios,'9,999,999') rei,
             to_char(actual_redo_blks,'99,999,999') arb,
	     to_char(target_redo_blks,'99,999,999') trb,
             to_char(log_file_size_redo_blks,'99,999,999') lfrb,
	     to_char(log_chkpt_timeout_redo_blks,'99,999,999') lctrb,
             to_char(log_chkpt_interval_redo_blks,'99,999,999,999') lcirb,
	     snap_id snid
        FROM stats$instance_recovery e
       WHERE e.snap_id = eid
         AND e.dbid    = db_id
         AND e.instance_number = instnum
       ORDER BY snid;
    BEGIN
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
      print(TABLE_CLOSE);
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;
