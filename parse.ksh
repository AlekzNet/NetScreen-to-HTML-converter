#!/bin/ksh

TMPGRP=/tmp/grp.tmp
TMPHOSTS=/tmp/hosts.tmp
TMPPOL=/tmp/polcat.tmp
TMPPOLG=/tmp/polcatg.tmp
TMPCAT=/tmp/cat.tmp
TMP1=/tmp/1
TMPSEDH=/tmp/sedh.tmp
TMPSEDGA=/tmp/sedga.tmp
TMPSEDGS=/tmp/sedgs.tmp
EXPRULES=/tmp/exprules
OUTPUT=/tmp/report.html

function recexpand
{
gawk '
	function expand(name,    j,new,elements) {
		elements= split (name, new, ";");
		if ( elements >= 1 )
		{
			for (j=1; j<=elements; j++)
			{
				if ( new[j] == "" ) return;
				if ( a[new[j]] != "" ) 	expand( a[new[j]] );
				else 
				{
					out = ( out == "" ) ? new[j] : out ";" new[j];					
				}
			}
		}
		else 
		{			
			out = ( out == "" ) ? name : out ";" name;			
		}
	return;
	}

/ add / { a[$5]=$7 ";" a[$5];} 

END {
	for (i in a) {
		out = "";
		expand( a[i] );
		output[i] = out;
	}

for (i in output) printf "s%%%s%%%s%%g\n",i,output[i];
}' 
}

#LEU nets
#LEUNETS="129.159.38|129.159.39|192.18.224|129.159.36|129.159.37"
LEUNETS=.

#SED replacement rules for all groups
grep "^set group address" $1 |  recexpand > $TMPSEDGA
grep "^set group service" $1 | sed -e 's/^set group/set group mod/' |  recexpand > $TMPSEDGS




grep "^set address" $1 | sed -e 's/^set address //' | 
while read zone name host rest
do
	if [[ $host = +([0-9]).+([0-9]).+([0-9]).+([0-9]) ]]
		then
			echo $name $host $rest
		else
			hostips=`getent hosts $host | awk '{print $1}'`
			hostips=${hostips:-NOT_RESOLVED}
			echo $name $hostips $host $rest
	fi
done | awk '{printf "s%%%s%%%s %s %s %s<br>%%g\n",$1,$1,$2,$3,$4}' > $TMPSEDH 

./policy.ksh $1 > $TMPPOL

cat $TMPPOL | while read id src dst svc fromzone tozone rest
do
	src=`echo $src | sed -f $TMPSEDGA | sed -f $TMPSEDH`
	dst=`echo $dst | sed -f $TMPSEDGA | sed -f $TMPSEDH`
	svc=`echo $svc | sed -f $TMPSEDGS | sed -e 's@;@<br>@g'`
	exp_policy="<tr id=id$id><td>$id</td><td>$src</td><td>$dst</td><td>$svc</td><td>$fromzone</td><td>$tozone</td><td>$rest</td></tr>"
	echo $exp_policy | egrep $LEUNETS 
done | sed -e 's/";"/ /g' -e 's/"//g' -e 's/;//g' -e 's/255.255.255.255//g' > $TMP1

echo '<html><head><title>'$1'</title></head><body>' > $OUTPUT
echo '<style> .mark { color: #fff; background: #000080; } table {color: #000080; font-size: 10px; border: solid 1px #000080; border-collapse: collapse;} </style>' >> $OUTPUT
echo '<h2>'`head -1 $1 | awk '{print $2}'`'</h2>' >> $OUTPUT
echo '<h3>'`head -2 gmp-spe-fw-1.conf | tail -1`'</h3>' >> $OUTPUT
echo '<table border="1">' >> $OUTPUT
echo '<th >ID</th><th width=40%>Source address</th><th width=40%>Destination address</th><th>Service</th><th>SRC zone</th><th>DST zone</th><th>Comment</th>' >> $OUTPUT
cat $TMP1 >> $OUTPUT
echo "</table> <br /> <p>" >> $OUTPUT

cat $TMPSEDH | sed -e 's/s%//' -e 's/%g//' -e 's/%/ /' | awk '/'$LEUNETS'/{print $2,$3,$4,$5}' >> $OUTPUT

echo "</p></body></html>" >> $OUTPUT
mv $OUTPUT $1.html


