#!/bin/bash

# set -euxo pipefail

INPUT=$(mktemp)
ROW=$(mktemp)

DAY_IDX=4
LAT_IDX=5
LONG_IDX=7
PLACE_IDX=12
MAGNITUDE_IDX=11

ROW_TARGET="tbody#tbody > tr"

cleanup() {
	rm "$INPUT"
}

trap cleanup EXIT

curl https://www.emsc-csem.org/Earthquake/world/ -s >$INPUT

ROWS=$(cat $INPUT | pup $ROW_TARGET)

COUNT=$(echo $ROWS | grep -o '</tr>' | wc -l)

echo "{"
echo "registers: ["

for i in $(seq 1 $COUNT)
do
	cat $INPUT | pup "${ROW_TARGET}:nth-child($i)" >$ROW
	sed -i -e "s@</td>@</div>@g" $ROW
	sed -i -e "s@<td@<div@g" $ROW
	sed -i -e "s@<tr@<h1@g" $ROW
	sed -i -e "s@</tr>@</h1>@g" $ROW
	FILT_ROW=$(cat $ROW | pup "h1.ligne1, h1.ligne2" | xargs ) 
	if [[ "$FILT_ROW" != "" ]]; then
		#echo $FILT_ROW
		#echo "hello"
		DAY=$(echo $FILT_ROW | pup "div:nth-child($DAY_IDX)" | grep -P '(\d+)[-.\/](\d+)[-.\/](\d+)' -o)
		TIME=$(echo $FILT_ROW | pup "div:nth-child($DAY_IDX)" | grep -P '(\d+)[:.\/](\d+)[:.\/](\d+)' -o)
		LATITUDE=$(echo $FILT_ROW | pup "div:nth-child($LAT_IDX) text{}" | xargs)
		LAT_SIGN=$(echo $FILT_ROW | pup "div:nth-child($(expr $LAT_IDX + 1)) text{}" | xargs)

		case $LAT_SIGN in
			S)
				LAT_SIGN="-";;
			N)
				LAT_SIGN="";;
		esac

		LOG_SIGN=$(echo $FILT_ROW | pup "div:nth-child($(expr $LONG_IDX + 1)) text{}" | xargs)
		case $LOG_SIGN in
			W)
				LOG_SIGN="-";;
			E)
				LOG_SIGN="";;
		esac
		LONGITUDE=$(echo $FILT_ROW | pup "div:nth-child($LONG_IDX) text{}" | xargs) 

		PLACE=$(echo $FILT_ROW | pup "div:nth-child($PLACE_IDX) text{}" | xargs) 

		MAGNITUDE=$(echo $FILT_ROW | pup "div:nth-child($MAGNITUDE_IDX) text{}" | xargs) 


#   echo "$LAT_SIGN$LATITUDE, $LOG_SIGN$LONGITUDE ($PLACE) $MAGNITUDE"
		echo "{"
		echo "  lat: $LAT_SIGN$LATITUDE,"
		echo "  log: $LOG_SIGN$LONGITUDE,"
		echo "  place: '$PLACE',"
		echo "  magnitude: $MAGNITUDE"
		echo -n "}"
		if [[ $i -ne $COUNT ]];then
			echo ","
		else
			echo ""
		fi
	fi
done

echo "]"
echo "}"

