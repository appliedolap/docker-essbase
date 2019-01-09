#!/bin/bash

set -e
set -u
set -o pipefail

echo Starting up Essbase container, checking if configuration is needed

java -version

if [ ! -f ".hasBeenConfigured" ]; then
    echo Performing first-time configuration

    ln -s $EPM_ORACLE_INSTANCE/import_export $HOME/import_export
    ln -s $EPM_ORACLE_INSTANCE/EssbaseServer/essbaseserver1/app $HOME/app
    ln -s $USER_PROJECTS/domains/EPMSystem/bin/startWebLogic.sh $HOME/startWebLogicAdminConsole.sh

    javac SimpleJdbcRunner.java

    java -cp .:./jtds12.jar SimpleJdbcRunner \
    -driver net.sourceforge.jtds.jdbc.Driver \
    -url jdbc:jtds:sqlserver://$SQL_HOST \
    -username sa \
    -password "$SQL_PASSWORD" \
    -query "DROP DATABASE IF EXISTS EPM_HSS, EPM_EAS;CREATE DATABASE EPM_HSS;CREATE DATABASE EPM_EAS"

    # Make sure that the refernce to both of these (or at least the configtool.sh call) are absolute paths
    # as otherwise the exec/fork calls inside will fail

    sed -i \
    -e "s/__EPM_ADMIN__/$EPM_ADMIN/g" \
    -e "s/__EPM_PASSWORD__/$EPM_PASSWORD/g" \
    -e "s/__SQL_HOST__/$SQL_HOST/g" \
    -e "s/__SQL_USER__/$SQL_USER/g" \
    -e "s/__SQL_PASSWORD__/$SQL_PASSWORD/g" \
    -e "s|__ORACLE_ROOT__|$ORACLE_ROOT|g" \
    $HOME/essbase-config.xml  

    if [ "$NO_CONFIG" = "true" ]; then
        echo Skipping config
        tail -F /dev/null
    fi

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

    # Start up services. Note that the first thing the start script does is source in various variables from 
    # setEnv (.../user_projects/epmsystem1/bin/setEnv.sh). This will establish EPM_ORACLE_HOME, EPM_ORACLE_INSTANCE
    # MWHOME, LD_LIBRARY_PATH, HYPERION_HOME (same as EPM_ORACLE_HOME, appears to be a historical hack), and TNS_ADMIN

    echo Calling EPM start script
    $USER_PROJECTS/epmsystem1/bin/start.sh

    echo Loading sample databases in the background...
    startMaxl.sh load-sample-databases.msh &

    echo Checking to autostart the admin console
    if [ "$AUTO_START_ADMIN_CONSOLE" = "true" ]; then
    echo Starting the admin console in the background...
    $HOME/startWebLogicAdminConsole.sh &    
    fi

    touch .hasBeenConfigured

else
    echo This instance was already configured, just going to start it again
    $USER_PROJECTS/epmsystem1/bin/start.sh
fi

echo Starting tail call on all .log files in logs folder
tail -F $USER_PROJECTS/domains/EPMSystem/servers/EPMServer0/logs/*.log
