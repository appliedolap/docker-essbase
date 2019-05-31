#!/bin/sh

pushd $EPM/OPatch

PATCH_FOLDER=$HOME/patches/$PATCH_LEVEL

if [ -d "$PATCH_FOLDER" ]
then
	for patch in $HOME/patches/$PATCH_LEVEL/*.zip
	do
		[ -f "$patch" ] || continue
		echo $patch
		patch_file=$(basename $patch)
		echo patch file is $patch_file
		patch_num=${patch_file:4:8}
		echo patch num is $patch_num
  		unzip $patch -d $EPM/OPatch
		./opatch apply -silent $EPM/OPatch/$patch_num -oh $EPM -jre $MW/jdk160_35 -invPtrLoc $EPM/oraInst.loc
		echo Removing unzipped files from patch $patch_num
		rm -r $EPM/OPatch/$patch_num
	done
else
	echo The folder $PATCH_FOLDER does not seem to exist, no patches will be applied
fi
	
popd

