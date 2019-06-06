#!/bin/bash
#
#
# WebLogic command example:
# WL_CMD="java -cp $MW/wlserver_10.3/server/lib/weblogic.jar weblogic.Deployer -adminurl t3://127.0.0.1:7001 -user $EPM_ADMIN -password $EPM_PASSWORD" \
#

set -e
set -u
set -o pipefail

echo Starting up Essbase container, checking if configuration is needed

#export PATH="${JAVA_HOME}/bin:${EPM_ORACLE_INSTANCE}/EssbaseServer/essbaseserver1/bin:${PATH}"

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
    -query "DROP DATABASE IF EXISTS ${SQL_DB_PREFIX}HSS, ${SQL_DB_PREFIX}EAS;CREATE DATABASE ${SQL_DB_PREFIX}HSS;CREATE DATABASE ${SQL_DB_PREFIX}EAS"

    # Make sure that the refernce to both of these (or at least the configtool.sh call) are absolute paths
    # as otherwise the exec/fork calls inside will fail

    sed -i \
    -e "s/__EPM_ADMIN__/$EPM_ADMIN/g" \
    -e "s/__EPM_PASSWORD__/$EPM_PASSWORD/g" \
    -e "s/__SQL_HOST__/$SQL_HOST/g" \
    -e "s/__SQL_DB_PREFIX__/$SQL_DB_PREFIX/g" \
    -e "s/__SQL_USER__/$SQL_USER/g" \
    -e "s/__SQL_PASSWORD__/$SQL_PASSWORD/g" \
    -e "s/__ESS_START_PORT__/$ESS_START_PORT/g" \
    -e "s/__ESS_END_PORT__/$ESS_END_PORT/g" \
    -e "s|__EPM__|$EPM|g" \
    -e "s|__MW__|$MW|g" \
    $HOME/essbase-config.xml  

    # Update the templatized variables for SQL connection in ODBC settings. This 
    # enables the usage of the local SQL database inside of a load rule
    sed \
    -e "s/__SQL_USER__/$SQL_USER/g" \
    -e "s/__SQL_PASSWORD__/$SQL_PASSWORD/g" \
    -e "s/__SQL_DB__/${SQL_DB_PREFIX}HSS/g" \
    -e "s|__EPM__|$EPM|g" \
    $HOME/odbc.ini > $EPM/common/ODBC-64/Merant/7.1/odbc.ini    

    if [ "$NO_CONFIG" = "true" ]; then
        echo Skipping config
        tail -F /dev/null
    fi

    sed -i -e 's|<dump intervalSeconds="10800" maxSizeMBytes="75" enabled="true"/>|<dump intervalSeconds="10800" maxSizeMBytes="75" enabled="false"/>|' \
        $MW/oracle_common/modules/oracle.dms_11.1.1/server_config/mbeans/dms_mbeans.xml

    sed -i -e 's|<dump intervalSeconds="10800" maxSizeMBytes="75" enabled="true"/>|<dump intervalSeconds="10800" maxSizeMBytes="75" enabled="false"/>|' \
        $MW/oracle_common/modules/oracle.dms_11.1.1/server_config/dms_config.xml

    $EPM/common/config/11.1.2.0/configtool.sh -silent $HOME/essbase-config.xml

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

    # Look for unzipped LCM import folders (that is, folders in start_scripts that contain an Import.xml file) and import them
    echo Running LCM imports
    for directory in start_scripts/*/; do
        if [ -f $directory/Import.xml ]; then
            target=/tmp/$(basename $directory)
            echo "Processing $directory in temporary location $target"
            cp -R $directory $target
            sed -i -e "s|<User.*/>|<User name=\"$EPM_ADMIN\" password=\"$EPM_PASSWORD\"/>|" $target/Import.xml
            $LCM_CMD $target/Import.xml
        else
            echo No Import.xml file present in $directory, skipping
        fi
    done

    #echo Checking to autostart the admin console
    #if [ "$AUTO_START_ADMIN_CONSOLE" = "true" ]; then
    #  echo Starting the admin console in the background...
    #  $HOME/startWebLogicAdminConsole.sh &    
    #fi

    if [ "$RESTART_EPM_AFTER_LCM_IMPORT" = "true" ]; then
	echo Starting WebLogic AdminServer in background and waiting for it to come online before proceeding
        rm -f .webLogicStartupLog
        $USER_PROJECTS/domains/EPMSystem/bin/startWebLogic.sh | tee .webLogicStartupLog &
        until cat .webLogicStartupLog | grep -m 1 "Server started in RUNNING mode"; do sleep 1 ; done
        
        echo Stopping EPM services per option so that imported foundational settings can be applied at $(date)
        #$USER_PROJECTS/epmsystem1/bin/stop.sh
        $USER_PROJECTS/domains/EPMSystem/bin/stopManagedWebLogic.sh EPMServer0

        echo Stopping EPM
	$USER_PROJECTS/epmsystem1/bin/stop.sh

        echo Starting EPM services ater imported foundational settings at $(date)
        $USER_PROJECTS/epmsystem1/bin/start.sh
    fi    

    echo Main system was configured and brought up in $SECONDS seconds
    echo Loading sample databases in the background...
    bunzip2 $USER_PROJECTS/epmsystem1/EssbaseServer/essbaseserver1/app/ASOsamp/Sample/dataload.txt.bz2
    startMaxl.sh load-sample-databases.msh &

    touch .hasBeenConfigured

else
    echo This instance was already configured, just going to start it again
    $USER_PROJECTS/epmsystem1/bin/start.sh
fi

echo Starting tail call on all .log files in logs folder
tail -F $USER_PROJECTS/domains/EPMSystem/servers/EPMServer0/logs/*.log
