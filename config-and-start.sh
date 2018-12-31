#!/bin/bash

set -e
set -u
set -o pipefail

sleep 30

./Oracle/Middleware/jdk160_35/bin/javac SimpleJdbcRunner.java

./Oracle/Middleware/jdk160_35/bin/java -cp .:./jtds12.jar SimpleJdbcRunner \
    -driver net.sourceforge.jtds.jdbc.Driver \
    -url jdbc:jtds:sqlserver://db \
    -username sa \
    -password 'ABcd12#$' \
    -query "DROP DATABASE IF EXISTS EPM_HSS, EPM_EAS;CREATE DATABASE EPM_HSS;CREATE DATABASE EPM_EAS"

./Oracle/Middleware/EPMSystem11R1/common/config/11.1.2.0/configtool.sh -silent /home/oracle/essbase-config.xml

#export LD_LIBRARY_PATH=/home/oracle/Oracle/Middleware/EPMSystem11R1/products/FinancialManagement/Server/:/home/oracle/Oracle/Middleware/EPMSystem11R1/products/FinancialManagement/Server/mw/lib-amd64_linux_optimized/:/home/oracle/Oracle/Middleware/EPMSystem11R1/common/ODBC-64/Merant/7.1/lib/
#export EPM_ORACLE_HOME=/home/oracle/Oracle/Middleware/EPMSystem11R1

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


/home/oracle/Oracle/Middleware/user_projects/epmsystem1/bin/start.sh

export PATH="$PATH:/home/oracle/Oracle/Middleware/user_projects/epmsystem1/EssbaseServer/essbaseserver1/bin"

echo "Loading sample databases in the background..."
startMaxl.sh load-sample-databases.msh &

tail -F /u0/Oracle/Middleware/user_projects/domains/EPMSystem/servers/EPMServer0/logs/apsserver.log
