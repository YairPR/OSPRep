<html>
<head>
<title>Database Statistic Diagrams</title>
<LINK REL="stylesheet" TYPE="text/css" HREF="../{css}">
<link rel=stylesheet type="text/css" href="diagram.css">
<SCRIPT Language="JavaScript">
 var maxval = 0;
 if ((document.layers)&&(history.length==1)) location.href=location.href+"#";
</SCRIPT>
<SCRIPT Language="JavaScript" src="diagram.js"></SCRIPT>
<SCRIPT Language="JavaScript" src="common.js"></SCRIPT>
</head>
<body>
<DIV STYLE="position:absolute; top:0"></DIV>
<TABLE BORDER="0" CELLPADDING="2" CELLSPACING="2" WIDTH="620" ALIGN="center"><TR>
<SCRIPT Language="JavaScript">
//<!--
document.write('<TH>Timeouts per SnapShot (cumulative) on '+parent.sid+'</TH></TR>');
document.write('<TR><TD ALIGN="center"><DIV CLASS="small">Begin Snapshot: '+parent.bid+' ('+parent.btime+')<BR>');
document.write('End Snapshot: '+parent.eid+' ('+parent.etime+')</DIV></TD></TR>');
document.write('<TR><TH CLASS="th_sub" ALIGN="center">'+parent.dname+'</TH></TR></TABLE>');

// Create a graph (Array, StartElem, Color)
function mkline(arr,col) {
 // parts: connect dots (fill the gaps with calculated delta for x pieces)
 if ( (eid - bid) > 620 ) {
   parts = 1;
   inc   = Math.floor((eid - bid)/620);
 } else {
   parts = Math.ceil(620/(eid - bid));
   inc   = 1;
 }
 for (i=bid,k=bid; i<eid; i=i+inc) {
   if (isNaN(arr[i])) {
     k++;
     continue;
   }
   snapcount = i - dbup_id +1;
   if (i>bid) {
     delta = (arr[k] - arr[i]) / parts;
     for (f=0;f<parts;f++) {
       snapcount = snapcount + f/parts;
       x = D.ScreenX(i - f/parts);
       j = D.ScreenY( (arr[i] + f*delta) / snapcount );
       new Pixel(x, j, col);
     }
     k++;
   } else {
     x = D.ScreenX(i);
     j = D.ScreenY(arr[i]/snapcount);
     new Pixel(x, j, col);
   }
 }
}

function maxDelta(arr) {
 maxval = 0;
 for (i=bid;i<eid;i++) {
   if (isNaN(arr[i])) {
     i++;
     continue;
   }
   if ( !isNaN(arr[i]/(i-dbup_id+1)) )
     maxval = Math.max(maxval,arr[i]/(i-dbup_id+1));
 }
 if (maxval == 0 || isNaN(maxval)) maxval = 1;
}


document.open();
var D=new Diagram();
maxDelta(parent.dstat);
mkdiag();
mkline(parent.dstat,'#0000FF');
document.close();

//--></SCRIPT>
<DIV ALIGN="center">
<DIV
 STYLE="margin-top:380">
<TABLE BORDER="1" ALIGN="center">
<TR><TD ALIGN="center">
<SELECT NAME="stat" onChange="drawStat(this.value)">
 <OPTION VALUE="-">-- Select Statistic: --</OPTION>
 <OPTION VALUE="enq">Enqueues</OPTION>
 <OPTION VALUE="freebuff">Free Buffer Waits</OPTION>
 <OPTION VALUE="busybuff">Buffer Busy Waits</OPTION>
 <OPTION VALUE="fileseq">DB file Sequential Reads</OPTION>
 <OPTION VALUE="filescat">DB file Scattered Reads</OPTION>
 <OPTION VALUE="lgwr">LGWR Wait for Redo Copy</OPTION>
 <OPTION VALUE="lgsw">Log File Switch Completion</OPTION>
 <OPTION VALUE="redoreq">Redo Log Space Requests</OPTION>
</SELECT>
</TD></TR></TABLE><BR>
<TABLE ALIGN="center" BORDER="1">
<TR><TD ALIGN="center" CLASS="small">
<SCRIPT LANGUAGE="JavaScript">//<!--
  document.write('Created by OSPRep v'+parent.vers+' &copy; 2003-2004 by <A HREF="http://www.qumran.org/homes/izzy/" TARGET="_blank">Itzchak Rehberg</A> &amp; <A HREF="http://www.izzysoft.de" TARGET="_blank">IzzySoft</A>');
//--></SCRIPT>
</TD></TR>
</TABLE>
</DIV>
</DIV>
</body>
</html>