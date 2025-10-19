#!/usr/bin/bash

# Observaciones: Copiar el script en /usr/local/bin

# Definir la cuenta del usuario para ubicar el archivo vacaciones.txt
#  ej: brivas
USUARIO=brivas

# URL del API de feriados
API_FERIADOS_URL="https://feriados.net/api/feriados"

# Respaldo local de feriados en caso de que la API no esté disponible
FERIADOS_LOCAL_BKUP="/home/$USUARIO/feriados.json"

# Archivo de vacaciones adicionales
VACACIONES_FILE="/home/$USUARIO/vacaciones.txt"

# Archivo de log
APAGADO_LOG="/home/$USUARIO/apagado.log"

# Obtener la fecha de hoy en formato YYYY-MM-DD
HOY=$(date +%Y-%m-%d)
DATE_FOR_LOG=$(date "+%F "%T)

if [[ ! -f "$FERIADOS_LOCAL_BKUP" ]]; then
    echo "[ $DATE_FOR_LOG ] - Creando el archivo local con las fechas de los feriados: $FERIADOS_LOCAL_BKUP" >> "$APAGADO_LOG"

    echo '{
  "feriados": [
    "'$(date +%Y)'-01-01",
    "'$(date +%Y)'-05-01",
    "'$(date +%Y)'-05-30",
    "'$(date +%Y)'-07-19",
    "'$(date +%Y)'-09-14",
    "'$(date +%Y)'-09-15",
    "'$(date +%Y)'-12-08",
    "'$(date +%Y)'-12-25"
  ]
}' > "$FERIADOS_LOCAL_BKUP"
fi

### Función para programar el apagado a las 7 PM
programar_apagado_a_las_7pm() {
    local HORA_APAGADO="18:00"
    # Programar el apagado
    shutdown -h "$HORA_APAGADO"
    echo "[ $DATE_FOR_LOG ] - Se programó el apagado a las 7:00 PM." >> "$APAGADO_LOG"
}

### Función: Verifica si hoy es sábado o domingo
es_fin_de_semana() {
  local DIA_DE_LA_SEMANA
  DIA_DE_LA_SEMANA=$(date +%u)  # 6 = sábado, 7 = domingo
  if [[ "$DIA_DE_LA_SEMANA" -ge 6 ]]; then
    echo "[ $DATE_FOR_LOG ] - Hoy es fin de semana." >> "$APAGADO_LOG"
    return 0
  else
    return 1
  fi
}

### Función para verificar si una fecha está en una lista
es_fecha_en_lista() {
  local fecha="$1"
  shift
  for f in "$@"; do
    if [[ "$f" == "$fecha" ]]; then
      return 0
    fi
  done
  return 1
}

### Función para cargar FERIADOS ANUALES desde API o respaldo local
cargar_feriados() {
    local URL="$1"
    local respaldo_local="$2"
    local TEMP_FILE="/tmp/feriados.json"
    local STATUS_CODE

    STATUS_CODE=$(curl -s -f -o "$TEMP_FILE" -w "%{http_code}" $URL)

    if [[ "$STATUS_CODE" -ge 200 && "$STATUS_CODE" -lt 300 ]]; then
        echo "[ $DATE_FOR_LOG ] - Feriados obtenidos desde API: $URL" >> "$APAGADO_LOG"
        # Extraer fechas de feriados usando jq  
        FERIADOS_ANUALES=($(jq -r '.feriados[]' "$TEMP_FILE"))
        
        # Actualizar respaldo local
        cp "$TEMP_FILE" "$respaldo_local"
    else
        echo "[ $DATE_FOR_LOG ] - No se pudo acceder al API. Intentando con respaldo local..." >> "$APAGADO_LOG"
        
        # Usar respaldo local si está disponible
        if [[ -f "$respaldo_local" ]]; then
            echo "[ $DATE_FOR_LOG ] - Usando respaldo local: $respaldo_local" >> "$APAGADO_LOG"
            FERIADOS_ANUALES=($(jq -r '.feriados[]' "$respaldo_local"))
        else
            echo "[ $DATE_FOR_LOG ] - No hay respaldo local disponible."
            FERIADOS_ANUALES=()
        fi
    fi

#echo "Lista de feriados desde adentro de la funcion que los carga: ${FERIADOS_ANUALES[@]}"
    rm -f "TEMP_FILE"
}

# Verificar si hoy es fin de semana
if es_fin_de_semana; then
  shutdown -h 0
  echo "[ $DATE_FOR_LOG ] - Hoy es fin de semana, apagando..." >> "$APAGADO_LOG"
  exit 0
else
  echo "[ $DATE_FOR_LOG ] - Hoy es día laboral." >> "$APAGADO_LOG"
fi

cargar_feriados "$API_FERIADOS_URL" "$FERIADOS_LOCAL_BKUP"
#echo "Lista de feriados luego de llamar la funcion: ${FERIADOS_ANUALES[@]}"

# Revisar si hoy es feriado
if es_fecha_en_lista "$HOY" "${FERIADOS_ANUALES[@]}"; then
  echo "[ $DATE_FOR_LOG ] - Hoy es feriado oficial. Apagando..." >> "$APAGADO_LOG"
  shutdown -h 0
  exit 0
fi

# Revisar si hoy está en vacaciones.txt
if [[ -f "$VACACIONES_FILE" ]]; then
  while IFS= read -r fecha; do
    [[ -z "$fecha" ]] && continue  # ignorar líneas vacías
    if [[ "$fecha" == "$HOY" ]]; then
      echo "[ $DATE_FOR_LOG ] - Hoy está marcado como vacaciones para el usuario $USUARIO. Apagando..." >> "$APAGADO_LOG"
      shutdown -h 0
      exit 0
    fi
  done < "$VACACIONES_FILE"
fi

# Si no hay coincidencia
echo "[ $DATE_FOR_LOG ] - Hoy no es feriado ni vacaciones."
programar_apagado_a_las_7pm
