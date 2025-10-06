#!/usr/bin/bash

# Observaciones: Copiar el script en /usr/local/bin

# Definir la cuenta del usuario para ubicar el archivo vacaciones.txt
#  ej: brivas
USUARIO=brivas

# Lista de feriados
FERIADOS=(
#2025-10-03  
2025-12-08
2025-12-25
2026-01-01
2026-05-30
2026-07-19
)

# Archivo de vacaciones adicionales
VACACIONES_FILE="/home/$USUARIO/vacaciones.txt"

# Logs de los dias de vacaciones que se apagó
APAGADO_LOG="/home/$USUARIO/apagado.log"

# Obtener la fecha de hoy en formato YYYY-MM-DD
HOY=$(date +%Y-%m-%d)

# Función para programar el apagado a las 7 PM
programar_apagado_a_las_7pm() {
    local HORA_APAGADO="19:00"
    # Programar el apagado
    shutdown -h "$HORA_APAGADO"
    echo "Se programó el apagado a las 7:00 PM." >> "$APAGADO_LOG"
}

# Función: Verifica si hoy es sábado o domingo
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

# Función para verificar si una fecha está en una lista
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

# Verificar si hoy es fin de semana
if [[ es_fin_de_semana -eq 0 ]]; then
  #shutdown -h "$HORA_APAGADO"
  echo "Hoy es $HOY y es fin de semana." >> "$APAGADO_LOG"
  exit 0
fi

if [[ es_fin_de_semana -eq 1 ]]; then
  echo "Hoy es $HOY y es día laboral." >> "$APAGADO_LOG"
  programar_apagado_a_las_7pm
fi

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
