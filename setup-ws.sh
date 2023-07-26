#!/bin/bash 
ECLIPSE=${ECLIPSE:-eclipse}
IDEMPIERE_SOURCE_FOLDER=${IDEMPIERE_SOURCE_FOLDER:-idempiere}
XTEXT_RUNTIME_REPOSITORY=https://download.eclipse.org/modeling/tmf/xtext/updates/releases/2.31.0
TARGETPLATFORM_DSL_REPOSITORY=https://download.eclipse.org/cbi/updates/tpd/nightly/N202305061445
MWE_REPOSITORY=https://download.eclipse.org/modeling/emft/mwe/updates/releases/2.14.0/
EMF_REPOSITORY=http://download.eclipse.org/modeling/emf/emf/builds/release/2.34.0

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
    --source)
    IDEMPIERE_SOURCE_FOLDER="$2"
    shift # past argument
    shift # past value
    ;;
    --eclipse)
    ECLIPSE="$2"
    shift # past argument
    shift # past value
    ;;
    --help)
    echo "Usage: setup-ws.sh [OPTION]"
    echo ""
    echo -e "  --eclipse <eclipse ide folder>"
    echo -e "\tSet eclipse ide folder (default is eclipse)"
    echo -e "  --source <idempiere source folder>"
    echo -e "\tSet idempiere source folder (default is idempiere)"
    echo -e "  --help"
    echo -e "\tdisplay this help and exit"
    exit 0
    ;;
    --*)
    echo "Unknown option $1"
    exit 1
    ;;
    *)
    POSITIONAL_ARGS+=("$1") # save positional arg
    shift
    ;;
    esac
done

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
if [[ $IDEMPIERE_SOURCE_FOLDER == "/*" ]]; then
	:
else
	IDEMPIERE_SOURCE_FOLDER="$DIR/$IDEMPIERE_SOURCE_FOLDER"	
fi

cd $ECLIPSE
DESTINATION=$(pwd)

echo
echo "*** Install XText Runtime ***"
echo
./eclipse -vm $JAVA_HOME/bin/java -nosplash -data "$IDEMPIERE_SOURCE_FOLDER" -application org.eclipse.equinox.p2.director \
    -repository $XTEXT_RUNTIME_REPOSITORY,$MWE_REPOSITORY,$EMF_REPOSITORY -destination "$DESTINATION" \
    -installIU "org.eclipse.xtext.runtime.feature.group,org.eclipse.xtext.ui.feature.group,org.eclipse.emf.mwe2.runtime,org.eclipse.emf.codegen.ecore.xtext,org.eclipse.emf.ecore.xcore.feature.group" 

echo
echo "*** Install CBI Target Platform DSL Editor ***"
echo
./eclipse -vm $JAVA_HOME/bin/java -nosplash -data "$IDEMPIERE_SOURCE_FOLDER" -application org.eclipse.equinox.p2.director \
    -repository $TARGETPLATFORM_DSL_REPOSITORY -destination "$DESTINATION" \
    -installIU org.eclipse.cbi.targetplatform.feature.feature.group

./eclipse -vm $JAVA_HOME/bin/java -nosplash -data "$IDEMPIERE_SOURCE_FOLDER" -application org.eclipse.ant.core.antRunner -buildfile "$DIR/setup-ws.xml" -Didempiere="$IDEMPIERE_SOURCE_FOLDER"

./eclipse -vm $JAVA_HOME/bin/java -nosplash -data "$IDEMPIERE_SOURCE_FOLDER" -application org.eclipse.ant.core.antRunner -buildfile "$DIR/loadtargetplatform.xml" -Didempiere="$IDEMPIERE_SOURCE_FOLDER"

cd "$DIR"
