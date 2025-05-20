#!/bin/bash 
ECLIPSE=${ECLIPSE:-eclipse}
INSTALL_COPILOT=false
IDEMPIERE_SOURCE_FOLDER=${IDEMPIERE_SOURCE_FOLDER:-idempiere}
XTEXT_RUNTIME_REPOSITORY=https://download.eclipse.org/modeling/tmf/xtext/updates/releases/2.35.0
TARGETPLATFORM_DSL_REPOSITORY=https://download.eclipse.org/cbi/updates/tpd/nightly/N202403260932
MWE_REPOSITORY=https://download.eclipse.org/modeling/emft/mwe/updates/releases/2.18.0/
EMF_REPOSITORY=https://download.eclipse.org/modeling/emf/emf/builds/release/2.38.0
LSP4_REPOSITORY="https://download.eclipse.org/lsp4e/releases/latest/"
COPILOT_REPOSITORY="https://azuredownloads-g3ahgwb5b8bkbxhd.b01.azurefd.net/github-copilot/"


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
    --install-copilot) 
    INSTALL_COPILOT=true
    shift
    ;;
    --help)
    echo "Usage: setup-ws.sh [OPTION]"
    echo ""
    echo -e "  --eclipse <eclipse ide folder>"
    echo -e "\tSet eclipse ide folder (default is eclipse)"
    echo -e "  --source <idempiere source folder>"
    echo -e "\tSet idempiere source folder (default is idempiere)"
    echo -e "  --install-copilot"
    echo -e "\tAutomaticaly install copilot plugin (default is N)"
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
DESTINATION="$(pwd)"

if [ "$OSTYPE" = "msys" ] ; then
	JUSTJ_BUNDLE="org.eclipse.justj.openjdk.hotspot.jre.full.win32.x86_64_21.0.6.v20250130-0529"
	ECLIPSE_JRE="$(pwd -W)/plugins/$JUSTJ_BUNDLE/jre/"
else
	JUSTJ_BUNDLE="org.eclipse.justj.openjdk.hotspot.jre.full.linux.x86_64_21.0.6.v20250130-0529"	
	ECLIPSE_JRE="$(pwd)/plugins/$JUSTJ_BUNDLE/jre/"
fi

if [ "$JAVA_HOME" = "" ] ; then
	JAVA_HOME="$ECLIPSE_JRE"
fi

echo
echo "*** Install XText Runtime ***"
echo
./eclipse -vm "$ECLIPSE_JRE/bin/java" -nosplash -data "$IDEMPIERE_SOURCE_FOLDER" -application org.eclipse.equinox.p2.director \
    -repository $XTEXT_RUNTIME_REPOSITORY,$MWE_REPOSITORY,$EMF_REPOSITORY -destination "$DESTINATION" \
    -installIU "org.eclipse.xtext.runtime.feature.group,org.eclipse.xtext.ui.feature.group,org.eclipse.emf.mwe2.runtime,org.eclipse.emf.codegen.ecore.xtext,org.eclipse.emf.ecore.xcore.feature.group" 

echo
echo "*** Install CBI Target Platform DSL Editor ***"
echo
./eclipse -vm "$ECLIPSE_JRE/bin/java" -nosplash -data "$IDEMPIERE_SOURCE_FOLDER" -application org.eclipse.equinox.p2.director \
    -repository $TARGETPLATFORM_DSL_REPOSITORY -destination "$DESTINATION" \
    -installIU org.eclipse.cbi.targetplatform.feature.feature.group

./eclipse -vm "$ECLIPSE_JRE/bin/java" -nosplash -data "$IDEMPIERE_SOURCE_FOLDER" -application org.eclipse.ant.core.antRunner -buildfile "$DIR/setup-ws.xml" -Didempiere="$IDEMPIERE_SOURCE_FOLDER"

./eclipse -vm "$ECLIPSE_JRE/bin/java" -nosplash -data "$IDEMPIERE_SOURCE_FOLDER" -application org.eclipse.ant.core.antRunner -buildfile "$DIR/loadtargetplatform.xml" -Didempiere="$IDEMPIERE_SOURCE_FOLDER"

if [ "$INSTALL_COPILOT" = true ]; then
    ./eclipse -vm "$ECLIPSE_JRE/bin/java" -nosplash -data "$IDEMPIERE_SOURCE_FOLDER" -application org.eclipse.equinox.p2.director \
    -repository $LSP4_REPOSITORY,$COPILOT_REPOSITORY -destination "$DESTINATION" \
    -installIU "com.microsoft.copilot.eclipse.feature.feature.group" 
fi

cd "$DIR"
