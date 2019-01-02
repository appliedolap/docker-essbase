FROM centos:6.9 as media

RUN touch /var/lib/rpm/* && yum -y install unzip

RUN mkdir -p /root/epmmedia/extracted
WORKDIR /root/epmmedia

RUN groupadd -f dba && \
    groupadd -f oinstall && \
    useradd -G dba oracle

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

COPY essbase-install.xml .

# I guess don't ever use relative references for either invoking the installer or for 
# the location of the install response file. The process bounces around various shell
# invocations and other things and you'll get file not found errors

RUN $HOME/extracted/installTool.sh -silent $HOME/essbase-install.xml


FROM centos:6.9

LABEL maintainer="jason@appliedolap.com"

RUN touch /var/lib/rpm/* && yum -y install zip \
emacs \
unzip \
xauth \
xdpyinfo \
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
openssh-clients \
openssl098e-0.9.8e-20.el6.centos.1.x86_64 \
libicu.x86_64

RUN groupadd -f dba && \
    groupadd -f oinstall && \
    useradd -G dba oracle

WORKDIR /home/oracle

# Other folders from install: bea, oraInventory
COPY --from=media --chown=oracle:dba /home/oracle/Oracle ./Oracle
COPY --chown=oracle:dba SimpleJdbcRunner.java config-and-start.sh jtds12.jar essbase-config.xml load-sample-databases.msh ./

USER oracle 

CMD ["./config-and-start.sh"]
