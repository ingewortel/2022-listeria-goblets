# Need to do this for floating point parameters that have been stored as .0 files


for f in $(ls); do \
	if [[ "$f" == *".0"* ]]; then
		mv $f $( echo $f | sed 's/\.0//g'); 
	fi
done
