#!/bin/bash

set -e
set -u
set -o pipefail

sleep 30

javac SimpleJdbcRunner.java

java -cp .:./jtds12.jar SimpleJdbcRunner \
    -driver net.sourceforge.jtds.jdbc.Driver \
    -url jdbc:jtds:sqlserver://db \
    -username sa \
    -password 'ABcd12#$' \
    -query "DROP DATABASE IF EXISTS EPM_HSS, EPM_EAS;CREATE DATABASE EPM_HSS;CREATE DATABASE EPM_EAS"

# Make sure that the refernce to both of these (or at least the configtool.sh call) are absolute paths
# as otherwise the exec/fork calls inside will fail

sed -i "s/__EPM_PASSWORD__/$EPM_PASSWORD/g" $HOME/essbase-config.xml  

$EPM_ORACLE_HOME/common/config/11.1.2.0/configtool.sh -silent $HOME/essbase-config.xml

# Brings in EPM_ORACLE_HOME, MWHOME, LD_LIBRARY_PATH (although this gets modified later in this script),
# HYPERION_HOME, and TNS_ADMIN. Must have run the config step prior to this as it is what
# creates the contents in user_projects, among other things

#source ./Oracle/Middleware/user_projects/epmsystem1/bin/setEnv.sh

#
# EPM_ORACLE_HOME example: Oracle/Middleware/EPMSystem11R1

#echo EPM_ORACLE_HOME = $EPM_ORACLE_HOME
#echo LD_LIBRARY_PATH = $LD_LIBRARY_PATH

echo Context:
export 
#echo     EPM_ORACLE_HOME = $EPM_ORACLE_HOME
#echo     LD_LIBRARY_PATH = $LD_LIBRARY_PATH

# Start up services. Note that the first thing the start script does is source in various variables from 
# setEnv (.../user_projects/epmsystem1/bin/setEnv.sh). This will establish EPM_ORACLE_HOME, EPM_ORACLE_INSTANCE
# MWHOME, LD_LIBRARY_PATH, HYPERION_HOME (same as EPM_ORACLE_HOME, appears to be a historical hack), and TNS_ADMIN

echo Calling EPM start script
$USER_PROJECTS/epmsystem1/bin/start.sh

echo Loading sample databases in the background...
startMaxl.sh load-sample-databases.msh &

echo Starting tail call on all .log files in logs folder
tail -F $USER_PROJECTS/domains/EPMSystem/servers/EPMServer0/logs/*.log
