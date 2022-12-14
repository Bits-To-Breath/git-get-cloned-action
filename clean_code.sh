OUT_FILE=reference_only_entrypoint.clean.sh
echo "### CODER DO NOT CHANGE! ###" > $OUT_FILE
echo "### WILL BE OVERWRITTEN! ###" >> $OUT_FILE
sed -E '/^\s*#/d' entrypoint.sh | sed -E "s/[ \t]+# .*//" | sed -E "/^$/N;/^\n$/D" >> $OUT_FILE
