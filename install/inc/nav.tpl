<html>
<head>
<title>Database Statistic Diagrams: Navigation</title>
<SCRIPT Language="JavaScript">
  function init(mode) {
    parent.dtype = mode;
    switch(mode) {
      case "cumul" :
      case "delta" : parent.dstat = parent.enq;
                     parent.dname = "Enqueues";
		     break;
      case "ratio" : parent.dstat = parent.enqper;
                     parent.dname = "Pct Library Cache HitMisses";
		     break;
    }
  }
</SCRIPT>
<LINK REL="stylesheet" TYPE="text/css" HREF="../{css}">
</HEAD><BODY>
<TABLE BORDER="0" CELLPADDING="2" CELLSPACING="2" ALIGN="center" STYLE="margin-top:30">
 <TR><TH CLASS="th_sub">Stats</TH></TR>
 <TR><TD><A HREF="cumul.html" TARGET="chart" onClick="init('cumul')">Cumul</A></TD></TR>
 <TR><TD><A HREF="delta.html" TARGET="chart" onClick="init('delta')">Delta</A></TD></TR>
 <TR><TD><A HREF="ratio.html" TARGET="chart" onClick="init('ratio')">Ratio</A></TD></TR>
</TABLE>
</body>
</html>