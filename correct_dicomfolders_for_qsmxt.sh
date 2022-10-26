#!/bin/bash
#script to move dicomsorted (with bidscoin) data to a format more pleasing for QSMxT
#only takes T1w, ASPIRE phase and Siemen's Magnitude image for QSM into new dir.

dicomsorted=/path/to/dicomsorted
qsmxt_raw=/path/to/qsmxt_raw
ses="ses-01"
cd ${dicomsorted}

for x in sub-* ; do 
	mkdir -p ${qsmxt_raw}/${x}/${ses} 
	cd ${dicomsorted}/${x}/${ses} 
       	cp -vr *Aspire_P_* *T1w* ${qsmxt_raw}/${x}/${ses}/
        cp -vr `ls -d *3d-bipolar* | head -n 4 | tail -n 1` ${qsmxt_raw}/${x}/${ses}/
        cp -vr `ls -d *2d_bipolar* | head -n 4 | tail -n 1` ${qsmxt_raw}/${x}/${ses}/
	rm -r ${qsmxt_raw}/${x}/${ses}/*GRE-T1w*
	cd ${qsmxt_raw}/${x}/${ses}
	for y in * ; do mv ${y}/* ./
	done
	find . -type d -empty -delete	
done
