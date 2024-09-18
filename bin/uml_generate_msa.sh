#!/bin/bash

#
# Script created according to MagicDraw documentation file Specifying_batch_mode_program_classpath_and_required_system_properties.html
# 
# This script will only work with MagicDraw 2024x or later.
#

if [ -z "$MAGICDRAW_HOME" ]; then
    echo "MAGICDRAW_HOME environment variable not set, please set it to the MagicDraw installation folder"
    exit 1
fi

# Reads CLASSPATH value from magicdraw.properties files (change to your properties file name)
MD_CLASSPATH=`grep "CLASSPATH" $MAGICDRAW_HOME/bin/msa.properties | cut -d'=' -f 2`

# prepend MAGICDRAW_HOME to classpath
MD_CLASSPATH="$MAGICDRAW_HOME/$MD_CLASSPATH"

# add path to plugin
MD_CLASSPATH="$MD_CLASSPATH:$MAGICDRAW_HOME/plugins/org.openehr.adoc.magicdraw/UmlAdocExporter.jar"

# Adjust CP for operating system
if [ "$OS" = Windows_NT ]; then
    MD_CLASSPATH=$(echo "$MD_CLASSPATH" | sed "s/\\\:/;/g")
else
    MD_CLASSPATH=$(echo "$MD_CLASSPATH" | sed "s/\\\:/:/g")
fi

echo " class path = $MD_CLASSPATH"

# Note that the version of java needed in the final invocation of this script is Java17 or later
java -Xmx1200M -Xss1024K \
       -cp "$MD_CLASSPATH" \
       -Desi.system.config="$MAGICDRAW_HOME/data/application.conf" \
       -Dfile.encoding=UTF-8 \
       @$MAGICDRAW_HOME/bin/vm.options \
       org.openehr.adoc.magicdraw.UmlAdocExporterCommandLine "$@"

