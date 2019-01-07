#!/bin/bash

# create the war
# run the admin server
# remove old proxything
# add our new one
# shut down admin server if desired

#java -cp $ORACLE_ROOT/Middleware/wlserver_10.3/server/lib/weblogic.jar weblogic.Deployer -adminurl t3://127.0.0.1:7001 -user epm_admin -password password1 -undeploy -name  landing.war -targets EPMServer0

#export WL_CMD="java -cp $ORACLE_ROOT/Middleware/wlserver_10.3/server/lib/weblogic.jar weblogic.Deployer -adminurl t3://127.0.0.1:7001 -user epm_admin -password password1"

pushd $HOME/landing
jar -cvf $HOME/landing.war *
popd

# admin server is running when we get output saying as such:

<Jan 7, 2019 8:56:42 PM UTC> <Notice> <WebLogicServer> <BEA-000365> <Server state changed to RUNNING>
<Jan 7, 2019 8:56:42 PM UTC> <Notice> <WebLogicServer> <BEA-000360> <Server started in RUNNING mode>


$WL_CMD -undeploy -name proxyservlet -appversion 11.1.2.2 -targets EPMServer
$WL_CMD -deploy landing/landing.war -targets EPMServer

