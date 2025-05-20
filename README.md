# Linux scripts to setup new iDempiere Development environment

## Pre-requisite
* [Maven](https://maven.apache.org) (>=3.8.6)
* Git.
* Docker (optional, for installation of postgresql server).
* JDK 17 (optional since Eclipse is now bundle with JRE 17).

Before running the setup.sh script, make sure you have a compatible Maven version

    mvn -version

If you don't have the needed mvn version, download and unpack an appropriate version and set your environment

    export MVN_HOME=/your/mvn/version
    export PATH=$MVN_HOME/bin:$PATH

**NOTE!**

**If building older releases don't work properly, use the appropriate tagged version (see the git tags of this repository).**

## Usage
* Clone or download to a folder.
* If you want to install and run postgresql docker container image, make sure your current login user has the necessary permission to run docker (https://www.baeldung.com/linux/docker-run-without-sudo).

### If you are using zsh instead of bash shell, run the following 2 command to enable bash completion.
```
* Run **autoload bashcompinit**
* Run **bashcompinit**
```

* Run **source completion.bash** to turn on auto completion for bundle shell scripts.
* Run **./setup.sh --help** to get help on options available.

Examples of usage:

    ./setup.sh --branch release-10 --repository-url git@github.com:idempiere/idempiere.git --docker-postgres-create 
    
    ./setup.sh --branch release-10 --docker-postgres-create --db-admin-pass <your-password>

    ./setup.sh --skip-setup-db


## What it does
* Clone idempiere source and run Maven build.
* Download and setup Eclipse JEE 2023-06.
* Create new workspace in the cloned idempiere folder and import all projects into the workspace.
* Set target platform and build the workspace.
* Setup connection properties (idempiere.properties) and jetty server (jettyhome).
* If DB doesn't exists yet, import iDempiere db. 
* If DB exists, apply migration scripts.
* You should have a ready to run Eclipse workspace after the completion of the script.

## Scripts
* Use **--help** option to get help in available options.
* **setup.sh** is the main entry point to invoke other scripts.
* **docker-postgres.sh** - script to install and run postgres 15.3 docker container image.
* **eclipse.sh** - script to start Eclipse IDE.
* **setup-db.sh** - script to setup DB connection propertis (idempiere.propertis), jetty server (jettyhome) and import iDempiere seed database (if DB does not exists) or apply migration scripts (if DB exists).
* **setup-ws.sh** - setup idempiere workspace, set target platform.

## GUI Frontend
* **Python setup.py** to open the GTK front end for **setup.sh**. You can use this to generate and execute command line for **setup.sh**
* **setup.html** a simple html and javascript front end for **setup.sh**. Open in browser to generate command line for **setup.sh**.

## Windows 
* Option 1 is by the use of WSL.
* Option 2 is to use the Git bash shell that's part of the Git installation for Windows.
  * Need to install wget and maven. I uses scoop (https://scoop.sh/) to install both but you can use whatever means you prefer to.
  * Installation of JDK is optional. The script will use the JRE bundle with Eclipse if you don't already have a JDK install.
* Option 3 is to use msys2
  * You can install msys2 with scoop  (https://scoop.sh/) and the installation will goes to "C:\Users\<you user name>\scoop\apps\msys2\current".
  * At the installation folder above, run "ucrt64.exe" to open the msys2 terminal.
  * If you have install wget and maven using scoop, you will have to add "C:\Users\<you user name>\scoop\apps\maven\current\bin"
    and "C:\Users\<you user name>\scoop\apps\wget\current\bin" to your PATH environment variable.
  * To use the python frontend, you need to install python3 and the require dependencies using pacman:
  
    pacman -S python mingw-w64-ucrt-x86_64-gtk3 mingw-w64-ucrt-x86_64-python3 mingw-w64-ucrt-x86_64-python3-gobject
