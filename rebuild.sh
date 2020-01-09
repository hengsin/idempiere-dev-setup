cd eclipse
./eclipse -nosplash \
	-application org.eclipse.cdt.managedbuilder.core.headlessbuild \
	-data ../idempiere \
	-cleanBuild all \
	-build all
