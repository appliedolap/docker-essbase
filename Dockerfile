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

RUN rm -rf $ORACLE_ROOT/Middleware/jrockit_160_37
RUN rm -rf $ORACLE_ROOT/Middleware/jrockit_160_37
RUN rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/products/Essbase/aps/util
RUN rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/ODBC/*
#RUN rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/ODBC-64/*
#RUN rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/essbase-studio-sdk/*
RUN rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/epmstatic/webanalysis/*
#RUN rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/docs/*
#RUN rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/hfm/*
#RUN rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/planning/*
RUN rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/products/Essbase/EssbaseServer-32/*
RUN rm -rf $ORACLE_ROOT/Middleware/oracle_common/OPatch/Patches/*

RUN rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/JRE/Sun/1.6.0 && \
    ln -s  $ORACLE_ROOT/Middleware/jdk160_35/jre $ORACLE_ROOT/Middleware/EPMSystem11R1/common/JRE/Sun/1.6.0


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
openssh-clients 

RUN groupadd -f dba && \
    groupadd -f oinstall && \
    useradd -G dba oracle

ENV ORACLE_ROOT $ORACLE_ROOT_DEFAULT
RUN mkdir -p $ORACLE_ROOT && chown oracle:dba $ORACLE_ROOT

WORKDIR /home/oracle

# Other folders from install: bea, oraInventory
COPY --from=media --chown=oracle:dba $ORACLE_ROOT $ORACLE_ROOT
COPY --chown=oracle:dba SimpleJdbcRunner.java config-and-start.sh jtds12.jar essbase-config.xml load-sample-databases.msh ./

# Oddly enough, everything seemed to work fine when JAVA_HOME was invalid. Hmm.
ENV JAVA_HOME $ORACLE_ROOT/Middleware/jdk160_35
ENV JAVA_VENDOR Sun

ENV EPM_ORACLE_INSTANCE $ORACLE_ROOT/Middleware/user_projects/epmsystem1
ENV PATH="${JAVA_HOME}/bin:${EPM_ORACLE_INSTANCE}/EssbaseServer/essbaseserver1/bin:${PATH}"
ENV EPM_ORACLE_HOME $ORACLE_ROOT/Middleware/EPMSystem11R1
ENV USER_PROJECTS $ORACLE_ROOT/Middleware/user_projects
ENV TMP /tmp
ENV EPM_PASSWORD password2
ENV LCM $USER_PROJECTS/epmsystem1/bin/Utility.sh

USER oracle 

CMD ["./config-and-start.sh"]
