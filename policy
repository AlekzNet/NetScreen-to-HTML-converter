#!/bin/ksh

cat $1 | sed -e 's/^set policy id/SETPOLID/' -e 's/ from / /' -e 's/ to / /' | \
while  read kw id fromzone tozone src dst svc rest
do
	if [[ $kw = "SETPOLID" ]]
	then
		while read kw what where
		do
			case $kw in
				SETPOLID)
					continue;;
				exit)
					echo $id $src $dst $svc $fromzone $tozone $rest
					continue 2;;
				set)
					case $what in
						service) 
							svc="${svc};$where";;
						dst-address)
							dst="${dst};$where";;
						src-address)
							src="${src};$where";;
					esac
					continue;;
			esac
		done
	fi
done 
