#!/bin/bash

pdb="../pdb6h6g.ent"
res1="LYS"
atm1="NZ"
resn1="16"
res2="SER"
atm2="OG"
resn2="8"
#Recuperando pontos x,y,z de dois aminoácidos exemplos:
x1=`egrep "^ATOM *[0-9]+ *NZ *LYS *A *16 " $pdb | awk '{ print substr($0,31,8) }'`
y1=`egrep "^ATOM *[0-9]+ *NZ *LYS *A *16 " $pdb | awk '{ print substr($0,39,8) }'`
z1=`egrep "^ATOM *[0-9]+ *NZ *LYS *A *16 " $pdb | awk '{ print substr($0,47,8) }'`
x2=`egrep "^ATOM *[0-9]+ *OG *SER *A *8 " $pdb | awk '{ print substr($0,31,8) }'`
y2=`egrep "^ATOM *[0-9]+ *OG *SER *A *8 " $pdb | awk '{ print substr($0,39,8) }'`
z2=`egrep "^ATOM *[0-9]+ *OG *SER *A *8 " $pdb | awk '{ print substr($0,47,8) }'`

#Calculando a distância euclidiana entre os modelos acima:
distance=`echo "scale=3;sqrt(($x1-($x2))^2+($y1-($y2))^2+($z1-($z2))^2)" | bc`

echo "A distância entre $res1 $atm1 $resn1 x($x1), y($y1), z($z1) e $res2 $atm2 $resn2 x($x2), y($y2), z($z2) = $distance"
echo

cutoff=3.2
sim=`echo "$distance<=$cutoff" | bc`
if [ $sim -eq 1 ]; then echo "$distance <= $cutoff"; else echo "$distance > $cutoff"; fi
