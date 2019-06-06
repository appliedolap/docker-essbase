ARG ORACLE_ROOT_DEFAULT=/opt/Oracle
ARG PATCH_LEVEL=000

FROM centos:6.9 as media

ARG ORACLE_ROOT_DEFAULT
ARG PATCH_LEVEL

RUN touch /var/lib/rpm/* && yum -y install unzip

RUN groupadd -f dba && \
    useradd -G dba oracle

# A version of 7u211 (as part of the standard tar.gz distribution) would result in an extraction folder
# of something like jdk1.7.0_211
ENV MW=$ORACLE_ROOT_DEFAULT/Middleware \
    EPM=$ORACLE_ROOT_DEFAULT/Middleware/EPMSystem11R1 \
    PATCH_LEVEL=$PATCH_LEVEL \
    JDK_VERSION=7u211 \
    JDK_FOLDER=jdk1.7.0_211 \
    TMP=/tmp

RUN mkdir -p $ORACLE_ROOT_DEFAULT && chown oracle:dba $ORACLE_ROOT_DEFAULT

USER oracle

WORKDIR /home/oracle

# Note that any zip files added on this step will be extracted on the next step because it targets
# *.zip. If you need to add a file that you don't want extracted, put it in another folder or give
# it a different extension
COPY Foundation-11124-linux64-Part1.zip \
     Foundation-11124-linux64-Part2.zip \
     Foundation-11124-linux64-Part4.zip \
     Foundation-11124-Part3.zip \
     Essbase-11124-linux64.zip \
     jdk-${JDK_VERSION}-linux-x64.tar.gz \
     apply_patches.sh \
     essbase-install.xml \
     ./

# Copy any and all patches that have been staged in folders numbered 000, 001, ..., 031
COPY patches ./patches

RUN mkdir -p extracted && \
    unzip -o '*.zip' -d extracted

# I guess don't ever use relative references for either invoking the installer or for 
# the location of the install response file. The process bounces around various shell
# invocations and other things and you'll get file not found errors
RUN sed -i "s|__ORACLE_ROOT__|$ORACLE_ROOT_DEFAULT|g" $HOME/essbase-install.xml && \ 
    $HOME/extracted/installTool.sh -silent $HOME/essbase-install.xml

# Remove JRE/JDKs supplied by Oracle as we will adding the 1.7 JDK. If for some reason
# you switch to the included 1.6 JDK, you can save space by tossing the /utl folder (appears to be 
# redundant installer files (!?), src.zip (standard Java source dist), and the /nginstall folder
# Earlier iterations also bothered to symlink the other JRE located here:
#   ln -s  $ORACLE_ROOT/Middleware/jdk160_35/jre $ORACLE_ROOT/Middleware/EPMSystem11R1/common/JRE/Sun/1.6.0
#   But not bothering to touch it also seems to be fine (the system will find a JRE anyway)

RUN rm -rf $MW/jrockit_160_37 && \
    rm -rf $MW/jdk160_35 && \
    tar zxvf jdk-${JDK_VERSION}-linux-x64.tar.gz -C $MW && \
    ln -s $MW/$JDK_FOLDER $MW/jdk160_35

# Configuration does not like the following items being removed:
#  - $ORACLE_ROOT/Middleware/utils
#  - rm -rf $EPM/perl/* 
# Leave at least the odbc.ini file at $ORACLE_ROOT/Middleware/EPMSystem11R1/common/ODBC-64/Merant/7.1/odbc.ini
#  otherwise a symlink can't get created and the installer gets upset

RUN rm -rf $MW/jdk160_35/src.zip && \
    rm -rf $MW/jdk160_35/lib/visualvm/* && \
    rm -rf $MW/oracle_common/jdk/jre/lib/fonts/* && \
    rm -rf $MW/oracle_common/doc/* && \
    rm -rf $EPM/products/Essbase/aps/util/* && \
    rm -rf $EPM/products/Essbase/EssbaseServer-32/* && \
    rm -rf $EPM/products/Essbase/{EssbaseClient-32,EssbaseServer-32}/* && \
    rm -rf $EPM/products/Essbase/EssbaseServer/app/{DMDemo,Sampeast,Samppart} && \
    rm -rf $EPM/common/{docs,hfm,EssbaseRTC,essbase-studio-sdk}/* && \
    rm -rf $EPM/common/epmstatic/webanalysis/* && \
    rm -rf $EPM/common/JRE/Sun/1.6.0 && \
    rm -rf $EPM/common/ODBC/* && \
    rm -rf $EPM/common/ODBC-64/Merant/7.1/lib/{ARase27r,ARdb227,ARhive27,ARimpala27,ARora27r,ARpsql27,ARsyiq27,libARmback,ARase27,ARgplm27r,ARifcl27r,ARmysql27,ARora27,ARsfrc27,libARmbackw,ARdb227r,ARgplm27,ARifcl27,ARoe27,ARpsql27r,libARssl27}.so && \
    rm -rf $EPM/common/ODBC-64/Merant/7.1/{adminhelp,help,bind,java}/* && \
    bzip2 $EPM/products/Essbase/EssbaseServer/app/ASOsamp/Sample/dataload.txt 

# This helper script will iterate through the patch zip files located in patches/PATCH_LEVEL. The patches should have their
# default name from Oracle (e.g. pXXXXXXX-something.zip) and then be prepended with 01-, 02- and so on. This gives you the
# ability to force the patches to be applied in a particular order
   
RUN ./apply_patches.sh

RUN rm -rf $ORACLE_ROOT/Middleware/oracle_common/OPatch/Patches/* && \
    rm -rf $MW/oracle_common/.patch_storage/* && \
    rm -rf $MW/EPMSystem11R1/.patch_storage/* && \
    find $MW -name '_uninst*' -prune -exec rm -rf {} \; && \
    find $MW -name 'uninstall' -prune -exec rm -rf {} \; && \
    rm -rf $EPM/diagnostics/logs/*

# Main Image

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

# The usage of the UnlockCommercialFeatures option is as per Oracle support document 2351499.1.
# It is used SPECIFICALLY when Java 1.7 is in play. If an older version of Java is used,
# the option wiill be unrecognized and cause startup to fail
# 
# Note that at present the seeming JDK 1.6 reference is actually a symlink to a 1.7 install
# (also per one of the options for migrating that the support doc gives, although I believe it
# would be possible to simply reference whichever folder is desired as there shouldn't be 
# any references to 1.6 littered in various files, given how this Docker image is constructed
#
# Variable Notes:
# 
#   RESTART_EPM_AFTER_LCM_IMPORT:
#     Typically false, this is used in one specific use case (so far) to fully bounce the services 
#     after performing an LCM import that includes changes to the authentication providers (such as
#     adding an LDAP directory)
#

ENV JAVA_HOME=$ORACLE_ROOT_DEFAULT/Middleware/jdk160_35 \
    JAVA_VENDOR=Sun \
    JAVA_OPTIONS=-XX:+UnlockCommercialFeatures \
    EPM_ORACLE_INSTANCE=$ORACLE_ROOT_DEFAULT/Middleware/user_projects/epmsystem1 \
    MW=$ORACLE_ROOT_DEFAULT/Middleware \
    EPM=$ORACLE_ROOT_DEFAULT/Middleware/EPMSystem11R1 \
    USER_PROJECTS=$ORACLE_ROOT_DEFAULT/Middleware/user_projects \
    TMP=/tmp \
    EPM_ADMIN=admin \
    EPM_PASSWORD=password1 \
    ESS_START_PORT="32768" \
    ESS_END_PORT="32778" \
    LCM_CMD=$USER_PROJECTS/epmsystem1/bin/Utility.sh \
    SQL_HOST=db \
    SQL_USER=sa \
    SQL_PASSWORD=password \
    SQL_DB_PREFIX=EPM_ \
    AUTO_START_ADMIN_CONSOLE=false \
    RESTART_EPM_AFTER_LCM_IMPORT=false \
    NO_CONFIG=false 

# Augment system PATH so that Java and MaxL can be run straight from any command
ENV PATH="${JAVA_HOME}/bin:${EPM_ORACLE_INSTANCE}/EssbaseServer/essbaseserver1/bin:${PATH}"

RUN mkdir -p $ORACLE_ROOT_DEFAULT && chown oracle:dba $ORACLE_ROOT_DEFAULT

# Other folders from install: bea, oraInventory
COPY --from=media --chown=oracle:dba $ORACLE_ROOT_DEFAULT $ORACLE_ROOT_DEFAULT

USER oracle 

WORKDIR /home/oracle

COPY --chown=oracle:dba \
     SimpleJdbcRunner.java \
     config-and-start.sh \
     jtds12.jar \
     essbase-config.xml \
     load-sample-databases.msh \
     welcome.sh \
     odbc.ini \
     .bashrc \
     ./

EXPOSE 9000 1423 $ESS_START_PORT-$ESS_END_PORT 7001

CMD ["sh", "-c", "./config-and-start.sh"]

