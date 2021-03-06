#!/bin/bash
# $Id$
#
# =============================================================================
# Oracle StatsPack Report 2 Html  (c) 2003-2011 by IzzySoft (devel@izzysoft.de)     
# -----------------------------------------------------------------------------
# This report script creates a HTML document containing the StatsPack Report.
# It is a simple rewrite of the standard sprepins.sql script
# I'ld never claim this report tool to be perfect, complete or "state of the
# art". But it's simple to use and very helpful to those not having a license
# to the expensive AddOns available at Oracle. Any hints on errors or bugs as
# well as recommendations for additions are always welcome.
#                                                              Itzchak Rehberg
# =============================================================================

# =======================================================[ Header / Syntax ]===
function syntax {
  SCRIPT=${0##*/}
  echo
  echo ============================================================================
  echo "OSPRep v$version           (c) 2003-2011 by Itzchak Rehberg (devel@izzysoft.de)"
  echo ----------------------------------------------------------------------------
  echo This script is intended to generate a HTML report for the Oracle StatsPack
  echo collected statistics. Look inside the script header for closer details, and
  echo check for the configuration there as well.
  echo ----------------------------------------------------------------------------
  echo "Syntax: ${SCRIPT} <ORACLE_SID> [Options]"
  echo "  Options:"
  echo "     -c <alternate ConfigFile>"
  echo "     -b <BEGIN_ID (Snapshot)>"
  echo "     -e <END_ID (Snapshot)>"
  echo "     -h (Display this help message and exit)"
  echo "     -o <Output Filename>"
  echo "     -p <Password>"
  echo "     -r <ReportDirectory>"
  echo "     -s <ORACLE_SID/Connection String for Target DB>"
  echo "     -u <username>"
  echo "  Example: generate report for oradb up to snapshot ID 1800:"
  echo "   ${SCRIPT} oradb -e 1800"
  echo ============================================================================
  echo
  exit 1
}

# =================================================[ Configuration Section ]===
BINDIR=${0%/*}
#BINDIR=`dirname $0`
CONFIG=$BINDIR/config
ARGS=$*
PLUGINDIR=$BINDIR/plugins
FOOTER=$PLUGINDIR/footer.pls

. ${BINDIR}/version

# ----------------------------------------------------------[ syntax check ]---
[ -z "$1" ] && syntax

# ------------------------------------------[ process command line options ]---
while [ "$1" != "" ] ; do
  case "$1" in
    -s) shift; ORACLE_CONNECT=$1;;
    -u) shift; username=$1;;
    -p) shift; passwd=$1;;
    -e) shift; PEND_ID=$1;;
    -b) shift; PSTART_ID=$1;;
    -c) shift; CONFIG=$1;;
    -r) shift; REPORTDIR=$1;;
    -o) shift; FILENAME=$1;;
    -h|--help|"?"|"-?") syntax;;
  esac
  shift
done
# -------------------------------------------[ Read the Configuration File ]---
. $CONFIG $ARGS
if [ -z "$ORACLE_CONNECT" ]; then
  ORACLE_CONNECT=$ORACLE_SID
fi
if [ -n "$PEND_ID" ]; then END_ID=$PEND_ID; fi
if [ -n "$PSTART_ID" ]; then START_ID=$PSTART_ID; fi
if [ -n "$START_ID" ]; then
  if [ -z "$END_ID" ]; then
    END_ID=$START_ID
  fi
fi
if [ -n "$username" ]; then
  user=$username
fi
if [ -n "$passwd" ]; then
  password=$passwd
fi
if [ -n "$REPORTDIR" ]; then
  REPDIR=$REPORTDIR
fi
if [ -z "$FILENAME" ]; then
  FILENAME="${ORACLE_SID}.html"
fi

# --------------------------------[ Get the Oracle version of the DataBase ]---
SQLSET=$TMPDIR/osprep_sqlset_$ORACLE_SID.$$
TMPOUT=$TMPDIR/osprep_tmpout_$ORACLE_SID.$$
GWDUMMY=$TMPDIR/osprep_gwdummy_$ORACLE_SID.$$
DFDUMMY=$TMPDIR/osprep_dfdummy_$ORACLE_SID.$$

SQLPLUSRELEASE=`echo "prompt &_SQLPLUS_RELEASE" | $ORACLE_HOME/bin/sqlplus -s $user/$password@$ORACLE_CONNECT |tail -1`

# Serveroutput: 10g+ supports unlimited
if [ "${SQLPLUSRELEASE:0:13}" = "where <logon>" ]; then
  echo "Could not connect to the specified database. Please check your login/connection data!"
  exit 1
elif [ ${SQLPLUSRELEASE:0:2} -lt 20 ]; then
  SERVOUT="Size Unlimited"
else
  SERVOUT="Size 1000000"
fi

cat >$SQLSET<<ENDSQL
CONNECT $user/$password@$ORACLE_CONNECT
ALTER SESSION SET NLS_NUMERIC_CHARACTERS='.,';
Set TERMOUT OFF
Set SCAN OFF
Set SERVEROUTPUT On $SERVOUT
Set LINESIZE 500
Set TRIMSPOOL On 
Set FEEDBACK OFF
Set Echo Off
Set PAGESIZE 0
SPOOL $TMPOUT
ENDSQL

cat $SQLSET $PLUGINDIR/getver.sql | $ORACLE_HOME/bin/sqlplus -s /NOLOG >/dev/null
DBVER=`cat $TMPOUT`
SPFILE=$PLUGINDIR/sp$DBVER.pls

# ---------------------------------------------------[ Prepare the PlugIns ]---
if [ $DBVER -lt 90 ]; then
  MK_RECO=0
  MK_USS=0
  MK_USSTAT=0
  MK_ENQ=0
  # Until we found a replacement algorith, we also need to disable these for 8i:
  MK_SPSTAT=0
  MK_BUFFP=0
  MK_BUFFW=0
fi

if [ $MK_INSTEFF -eq 1 ]; then
  INSTEFF=$PLUGINDIR/insteff.pls
fi
if [ $MK_TOPWAITS -eq 1 ]; then
  if [ $DBVER -lt 90 ]; then
    TWAITHEAD=$PLUGINDIR/twait_head8.pls
  else
    TWAITHEAD=$PLUGINDIR/twait_head.pls
  fi
  TWAITBODY=$PLUGINDIR/twait_body.pls
fi
if [ $MK_BGWAITS -eq 1 ]; then
  if [ $DBVER -lt 90 ]; then
    BGWAITHEAD=$PLUGINDIR/bgwait_head8.pls
  else
    BGWAITHEAD=$PLUGINDIR/bgwait_head.pls
  fi
  BGWAITBODY=$PLUGINDIR/bgwait_body.pls
fi
if [ $MK_ALLWAITS -eq 1 ]; then
  if [ $DBVER -lt 90 ]; then
    ALLWAITHEAD=$PLUGINDIR/allwait_head8.pls
  else
    ALLWAITHEAD=$PLUGINDIR/allwait_head.pls
  fi
  ALLWAITBODY=$PLUGINDIR/allwait_body.pls
fi
if [ $MK_WAITOBJ -eq 1 ]; then
  WAITOBJ=$PLUGINDIR/wait_obj.pls
fi
if [ $MK_TOPSQL -eq 1 ]; then
  if [ $IS_AWR -eq 1 ]; then
    TSQLHEAD=$PLUGINDIR/tsql_head_awr.pls
  elif [ $DBVER -gt 92 ]; then
    TSQLHEAD=$PLUGINDIR/tsql_head_102.pls
  else
    TSQLHEAD=$PLUGINDIR/tsql_head.pls
  fi
  TSQLBODY=$PLUGINDIR/tsql_body.pls
fi
if [ $MK_TABS -eq 1 ]; then
  TABSHEAD=$PLUGINDIR/tabs_head.pls
  TABSBODY=$PLUGINDIR/tabs_body.pls
fi
if [ $MK_DFSTAT -eq 1 ]; then
  DFSFILE=$PLUGINDIR/datafiles.pls
fi
if [ "${MK_TSIO}${MK_FIO}" != "00" ]; then
  IOHEAD=$PLUGINDIR/io_head.pls
  IOBODY=$PLUGINDIR/io_body.pls
fi
if [ $MK_INSTACT -eq 1 ]; then
  INSTACTHEAD=$PLUGINDIR/instact_head.pls
  INSTACTBODY=$PLUGINDIR/instact_body.pls
fi
if [ $MK_RECO -eq 1 ]; then
  RECOHEAD=$PLUGINDIR/reco_head.pls
  RECOBODY=$PLUGINDIR/reco_body.pls
fi
if [ "${MK_USS}${MK_USSTAT}" != "00" ]; then
  USSTATHEAD=$PLUGINDIR/undo_head.pls
  USSTATBODY=$PLUGINDIR/undo_body.pls
fi
if [ $MK_LACT -eq 1 ]; then
  LACTHEAD=$PLUGINDIR/lact_head.pls
  LACTBODY=$PLUGINDIR/lact_body.pls
  if [ $MK_LMS -eq 1 ]; then
    LMSHEAD=$PLUGINDIR/lms_head.pls
    LMSBODY=$PLUGINDIR/lms_body.pls
  fi
fi
if [ "${MK_SPSTAT}${MK_BUFFP}${MK_BUFFW}" != "000" ]; then
  BUFFHEAD=$PLUGINDIR/buff_head.pls
  BUFFBODY=$PLUGINDIR/buff_body.pls
fi
if [ "${MK_PGAA}${MK_PGAM}" != "00" ]; then
  [ $DBVER -gt 81 ] && {
    if [ $IS_AWR -eq 1 ]; then
      PGAHEAD=$PLUGINDIR/pga_head_awr.pls
    else
      PGAHEAD=$PLUGINDIR/pga_head.pls
    fi
    PGABODY=$PLUGINDIR/pga_body.pls
  }
fi
if [ $MK_ENQ -eq 1 ]; then
  if [ $DBVER -gt 92 ]; then
    ENQHEAD=$PLUGINDIR/enq_head_102.pls
  else
    ENQHEAD=$PLUGINDIR/enq_head.pls
  fi
  ENQBODY=$PLUGINDIR/enq_body.pls
fi
if [ "${MK_RSSTAT}${MK_RSSTOR}" != "00" ]; then
  RBSHEAD=$PLUGINDIR/rbs_head.pls
  RBSBODY=$PLUGINDIR/rbs_body.pls
fi
if [ "${MK_CACHSIZ}${MK_LC}${MK_DC}" != "000" ]; then
  CACHEHEAD=$PLUGINDIR/cache_head.pls
  CACHEBODY=$PLUGINDIR/cache_body.pls
fi
if [ $MK_SGASUM -eq 1 ]; then
  if [ $IS_AWR -eq 1 ]; then
    SGAHEAD=$PLUGINDIR/sga_head_awr.pls
  else
    SGAHEAD=$PLUGINDIR/sga_head.pls
  fi
  SGABODY=$PLUGINDIR/sga_body.pls
fi
if [ $MK_IORA -eq 1 ]; then
  IORAHEAD=$PLUGINDIR/iora_head.pls
  IORABODY=$PLUGINDIR/iora_body.pls
fi
if [ $DBVER -gt 91 ]; then
  if [ "${MK_SEG_LR}${MK_SEG_PR}${MK_SEG_BUSY}${MK_SEG_LOCK}${MK_SEG_ITL}" != "00000" ]; then
    SEGSTATHEAD=$PLUGINDIR/segstat_head.pls
    SEGSTATBODY=$PLUGINDIR/segstat_body.pls
    MK_SEGSTAT=1
  else
    MK_SEGSTAT=0
  fi
else
  MK_SEGSTAT=0
fi
if [ $MK_DBWR -eq 1 ]; then
  DBWRHEAD=$PLUGINDIR/dbwr_head.pls
  DBWRBODY=$PLUGINDIR/dbwr_body.pls
fi
if [ $MK_LGWR -eq 1 ]; then
  LGWRHEAD=$PLUGINDIR/lgwr_head.pls
  LGWRBODY=$PLUGINDIR/lgwr_body.pls
fi

if [ "${MK_DBWR}${MK_LGWR}${MK_TABS}" != "000" ]; then
  if [ $DBVER -lt 90 ]; then
    SYSSTATFUNCS=$PLUGINDIR/sysstats8.pls
  else
    SYSSTATFUNCS=$PLUGINDIR/sysstats.pls
  fi
fi

# ==========================================[ Start the Run of the Scripts ]===
. $BINDIR/version

# ----------------------------------[ Check for the AddOns and set them up ]---
cat $SQLSET $PLUGINDIR/checkwt.sql | $ORACLE_HOME/bin/sqlplus -s /NOLOG >/dev/null
WTEXISTS=`cat $TMPOUT`
if [ "$WTEXISTS" = "1" ];
then
  GETWAITS="$PLUGINDIR/getwaits.prc"
else
  cat >$GWDUMMY<<ENDSQL
  cat>>$SQLSET<<ENDDUMMY
  PROCEDURE get_waitobj IS
  BEGIN
    NULL;
  END;
ENDDUMMY
ENDSQL
  chmod u+x $GWDUMMY
  GETWAITS=$GWDUMMY
fi

cat $SQLSET $PLUGINDIR/checkdf.sql | $ORACLE_HOME/bin/sqlplus -s /NOLOG >/dev/null
DFEXISTS=`cat $TMPOUT`
if [ "$DFEXISTS" = "1" ];
then
  GETDF="$PLUGINDIR/getfilestat.prc"
else
  cat >$DFDUMMY<<ENDSQL
  cat>>$SQLSET<<ENDDUMMY
  PROCEDURE get_filestats IS
  BEGIN
    NULL;
  END;
ENDDUMMY
ENDSQL
  chmod u+x $DFDUMMY
  GETDF=$DFDUMMY
fi

# ---------------------------------------------------[ Setup some Settings ]---
if [ "$EXC_PERF_FOR" = "" ];
then EXCLUDE_OWNERS="'NULL'"
else
  for i in $EXC_PERF_FOR; do
    if [ "$EXCLUDE_OWNERS" = "" ];
    then EXCLUDE_OWNERS="'$i'"
    else EXCLUDE_OWNERS="$EXCLUDE_OWNERS,'$i'"
    fi
  done
fi

# -------------------------------[ Prepare and run the final report script ]---
cat >$SQLSET<<ENDSQL
CONNECT $user/$password@$ORACLE_CONNECT
Set TERMOUT OFF
Set SCAN OFF
Set SERVEROUTPUT On Size 1000000
Set LINESIZE 300
Set TRIMSPOOL On 
Set FEEDBACK OFF
Set Echo Off
variable MK_INSTEFF NUMBER;
variable MK_TOPWAITS NUMBER;
variable MK_ALLWAITS NUMBER;
variable MK_BGWAITS NUMBER;
variable MK_WAITOBJ NUMBER;
variable MK_INSTACT NUMBER;
variable MK_USS NUMBER;
variable MK_USSTAT NUMBER;
variable MK_LACT NUMBER;
variable MK_LMS NUMBER;
variable MK_IORA NUMBER;
variable MK_SGASUM NUMBER;
variable MK_SGABREAK NUMBER;
variable MK_CACHSIZ NUMBER;
variable MK_DC NUMBER;
variable MK_LC NUMBER;
variable MK_RSSTAT NUMBER;
variable MK_RSSTOR NUMBER;
variable MK_ENQ NUMBER;
variable MK_PGAA NUMBER;
variable MK_PGAM NUMBER;
variable MK_SPSTAT NUMBER;
variable MK_BUFFP NUMBER;
variable MK_BUFFW NUMBER;
variable MK_RECO NUMBER;
variable MK_DFSTAT NUMBER;
variable MK_TSIO NUMBER;
variable MK_FIO NUMBER;
variable MK_DBWR NUMBER;
variable MK_LGWR NUMBER;
variable MK_TOPSQL NUMBER;
variable SQL_MAXLEN NUMBER;
variable MK_EP NUMBER;
variable MK_SEG_LR NUMBER;
variable MK_SEG_PR NUMBER;
variable MK_SEG_BUSY NUMBER;
variable MK_SEG_LOCK NUMBER;
variable MK_SEG_ITL NUMBER;
variable MK_SEGSTAT NUMBER;
variable MK_RLIMS NUMBER;
variable WR_IE_BUFFNW NUMBER;
variable AR_IE_BUFFNW NUMBER;
variable WR_IE_REDONW NUMBER;
variable AR_IE_REDONW NUMBER;
variable WR_IE_BUFFHIT NUMBER;
variable AR_IE_BUFFHIT NUMBER;
variable WR_IE_IMSORT NUMBER;
variable AR_IE_IMSORT NUMBER;
variable WR_IE_LIBHIT NUMBER;
variable AR_IE_LIBHIT NUMBER;
variable WR_IE_SOFTPRS NUMBER;
variable AR_IE_SOFTPRS NUMBER;
variable WR_IE_PRSC2E NUMBER;
variable AR_IE_PRSC2E NUMBER;
variable WR_IE_LAHIT NUMBER;
variable AR_IE_LAHIT NUMBER;
variable WR_RLIM NUMBER;
variable AR_RLIM NUMBER;
variable WR_RWP NUMBER;
variable AR_RWP NUMBER;
variable AR_EP_FTS NUMBER;
variable WR_DF_CHNG NUMBER;
variable AR_DF_CHNG NUMBER;
variable WR_TS_BLKRD NUMBER;
variable AR_TS_BLKRD NUMBER;
variable WR_TS_RD NUMBER;
variable AR_TS_RD NUMBER;
variable WR_LC_MISS NUMBER;
variable AR_LC_MISS NUMBER;
variable WR_LC_RLPRQ NUMBER;
variable AR_LC_RLPRQ NUMBER;
variable WR_LC_INVPRQ NUMBER;
variable AR_LC_INVPRQ NUMBER;
variable WR_ET NUMBER;
variable AR_ET NUMBER;
BEGIN
  :MK_INSTEFF  := $MK_INSTEFF;
  :MK_TOPWAITS := $MK_TOPWAITS;
  :MK_ALLWAITS := $MK_ALLWAITS;
  :MK_BGWAITS  := $MK_BGWAITS;
  :MK_WAITOBJ  := $MK_WAITOBJ;
  :MK_INSTACT  := $MK_INSTACT;
  :MK_USS      := $MK_USS;
  :MK_USSTAT   := $MK_USSTAT;
  :MK_LACT     := $MK_LACT;
  :MK_LMS      := $MK_LMS;
  :MK_IORA     := $MK_IORA;
  :MK_SGASUM   := $MK_SGASUM;
  :MK_SGABREAK := $MK_SGABREAK;
  :MK_CACHSIZ  := $MK_CACHSIZ;
  :MK_DC       := $MK_DC;
  :MK_LC       := $MK_LC;
  :MK_RSSTAT   := $MK_RSSTAT;
  :MK_RSSTOR   := $MK_RSSTOR;
  :MK_ENQ      := $MK_ENQ;
  :MK_PGAA     := $MK_PGAA;
  :MK_PGAM     := $MK_PGAM;
  :MK_SPSTAT   := $MK_SPSTAT;
  :MK_BUFFP    := $MK_BUFFP;
  :MK_BUFFW    := $MK_BUFFW;
  :MK_RECO     := $MK_RECO;
  :MK_DFSTAT   := $MK_DFSTAT;
  :MK_TSIO     := $MK_TSIO;
  :MK_FIO      := $MK_FIO;
  :MK_DBWR     := $MK_DBWR;
  :MK_LGWR     := $MK_LGWR;
  :MK_TOPSQL   := $MK_TOPSQL;
  :SQL_MAXLEN  := $SQL_MAXLEN;
  :MK_EP       := $MK_EP;
  :MK_SEG_LR   := $MK_SEG_LR;
  :MK_SEG_PR   := $MK_SEG_PR;
  :MK_SEG_BUSY := $MK_SEG_BUSY;
  :MK_SEG_LOCK := $MK_SEG_LOCK;
  :MK_SEG_ITL  := $MK_SEG_ITL;
  :MK_SEGSTAT  := $MK_SEGSTAT;
  :MK_RLIMS    := $MK_RLIMS;
  :WR_IE_BUFFNW  := $WR_IE_BUFFNW;
  :AR_IE_BUFFNW  := $AR_IE_BUFFNW;
  :WR_IE_REDONW  := $WR_IE_REDONW;
  :AR_IE_REDONW  := $AR_IE_REDONW;
  :WR_IE_BUFFHIT := $WR_IE_BUFFHIT;
  :AR_IE_BUFFHIT := $AR_IE_BUFFHIT;
  :WR_IE_IMSORT  := $WR_IE_IMSORT;
  :AR_IE_IMSORT  := $AR_IE_IMSORT;
  :WR_IE_LIBHIT  := $WR_IE_LIBHIT;
  :AR_IE_LIBHIT  := $AR_IE_LIBHIT;
  :WR_IE_SOFTPRS := $WR_IE_SOFTPRS;
  :AR_IE_SOFTPRS := $AR_IE_SOFTPRS;
  :WR_IE_PRSC2E  := $WR_IE_PRSC2E;
  :AR_IE_PRSC2E  := $AR_IE_PRSC2E;
  :WR_IE_LAHIT   := $WR_IE_LAHIT;
  :AR_IE_LAHIT   := $AR_IE_LAHIT;
  :WR_RLIM       := $WR_RLIM;
  :AR_RLIM       := $AR_RLIM;
  :WR_RWP        := $WR_RWP;
  :AR_RWP        := $AR_RWP;
  :AR_EP_FTS     := $AR_EP_FTS;
  :WR_DF_CHNG    := $WR_DF_CHNG;
  :AR_DF_CHNG    := $AR_DF_CHNG;
  :WR_TS_BLKRD   := $WR_TS_BLKRD;
  :AR_TS_BLKRD   := $AR_TS_BLKRD;
  :WR_TS_RD      := $WR_TS_RD;
  :AR_TS_RD      := $AR_TS_RD;
  :WR_LC_MISS    := $WR_LC_MISS;
  :AR_LC_MISS    := $AR_LC_MISS;
  :WR_LC_RLPRQ   := $WR_LC_RLPRQ;
  :AR_LC_RLPRQ   := $AR_LC_RLPRQ;
  :WR_LC_INVPRQ  := $WR_LC_INVPRQ;
  :AR_LC_INVPRQ  := $AR_LC_INVPRQ;
  :WR_ET         := $WR_ET;
  :AR_ET         := $AR_ET;
END;
/
SPOOL $REPDIR/${FILENAME}
ENDSQL

. $BINDIR/ospopen
#cat $SQLSET $SPFILE $BINDIR/ospout.pls $INSTEFF $INSTACTBODY $TWAITBODY $ALLWAITBODY $BGWAITBODY $WAITOBJ $TSQLBODY $TABSBODY $DFSFILE $IOBODY $DBWRBODY $LGWRBODY $SEGSTATBODY $RECOBODY $PGABODY $ENQBODY $USSTATBODY $RBSBODY $LACTBODY $LMSBODY $BUFFBODY $CACHEBODY $SGABODY $PLUGINDIR/rlims.pls $IORABODY $FOOTER >osp.out
cat $SQLSET $SPFILE $BINDIR/ospout.pls $INSTEFF $INSTACTBODY $TWAITBODY $ALLWAITBODY $BGWAITBODY $WAITOBJ $TSQLBODY $TABSBODY $DFSFILE $IOBODY $DBWRBODY $LGWRBODY $SEGSTATBODY $RECOBODY $PGABODY $ENQBODY $USSTATBODY $RBSBODY $LACTBODY $LMSBODY $BUFFBODY $CACHEBODY $SGABODY $PLUGINDIR/rlims.pls $IORABODY $FOOTER | $ORACLE_HOME/bin/sqlplus -s /NOLOG
rm -f $SQLSET $TMPOUT $GWDUMMY $DFDUMMY
