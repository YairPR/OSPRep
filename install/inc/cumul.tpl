<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<HTML><HEAD>
 <TITLE>Database Statistic Diagrams</TITLE>
 <LINK REL="stylesheet" TYPE="text/css" HREF="../{css}">
 <LINK REL="stylesheet" type="text/css" href="diagram.css">
 <SCRIPT TYPE="text/javascript" Language="JavaScript">
   var maxval = 0;
   if ((document.layers)&&(history.length==1)) location.href=location.href+"#";
 </SCRIPT>
 <SCRIPT TYPE="text/javascript" Language="JavaScript" src="diagram.js"></SCRIPT>
 <SCRIPT TYPE="text/javascript" Language="JavaScript" src="common.js"></SCRIPT>
</HEAD>
<BODY>
<DIV STYLE="position:absolute; top:0"></DIV>
<SCRIPT TYPE="text/javascript" Language="JavaScript">//<!--
document.write('<TABLE BORDER="0" CELLPADDING="2" CELLSPACING="2" WIDTH="620" ALIGN="center"><TR>');
document.write('<TH>Timeouts (cumulative) on '+parent.sid+'<\/TH><\/TR>');
document.write('<TR><TD ALIGN="center"><DIV CLASS="small">Begin Snapshot: '+parent.bid+' ('+parent.btime+')<BR>');
document.write('End Snapshot: '+parent.eid+' ('+parent.etime+')<\/DIV><\/TD><\/TR>');
document.write('<TR><TH CLASS="th_sub" ALIGN="center">'+parent.dname+'<\/TH><\/TR><\/TABLE>');

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
 for (i=bid,k=bid; i<=eid; i=i+inc) {
   if (isNaN(arr[i])) {
     k = k + inc;
     continue;
   }
   if (i>bid) {
     if ( isNaN(arr[k]) ) {
       delta = 0;
     } else {
       delta = (arr[k] - arr[i]) / parts;
     }
     for (f=0;f<parts;f++) {
       x = D.ScreenX(i - f/parts);
       j = D.ScreenY(arr[i] + f*delta);
       new Pixel(x, j, col);
     }
     k++;
   } else {
     x = D.ScreenX(i);
     j = D.ScreenY(arr[i]);
     new Pixel(x, j, col);
   }
 }
}

document.open();
var D=new Diagram();
maxval = parent.dstat[eid];
if ( isNaN(maxval) || maxval == 0 ) maxval = 1;
mkdiag();
mkline(parent.dstat,'#0000FF');
document.close();

//--></SCRIPT>
<DIV ALIGN="center">
<DIV STYLE="margin-top:380">
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
 <OPTION VALUE="ckpt">Checkpoint Incomplete</OPTION>
 <OPTION VALUE="redoreq">Redo Log Space Requests</OPTION>
 <OPTION VALUE="redoret">Redo Buffer Allocation Retries</OPTION>
</SELECT>
</TD></TR></TABLE><BR>
<TABLE ALIGN="center" BORDER="1">
<TR><TD ALIGN="center" CLASS="small">
<SCRIPT TYPE="text/javascript" LANGUAGE="JavaScript">//<!--
  document.write('<IMG SRC="..\/w3c.jpg" ALT="w3c" WIDTH="14" HEIGHT="14" ALIGN="middle" STYLE="margin-right:3px"><SPAN CLASS="small">Created by OSPRep v'+parent.vers+' &copy; 2003-2007 by Itzchak Rehberg &amp; <A HREF="http://www.izzysoft.de/" TARGET="_blank">IzzySoft<\/A><\/SPAN><IMG SRC="..\/islogo.gif" ALT="IzzySoft" WIDTH="14" HEIGHT="14" ALIGN="middle" STYLE="margin-left:3px">');
//--></SCRIPT>
</TD></TR>
</TABLE>
</DIV>
</DIV>
</BODY></HTML>