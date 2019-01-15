ARG ORACLE_ROOT_DEFAULT=/opt/Oracle

FROM centos:6.9 as media
ARG ORACLE_ROOT_DEFAULT

RUN touch /var/lib/rpm/* && yum -y install unzip

RUN mkdir -p /root/epmmedia/extracted
WORKDIR /root/epmmedia

RUN groupadd -f dba && \
    groupadd -f oinstall && \
    useradd -G dba oracle

ENV ORACLE_ROOT $ORACLE_ROOT_DEFAULT

RUN mkdir -p $ORACLE_ROOT && chown oracle:dba $ORACLE_ROOT

USER oracle

WORKDIR /home/oracle

COPY Foundation-11124-linux64-Part1.zip .
COPY Foundation-11124-linux64-Part2.zip .
COPY Foundation-11124-linux64-Part4.zip .
COPY Foundation-11124-Part3.zip .
COPY Essbase-11124-linux64.zip .
COPY jdk-7u80-linux-x64.tar.gz .

RUN mkdir -p extracted && \
    unzip -o Foundation-11124-linux64-Part1.zip -d extracted && \
    unzip -o Foundation-11124-linux64-Part2.zip -d extracted && \
    unzip -o Foundation-11124-linux64-Part4.zip -d extracted && \
    unzip -o Foundation-11124-Part3.zip -d extracted && \
    unzip -o Essbase-11124-linux64.zip -d extracted

ENV TMP /tmp

# I guess don't ever use relative references for either invoking the installer or for 
# the location of the install response file. The process bounces around various shell
# invocations and other things and you'll get file not found errors
COPY essbase-install.xml .

RUN sed -i "s|__ORACLE_ROOT__|$ORACLE_ROOT|g" $HOME/essbase-install.xml && \ 
    $HOME/extracted/installTool.sh -silent $HOME/essbase-install.xml

# Remove JRE/JDKs supplied by Oracle as we will adding the 1.7 JDK. If for some reason
# you switch to the included 1.6 JDK, you can save space by tossing the /utl folder (appears to be 
# redundant installer files (!?), src.zip (standard Java source dist), and the /nginstall folder
RUN rm -rf $ORACLE_ROOT/Middleware/jrockit_160_37 && \
    rm -rf $ORACLE_ROOT/Middleware/jdk160_35 && \
    tar zxvf jdk-7u80-linux-x64.tar.gz -C $ORACLE_ROOT/Middleware && \
    ln -s $ORACLE_ROOT/Middleware/jdk1.7.0_80 $ORACLE_ROOT/Middleware/jdk160_35

# At one point I also tried taking out ODBC-64 but I think it may have caused a failure in install/config, as
# apparently a symlink is made to the odbc.ini file
# Can maybe delete common/planning?
# Note on JRE deletion -- originally I setup a symlink but it doesn't seem necessary
#
# ln -s  $ORACLE_ROOT/Middleware/jdk160_35/jre $ORACLE_ROOT/Middleware/EPMSystem11R1/common/JRE/Sun/1.6.0

# Configuration does not like the following items being removed:
#  - $ORACLE_ROOT/Middleware/utils

RUN rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/products/Essbase/aps/util && \
    rm -rf $ORACLE_ROOT/Middleware/oracle_common/jdk/jre/lib/fonts/* && \
    rm -rf $ORACLE_ROOT/Middleware/oracle_common/doc/* && \
    rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/essbase-studio-sdk/* && \
    rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/epmstatic/webanalysis/* && \
    rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/docs/* && \
    rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/hfm/* && \
    rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/products/Essbase/EssbaseServer-32/* && \
    rm -rf $ORACLE_ROOT/Middleware/oracle_common/OPatch/Patches/* && \
    rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/JRE/Sun/1.6.0 && \
    rm -rf $ORACLE_ROOT/Middleware/jdk160_35/src.zip && \
    rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/ODBC/* && \
    rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/products/Essbase/EssbaseServer/app/{DMDemo,Sampeast,Samppart} && \
    rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/ODBC-64/Merant/7.1/lib/{ARase27r,ARdb227,ARhive27,ARimpala27,ARora27r,ARpsql27,ARsyiq27,libARmback,ARase27,ARgplm27r,ARifcl27r,ARmysql27,ARora27,ARsfrc27,libARmbackw,ARdb227r,ARgplm27,ARifcl27,ARoe27,ARpsql27r,libARssl27}.so && \
    rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/ODBC-64/Merant/7.1/{adminhelp,help,bind,java}/* && \
    bzip2 $ORACLE_ROOT/Middleware/EPMSystem11R1/products/Essbase/EssbaseServer/app/ASOsamp/Sample/dataload.txt
   
    #rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/ODBC-64/* && \
    #mkdir -p $ORACLE_ROOT/Middleware/EPMSystem11R1/common/ODBC-64/Merant/7.1/ && \
    #echo "[ODBC Data Sources]" > $ORACLE_ROOT/Middleware/EPMSystem11R1/common/ODBC-64/Merant/7.1/odbc.ini

FROM centos:6.9
ARG ORACLE_ROOT_DEFAULT

LABEL maintainer="jason@appliedolap.com"

RUN touch /var/lib/rpm/* && yum -y install \
unzip \
compat-libcap1 \
libstdc++-devel \
sysstat \
gcc \
gcc-c++ \
ksh \
libaio \
libaio-devel \
lsof \
numactl \
glibc-devel \
glibc-devel.i686 \
libgcc \
libgcc.i686 \
compat-libstdc++-33 \
compat-libstdc++-33.i686 \
openssh-clients && \
yum clean all

RUN groupadd -f dba && \
    groupadd -f oinstall && \
    useradd -G dba oracle

ENV ORACLE_ROOT $ORACLE_ROOT_DEFAULT
RUN mkdir -p $ORACLE_ROOT && chown oracle:dba $ORACLE_ROOT

WORKDIR /home/oracle

# Other folders from install: bea, oraInventory
COPY --from=media --chown=oracle:dba $ORACLE_ROOT $ORACLE_ROOT
COPY --chown=oracle:dba SimpleJdbcRunner.java config-and-start.sh jtds12.jar essbase-config.xml load-sample-databases.msh welcome.sh ./
COPY --chown=oracle:dba landing ./landing

RUN mkdir -p init-data && chown oracle:oracle init-data

# Oddly enough, everything seemed to work fine when JAVA_HOME was invalid. Hmm.
# The usage of the UnlockCommercialFeatures option is as per Oracle support document 2351499.1.
# It is used SPECIFICALLY when Java 1.7 is in play. If an older version of Java is used,
# the option wiill be unrecognized and cause startup to fail
# 
# Note that at present the seeming JDK 1.6 reference is actually a symlink to a 1.7 install
# (also per one of the options for migrating that the support doc gives, although I believe it
# would be possible to simply reference whichever folder is desired as there shouldn't be 
# any references to 1.6 littered in various files, given how this Docker image is constructed

ENV JAVA_HOME $ORACLE_ROOT/Middleware/jdk160_35
ENV JAVA_VENDOR Sun
ENV JAVA_OPTIONS -XX:+UnlockCommercialFeatures

ENV EPM_ORACLE_INSTANCE $ORACLE_ROOT/Middleware/user_projects/epmsystem1
ENV PATH="${JAVA_HOME}/bin:${EPM_ORACLE_INSTANCE}/EssbaseServer/essbaseserver1/bin:${PATH}"
ENV EPM_ORACLE_HOME $ORACLE_ROOT/Middleware/EPMSystem11R1
ENV USER_PROJECTS $ORACLE_ROOT/Middleware/user_projects
ENV TMP /tmp
ENV EPM_ADMIN admin
ENV EPM_PASSWORD password1

ENV ESS_START_PORT="32768" ESS_END_PORT="32778"

ENV LCM_CMD $USER_PROJECTS/epmsystem1/bin/Utility.sh
ENV WL_CMD ="java -cp $ORACLE_ROOT/Middleware/wlserver_10.3/server/lib/weblogic.jar weblogic.Deployer -adminurl t3://127.0.0.1:7001 -user $EPM_ADMIN -password $EPM_PASSWORD"

ENV SQL_HOST db
ENV SQL_USER sa

# You'll almost definitely need to set a real value here
ENV SQL_PASSWORD password

ENV AUTO_START_ADMIN_CONSOLE false
ENV NO_CONFIG false

RUN echo source welcome.sh  >> /home/oracle/.bashrc

USER oracle 

EXPOSE 9000 1423 $ESS_START_PORT-$ESS_END_PORT 7001

CMD ["./config-and-start.sh"]
