# Docker Essbase

A composed Essbase Docker image with a minimal Essbase installation backed by a Microsoft SQL Server on Linux repository.

## How to build the image

You need to supply the installation media for the 64-bit Linux version of Essbase. Specifically, you should have these files:

 * Foundation-11124-linux64-Part1.zip
 * Foundation-11124-linux64-Part2.zip
 * Foundation-11124-linux64-Part4.zip
 * Foundation-11124-Part3.zip
 * Essbase-11124-linux64.zip

It is not necessary to extract these files anywhere as they are extracted as needed during the Docker container build itself.

To build this image, first clone this repository:

```
git clone https://github.com/appliedolap/docker-essbase.git
```

Then put the install ZIP files into the same folder, resulting in a file structure similar to the following:

```
jason@docker1:~/docker-essbase$ pwd && ls -l
/home/jason/docker-essbase
total 6415212
-rwxrwxr-x 1 jason jason       2072 Jan  3 22:01 config-and-start.sh
-rw-rw-r-- 1 jason jason        614 Jan  3 19:01 docker-compose.yml
-rw-rw-r-- 1 jason jason       3738 Jan  3 22:16 Dockerfile
-rwxrwxr-x 1 jason jason 1368259501 Dec 28 21:25 Essbase-11124-linux64.zip
-rw-r----- 1 jason jason      13853 Jan  3 19:40 essbase-config.xml
-rw-rw-r-- 1 jason jason        939 Jan  3 19:28 essbase-install.xml
-rwxrwxr-x 1 jason jason         47 Jan  3 19:29 essbash.sh
-rwxrwxr-x 1 jason jason        177 Jan  3 19:20 follow-essbase-logs.sh
-rwxrwxr-x 1 jason jason 1174052554 Dec 28 21:22 Foundation-11124-linux64-Part1.zip
-rwxrwxr-x 1 jason jason 1516370785 Dec 28 21:22 Foundation-11124-linux64-Part2.zip
-rwxrwxr-x 1 jason jason  980505762 Dec 28 21:22 Foundation-11124-linux64-Part4.zip
-rwxrwxr-x 1 jason jason 1529284475 Dec 28 21:22 Foundation-11124-Part3.zip
-rwxr-xr-x 1 jason jason     611504 Dec 31 21:19 jtds12.jar
-rw-rw-r-- 1 jason jason        605 Jan  3 19:01 load-sample-databases.msh
-rw-rw-r-- 1 jason jason       6629 Jan  3 22:27 README.md
-rwxrwxr-x 1 jason jason        417 Jan  3 19:21 restart.sh
-rw-rw-r-- 1 jason jason       2823 Dec 28 20:55 SimpleJdbcRunner.java
```

Open up a terminal to this folder. You can then use the `restart.sh` script to take down existing servers and build a new image, or run these commands yourself:

```
docker-compose down
docker-compose up --build --detach
```
   
The "up" command in this case specifies to bring up the images by building them and running in "detached" mode.

The first build may take awhile. Once the images are run (i.e. they become running containers), you may then find it useful to monitor the output coming from the Essbase container. You can easily connect to and watch the output by running the provided script to do so:

```
./follow-essbase-logs.sh
```

Lastly, you may wish to open a bash shell on the Essbase server itself. A convenience script is provided to do so:

```
./essbash.sh
```

This will open up a bash session on the Essbase container running as user `oracle`. 


## Quick Links

 * Workspace: http://localhost:9000/workspace/
 * EAS: http://localhost:9000/easconsole/

You can run EAS over JNLP by running the following command:

```
javaws http://localhost:9000/easconsole/easconsole.jnlp
```

This assumes that `javaws` is on your system's PATH. You may need to add a security exception to Java to get things to run. You should be able to use a local EAS install if that's your thing.

## Conveniences & Customizations

### Symlinks

In the user home folder (`/home/oracle`), some symlinks are provided for convenience. Notably you have:

 * `$HOME/app` points to your Essbase server `/app` folder (containing your applications such as Sample)
 * `$HOME/import_export` points to your LCM folder of the same name in case you want to quickly/easily drop some files in for an LCM import/export
 
 
### Paths

 * Java: The singular Java installation for the server has its `/bin` folder added to the system path, enabling you to execute `java` or `javac` simply by typing it on the command-line:
 
```
[oracle@b9858b4632cf ~]$ pwd && java -version
/home/oracle
java version "1.6.0_35"
Java(TM) SE Runtime Environment (build 1.6.0_35-b52)
Java HotSpot(TM) 64-Bit Server VM (build 20.10-b01, mixed mode)
[oracle@b9858b4632cf ~]$ 
``` 
 
 * MaxL: Your Essbase server's `bin` folder containing `startMaxl.sh` is added to the path as well (`${EPM_ORACLE_INSTANCE}/EssbaseServer/essbaseserver1/bin`), enabling to you run the MaxL shell simply by typing in `startMaxl.sh` from anywhere:
 
```
[oracle@b9858b4632cf ~]$ startMaxl.sh 

 Essbase MaxL Shell 64-bit - Release 11.1.2 (ESB11.1.2.4.000B193)
 Copyright (c) 2000, 2015, Oracle and/or its affiliates.
 All rights reserved.

MAXL> login 'admin' "$EPM_PASSWORD" on localhost;

 OK/INFO - 1051034 - Logging in user [admin@Native Directory].
 OK/INFO - 1241001 - Logged in to Essbase.

MAXL> 
```

In the login statement above, the login line uses the environment variable `$EPM_PASSWORD` to login, since MaxL gets automatic access to all environment variables. The double quotes are not strictly needed for variable interpolation purposes, it simply permits the login to work when the password happens to contain a space, such as would be used by a masochist.


### Environment Variables

Several environment variables are set, both simply as part of the Oracle/EPM environment itself as well as some convenience locations. These include variables that are used/required as part of the EPM install:

 * EPM_ORACLE_HOME: this is your folder ending at `EPMSystem11R1`, such as `/opt/Oracle/Middleware/EPMSystem11R1`, or more generally, `$ORACLE_ROOT/Middleware/EPMSystem11R1`. Note that `$ORACLE_ROOT` is not an Oracle convention, it is purely limited to this container.

 * EPM_ORACLE_INSTANCE: in the context of this image, this has a path of ``$ORACLE_ROOT/Middleware/user_projects/epmsystem1`
 
 * JAVA_HOME: The home folder of the JDK install. Note that this isn't the folder that contains the Java binaries (that's actually `$JAVA_HOME/bin`). 
 * JAVA_VENDOR: This is setup almost purely (with a value of `Sun`) just to preempt the WebLogic init script from trying to use the JRockit JRE to run WebLogic with. The 1.6 JDK technically has a defined vendor of "Sun" rather than "Oracle" because it considers the Oracle vendor to correspond to the JRockit JRE.

as well as some that part of the Docker Essbase build environment:

 * ORACLE_ROOT: a Docker Essbase build argument and environment variable that defines the absolute root directory of the entire Oracle installation. By default this is `/opt/Oracle`, although you can potentially use anything. Prior to changing this to somewhere in `/opt` this simply defaulted to `/home/oracle/Oracle`. The Dockerfile will make sure that this folder exists and is chown'd by user `oracle`.

 * EPM_PASSWORD: The default password for the admin user is parameterized and defined by this environment variable. This is the password you will use to login as admin, such as via EAS, MaxL, or Workspace. 
 
as well as some that are purely for convenience:

 * USER_PROJECTS: A convenince variable pointing to the `user_projects/` folder, such as shown above in the `EPM_ORACLE_INSTANCE` variable.
 * LCM: Allows for running LCM's `Utility.sh` conveniently. The expanded variable contains the full path to the LCM utility. So you can run LCM in the following way, for example:
 
```
[oracle@b9858b4632cf ~]$ $LCM Import1.xml
ERROR ! Cannot find the migration definition file in the specified filepath - /home/oracle/Import1.xml
[oracle@b9858b4632cf ~]$  
``` 
 * TMP: This serves very little purpose except to prevent some harmless warnings on the installer as it searches for and eventually defaults to a temporary directory, such as the system's `/tmp` folder.
 
Note that the EPM startup processes can and do set other variables as needed such as from a `setEnv.*` script, which will typically set things like `MWHOME`, `HYPERION_HOME`, `LD_LIBRARY_PATH`, and others as needed. This file will also set `EPM_ORACLE_HOME` and some others that are already defined, but they have the same value. 

### Sample Databases Loaded on Startup

Data is automatically loaded for Sample/Basic (with default calculation run), Demo/Basic (with default calculation run), ASOsamp/Sample (with aggregate view materialization run to a size factor of 1.1).


## General Architectural Notes

### Composed with off the shelf SQL Server

The first version of the Essbase Docker container was a monolithic image that contained a full Oracle RDBMS and the EPM install on top of it. This added considerable size and complexity to the image. For instance, the input ZIP files were some 3GB, to say nothing of the install size and time it took to configure.

At the moment, Oracle does not have an Oracle RDBMS image that is available on the public Docker hub (they have their own container registry it seems, though). That said, Microsoft SQL Server on Linux seems to be a very nice image that starts up quickly and isn't too large. Additionally, being able to simply connect as `sa` and work with multiple databases is a real delight compared to some of the schema/group/role issues that add complexity when using Oracle.

Upon startup of the Essbase image, a simple Java program is compiled and executed that uses an older but freely available SQL Server JDBC driver. The utility executes a few commands (drop databases if they exist, then create new databases to Shared Services, EAS, and whatever else is needed).


### Multi-stage build

The original iteration of this container was a single image that took a hit in various layers for having to stage, extract, and install EPM files. This newer image uses a multi-stage build to great effect. The copy of the installer ZIP files, their extraction, and even the main Oracle install step are all performed in the first of two images in the multi-stage build. When the actual EPM image is built, it simply performs a wholesale copy of directory where Oracle was installed (these *MUST* match between the build image and the application image), thus avoiding any size hit to the layers from the intermediate files that aren't needed.


### Focused on just core Essbase files

This image installs the Essbase service and nothing else -- not Planning, HFM, or even Essbase Studio. This is fairly evident in the silent installer response file that is used:

```
<?xml version="1.0" encoding="UTF-8"?>
<HyperionInstall>
  <HyperionHome>__ORACLE_ROOT__/Middleware</HyperionHome>
  <UserLocale>en_US</UserLocale>
  <ActionType>0</ActionType>
  <SelectedProducts>
        <Product name="foundation">
            <ProductComponent name="foundationServices">
                <Component>hssWebApp</Component>
                <Component>staticContent</Component>
                <Component>weblogic</Component>
            </ProductComponent>
        </Product>
        <Product name="essbase">
            <Component>essbaseWebApp</Component>
            <Component>essbaseApsWebApp</Component>
            <!--
            <Component>essbaseStudioService</Component>
            -->
            <Component>essbaseService</Component>
            <Component>essbaseServiceSamples</Component>
        </Product>
    </SelectedProducts>
  <ProductHomes/>
  <UpgradeCleanUp/>
  <UninstallCleanUp>false</UninstallCleanUp>
</HyperionInstall>
```

Note that `__ORACLE_ROOT__` is a token specific to the Essbase Docker image that is updated with build argument dynamically (the home of the entire installation can be configured, if needed, but by default will be `/opt/Oracle`).


## Removed Items

The following sections detail specific files that are removed from the build image in an effort to specifically try and minimize the final size of the Essbase image. They mostly represent fairly low-hanging fruit whose removal is not meant to jeopardize the functionality or viability of the system. It is possible, however, that some functionality or processes are in fact impacted by these items being removed. If this happens to be the case, it may be necessary to disable/comment out a specific removal and rebuild the image.


### Remove JRockit and consolidate references to supplied JDK6

The default EPM install will include a Java 1.6 JDK, a JRockit JRE, and even additional JREs installed in various common folders. This install removes JRockit altogether (WebLogic this instead run with the normal 1.6 JDK), and symlinks any other JREs buried in the folder structure. This saves hundreds of MB from the overall image.

```
RUN rm -rf $ORACLE_ROOT/Middleware/EPMSystem11R1/common/JRE/Sun/1.6.0 && \
    ln -s  $ORACLE_ROOT/Middleware/jdk160_35/jre $ORACLE_ROOT/Middleware/EPMSystem11R1/common/JRE/Sun/1.6.0
```


### Remove beta Essbase Java agent files

The out-of-the-box EPM 11.1.2.4 install appears to contain some beta files for the Oracle "Cagent" to "Jagent" conversion. This has been a fairly substantial Oracle project (it seems) in an effort to modernize Essbase's core platform. I believe the cloud (OAC) products are running on the Java agent. In any case, there is almost an entire gigabyte of beta files included at `$ORACLE_EPM_HOME/products/Essbase/aps/util` that we don't need (it mostly seems to be ZIP files for different OS flavors).


### Remove 32-bit ODBC files

The entire folder of 32-bit ODBC files is removed (note that 64-bit files are in a sibling `ODBC-64` folder) at `$ORACLE_EPM_HOME/common/ODBC`


### Remove Web Analysis Static Files

We definitely aren't using Web Analysis (`$ORACLE_EPM_HOME/common/epmstatic/webanalysis`) so we don't need to waste space on its numerous files, which also includes Windows executables for two different JRE installers (!).


### Remove 32-bit Essbase Server Files

The Essbase installer includes files for both 32-bit and 64-bit flavors of Essbase. As we aren't concerned with 32-bit, we can discard the files (`$ORACLE_EPM_HOME/products/Essbase/EssbaseServer-32`).


### Remove applied OPatch patches

Even the vanilla EPM installer comes with some built-in OPatch-sets that seem to get applied during the install process, but their files are left behind. They consume a considerable amount of space (`$ORACLE_ROOT/Middleware/oracle_common/OPatch/Patches`).
    
    
## Running Essbase image only while using SQL Server on your host machine for the EPM repositories:

Rather than using the SQL Server on Linux database as your EPM repository backend, you may already have SQL Server installed on your local workstation and want to use that instead. You can accomplish this with the following technique, assuming that the image is built and available in your repository:

```
docker run -it -e SQL_HOST=host.docker.internal -e SQL_USER=sa -e "SQL_PASSWORD=<your sa password>" essbase:11.1.2.4
```
