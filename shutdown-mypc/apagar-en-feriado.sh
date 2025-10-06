#!/usr/bin/bash

# Observaciones: Copiar el script en /usr/local/bin

# Definir la cuenta del usuario para ubicar el archivo vacaciones.txt
#  ej: brivas
USUARIO=brivas

# URL del API de feriados
API_FERIADOS_URL="https://agplanilla.net/api/feriados"

# Respaldo local de feriados en caso de que la API no esté disponible
FERIADOS_LOCAL_BKUP="/home/$USUARIO/feriados.json"

# Archivo de vacaciones adicionales
VACACIONES_FILE="/home/$USUARIO/vacaciones.txt"

# Archivo de log
APAGADO_LOG="/home/$USUARIO/apagado.log"

# Obtener la fecha de hoy en formato YYYY-MM-DD
HOY=$(date +%Y-%m-%d)

### Función para programar el apagado a las 7 PM
programar_apagado_a_las_7pm() {
    local HORA_APAGADO="19:00"
    # Programar el apagado
    shutdown -h "$HORA_APAGADO"
    echo "Se programó el apagado a las 7:00 PM." >> "$APAGADO_LOG"
}

### Función: Verifica si hoy es sábado o domingo
es_fin_de_semana() {
  local DIA_DE_LA_SEMANA
  DIA_DE_LA_SEMANA=$(date +%u)  # 6 = sábado, 7 = domingo
  if [[ "$DIA_DE_LA_SEMANA" -ge 6 ]]; then
    echo "Hoy es $HOY y es fin de semana." >> "$APAGADO_LOG"
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
    local url="$1"
    local respaldo_local="$2"

    # Descargar desde API
    local respuesta
    respuesta=$(curl -s -f "$url")

    if [[ $? -eq 0 ]]; then
        echo "Feriados obtenidos desde API: $url" >> "$APAGADO_LOG"
        # Extraer fechas de feriados usando jq  
        FERIADOS_ANUALES=($(echo "$respuesta" | jq -r '.feriados[]'))
        
        # Actualizar respaldo local
        echo "$respuesta" > "$respaldo_local"
    else
        echo "No se pudo acceder al API. Intentando con respaldo local..." >> "$APAGADO_LOG"
        
        # Usar respaldo local si está disponible
        if [[ -f "$respaldo_local" ]]; then
            echo "📁 Usando respaldo local: $respaldo_local" >> "$APAGADO_LOG"
            FERIADOS_ANUALES=($(jq -r '.feriados[]' "$respaldo_local"))
        else
            echo "No hay respaldo local disponible."
            FERIADOS_ANUALES=()
        fi
    return "$FERIADOS_ANUALES"
    fi
}

# Verificar si hoy es fin de semana
if [[ es_fin_de_semana -eq 0 ]]; then
  #shutdown -h "$HORA_APAGADO"
  echo "Hoy es $HOY y es fin de semana." >> "$APAGADO_LOG"
  exit 0
fi

if [[ es_fin_de_semana -eq 1 ]]; then
  echo "Hoy es $HOY y es día laboral. Programando el apagdo a las 19:00hr" >> "$APAGADO_LOG"
  programar_apagado_a_las_7pm
fi

FERIADOS=cargar_feriados "$API_FERIADOS_URL" "$FERIADOS_LOCAL_BKUP"

# Revisar si hoy es feriado
if es_fecha_en_lista "$HOY" "${FERIADOS[@]}"; then
  echo "Hoy ($HOY) es feriado oficial. Apagando..." >> "$APAGADO_LOG"
#  shutdown -h 0
  exit 0
fi

# Revisar si hoy está en vacaciones.txt
if [[ -f "$VACACIONES_FILE" ]]; then
  while IFS= read -r fecha; do
    [[ -z "$fecha" ]] && continue  # ignorar líneas vacías
    if [[ "$fecha" == "$HOY" ]]; then
      echo "Hoy ($HOY) está marcado como vacaciones. Apagando..." >> "$APAGADO_LOG"
#      shutdown -h 0
      exit 0
    fi
  done < "$VACACIONES_FILE"
fi

# Si no hay coincidencia
echo "Hoy ($HOY) no es feriado ni vacaciones."
