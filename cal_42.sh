#!/bin/bash
# ----------------------------------------------------------------------------------------------------------
# bunter Kalender zur Anzeige in conky
# Farben für Wochentage, Samstage, Sonntage, bundesweite Feiertage, optionale Feiertage, Heute
# können angepaßt werden
# ebenfalls die Ausrichtung des Kalenders
# Der Kalender stellt 6 Wochen dar und ist somit jeden Monat gleich in den Abmaßen
#
# Script 09.2014 Thomas Gollmer
# Nutzung auf eigene Gefahr, tu' damit was immer du willst
# Aufruf in conkyrc an geeigneter Stelle z.B. mit:
# ${font DejaVu Sans Mono:size=12}${execpi 7200 ~/.conky/cal_42.sh}

# ----------------------------------------------------------------------------------------------------------
# Heutiges Datum, für dieses Datum wird der Kalender erstellt
TODAY=$(date +%Y-%m-%d)

# Hier die Farbcodes wie sie conky benötigt... sie werden jedem Tag bei der Ausgabe vorangestellt
# Bitte anpassen !
d0='${color 3f4e64}'                        # Tage die NICHT zu aktuellem Monat gehören
d1='${color b7b0ff}'                        # normale Wochentage (Mo-Fr) aktueller Monat
d2='${color ffb7b0}'                        # Samstage und optionale Feiertage aktueller Monat
d3='${color red}'                           # Sonntage und bundesweite Feiertage aktueller Monat
d4='${color b0ffb7}'                        # HEUTE
c0='${color yellow}'                        # Monat/Jahr Überschrift
c1='${color white}'                         # Texte Mo...So

my=$(date +%B -d "$TODAY")                  # Formatierung Kopfzeile Kalender
al='${alignc}'                              # Ausrichtung des Kalenders in conky
fdz=" "                                     # Führendes Zeichen bei einstelligem Datum (0 oder Leerzeichen)

# ----------------------------------------------------------------------------------------------------------
# Tage zur Kalendererstellung berechnen
td=$(date +%e -d "$TODAY")                  # aktueller Tag (1...31)
tm=$(date +%m -d "$TODAY")                  # aktueller Monat (1...12)
J=$(date +%Y -d "$TODAY")                   # aktuelles Jahr (YYYY)
lmld=$(date +%d -d "$TODAY - $td day")      # letzter Monat, letzter Tag (28...31)
tmp=$(date +%Y-%m-01 -d "$TODAY")
tmp=$(date +%Y-%m-%d -d "$tmp + 1 month")
tmld=$(date +%d -d "$tmp - 1 day")          # aktueller Monat, letzter Tag (28...31)
tmp=$(date +%Y-%m-01 -d "$TODAY")
fwdtm=$(date +%u -d "$tmp")                 # Wochentagsnummer 1. aktueller Monat (1=Mo...7=So)

# ----------------------------------------------------------------------------------------------------------
# Array mit 42 Datümern erstellen. Starttag ist Montag... 6 Wochen bis Sonntag
# Array mit 42 Farbkonstanten erstellen... passend zum Datum-Array

# falls der 1. des Monats KEIN Montag ist, Resttage vom Vormonat mitnehmen
if [ $fwdtm -ne 1 ]; then
  start=$((lmld - fwdtm + 2))
  for ((x=$start;x<=$lmld;x++)); do
    dlst+=("$x")
    clst+=("$d0")
  done
fi
# Tage dieses Monats ergänzen
for ((x=1;x<=$tmld;x++)); do
  if [ $x -lt 10 ]; then dlst+=("$fdz$x"); else dlst+=("$x"); fi
  clst+=("$d1")
done
# Starttage vom nächsten Monat ergänzen bis 42 Datümer voll
x=1
while [ ${#dlst[*]} -lt 42 ]; do
  if [ $x -lt 10 ]; then dlst+=("$fdz$x"); else dlst+=("$x"); fi
  clst+=("$d0")
  ((x++))
done

# ----------------------------------------------------------------------------------------------------------
# Ostersonntag [o] berechnen... um alle anderen beweglichen Feiertage daraus ableiten zu können
# gefunden bei "http://debianforum.de/forum/viewtopic.php?f=34&t=144038"
a=$(( $J % 19 ))
b=$(( $J % 4 ))
c=$(( $J % 7 ))
m=$((( (8 * ($J / 100) + 13) / 25) - 2 ))
s=$(( ($J / 100) - ($J / 400) - 2 ))
M=$(( (15 + $s - $m) % 30 ))
N=$(( (6 + $s) % 7 ))
d=$(( ($M + 19 * $a) % 30 ))
if [ $d = 29 ]; then
  D=28
elif [ $d = 28 -a $a -ge 11 ]; then
  D=27
else
  D=$d
fi
e=$(( (2 * $b + 4 * $c + 6 * $D + $N) % 7 ))
o=$( date -d ${J}-03-21+$(($D + $e + 1))days +%Y-%m-%d )

# ----------------------------------------------------------------------------------------------------------
# Array mit bundeseinheitlichen Feiertagen erstellen:
# Karfreitag, Ostermontag, Himmelfahrt, Pfingstmontag (ausgehend vom Ostersonntag)
# Neujahr, Tag der deutschen Einheit, Weihnachten, 1.Mai (fest)
for t in "-2" "+1" "+39" "+50"; do
  fft+=($(echo "$( date -d ${o}${t}days "+%d.%m")"))
done
fft+=("01.01" "03.10" "25.12" "26.12" "01.05")

# ----------------------------------------------------------------------------------------------------------
# Array mit den optionalen Feiertagen / Brauchtumstagen / halben Feiertagen erstellen:
# Rosenmontag, Fronleichnam (ausgehend vom Ostersonntag)
# Hl.3 Könige, Mariä Himmelfahrt, Reformationstag, Allerheiligen, 24+31 Dez. (fest)
for t in "-48" "+60"; do
  oft+=($(echo "$( date -d ${o}${t}days "+%d.%m")"))
done
oft+=("06.01" "15.08" "31.10" "01.11" "24.12" "31.12")

# ----------------------------------------------------------------------------------------------------------
# Farbarray anpassen optionale Feiertage & Samstage
for ((x=5;x<42;x+=7)); do
  if [ "${clst[$x]}" != "$d0" ]; then clst[$x]="$d2"; fi
done
for t in "${oft[@]}"; do
  m="${t##*.}"
  d="${t%%.*}"
  if [ "$m" = "$tm" ]; then
    d=$(($d + $fwdtm - 2))
    clst[$d]="$d2"
  fi
done

# ----------------------------------------------------------------------------------------------------------
# Farbarray anpassen bundesweite Feiertage & Sonntage
for ((x=6;x<42;x+=7)); do
  if [ "${clst[$x]}" != "$d0" ]; then clst[$x]="$d3"; fi
done
for t in "${fft[@]}"; do
  m="${t##*.}"
  d="${t%%.*}"
  if [ "$m" = "$tm" ]; then
    d=$(($d + $fwdtm - 2))
    clst[$d]="$d3"
  fi
done

# ----------------------------------------------------------------------------------------------------------
# Farbarray anpassen heutiger Tag
h=$(($td + $fwdtm - 2))
clst[$h]="$d4"
# Farb- und Datumsarray zusammenführen
for ((x=0;x<42;x++)); do da+=("${clst[$x]}${dlst[$x]}"); done

# ----------------------------------------------------------------------------------------------------------
# zu jedem Tag liegt in $da[0...41] ein Eintrag vor... 42 Tage beginnend mit Montag, Ende mit Sonntag
# Die müssen jetzt nur noch nach Geschmack plaziert und ausgegeben werden

# Wochentage oben
echo "$al$c0$my"
echo "$al${c1}Mo Di Mi Do Fr Sa So"
echo "$al${da[0]} ${da[1]} ${da[2]} ${da[3]} ${da[4]} ${da[5]} ${da[6]}"
echo "$al${da[7]} ${da[8]} ${da[9]} ${da[10]} ${da[11]} ${da[12]} ${da[13]}"
echo "$al${da[14]} ${da[15]} ${da[16]} ${da[17]} ${da[18]} ${da[19]} ${da[20]}"
echo "$al${da[21]} ${da[22]} ${da[23]} ${da[24]} ${da[25]} ${da[26]} ${da[27]}"
echo "$al${da[28]} ${da[29]} ${da[30]} ${da[31]} ${da[32]} ${da[33]} ${da[34]}"
echo "$al${da[35]} ${da[36]} ${da[37]} ${da[38]} ${da[39]} ${da[40]} ${da[41]}"

# Wochentage links
#echo "$al$c0$my"
#echo "$al${c1}Mo.  ${da[0]} ${da[7]} ${da[14]} ${da[21]} ${da[28]} ${da[35]}"
#echo "$al${c1}Di.  ${da[1]} ${da[8]} ${da[15]} ${da[22]} ${da[29]} ${da[36]}"
#echo "$al${c1}Mi.  ${da[2]} ${da[9]} ${da[16]} ${da[23]} ${da[30]} ${da[37]}"
#echo "$al${c1}Do.  ${da[3]} ${da[10]} ${da[17]} ${da[24]} ${da[31]} ${da[38]}"
#echo "$al${c1}Fr.  ${da[4]} ${da[11]} ${da[18]} ${da[25]} ${da[32]} ${da[39]}"
#echo "$al${c1}Sa.  ${da[5]} ${da[12]} ${da[19]} ${da[26]} ${da[33]} ${da[40]}"
#echo "$al${c1}So.  ${da[6]} ${da[13]} ${da[20]} ${da[27]} ${da[34]} ${da[41]}"

# Lange Leiste
#echo "$al${c1}Mo                   Mo                   Mo                   Mo                   Mo                   Mo                   "
#for x in ${da[@]}
#do
#  line=$(echo "$line$x ")
#done
#echo "$al$line"
