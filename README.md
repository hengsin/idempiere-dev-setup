# Linux script to setup new iDempiere Development environment

## Pre-requisite
* JDK11
* Maven
* Git
* Docker (optionl)

## Usage
* Clone or download to a folder
* At the folder, run ./setup.sh --help to get usage help

## What it does
* Clone idempiere source and run Maven build
* Download and setup Eclipse JEE 2019-12
* Create new workspace at the cloned idempiere folder and import all projects into the workspace
* Set target platform and build the workspace
* Create/sync iDempiere db, setup connection properties (idempiere.properties) and jetty server (jettyhome)
* You should have a ready to run Eclipse workspace after the completion of the script
