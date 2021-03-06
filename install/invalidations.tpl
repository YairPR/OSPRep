<HTML><HEAD>
 <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=iso-8859-15"/>
 <LINK REL='stylesheet' TYPE='text/css' HREF='../{css}'>
 <TITLE>OraHelp</TITLE>
</HEAD><BODY>

<TABLE WIDTH="95%" ALIGN="center"><TR><TD>
 <P>Invalidations of SQL cursors can have different causes:</P>
 <UL>
  <LI>Statistics for dependent objects have been changed
      (<CODE>ANALYZE TABLE/INDEX</CODE>, <CODE>dbms_stats.gather_statistics</CODE>,...)</LI>
  <LI>Definition (DDL) of dependent objects have changed
      (<CODE>ALTER TABLE/INDEX</CODE>, <CODE>COMMENT ON</CODE>,
      <CODE>GRANT/REVOKE</CODE>, <CODE>TRUNCATE TABLE</CODE>,...)</LI>
  <LI>The Shared Pool has been flushed (<CODE>ALTER SYSTEM FLUSH SHARED POOL</CODE>)</LI>
 </UL>
 <P>None of the mentioned actions are typically run frequently on a production
 database - so if a cursor encounters many invalidations, it usually is
 worth some investigation.</P>
</TD></TR></TABLE>

<SCRIPT TYPE="text/javascript" LANGUAGE="JavaScript">//<!--
  if ( opener != null && opener.version != '' && opener.version != null )
    version = 'v'+opener.version;
  else version = '';
  document.write('<DIV ALIGN="center" STYLE="margin-top:3px"><IMG SRC="..\/w3c.jpg" ALT="w3c" WIDTH="14" HEIGHT="14" ALIGN="middle" STYLE="margin-right:3px"><SPAN CLASS="small" ALIGN="middle">OSPRep '+version+' &copy; {copy} by Itzchak Rehberg &amp; <A STYLE="text-decoration:none" HREF="http://www.izzysoft.de/" TARGET="_blank">IzzySoft<\/A><\/SPAN><IMG SRC="..\/islogo.gif" ALT="IzzySoft" WIDTH="14" HEIGHT="14" ALIGN="middle" STYLE="margin-left:3px"><\/DIV>');
//--></SCRIPT>

</BODY></HTML>
