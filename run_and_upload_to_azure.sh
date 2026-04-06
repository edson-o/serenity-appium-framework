#!/usr/bin/env bash


# ---------------------------------------------------------------------------------------------- CONFIGURACION MANUAL
TOKEN=""
ORG_URL="https://dev.azure.com/"
PROJECT="PU"
PLAN_ID=34279
FORMATO_TAG_FEATURE="@TestCaseId:"

# ---------------------------------------------------------------------------------------------- Pipeline
URL_COMMENT="URL del reporte: https://${azSaName}.blob.core.windows.net/${azContainerName}/${BUILD_BUILDID}/index.html"
TEST_CASE_TITLE="Sprint 05-Q1-2026 Automated test mobile QA"
RUNNER_NAME="$1"
SUITE_ID_key="$2"
CUCUMBER_TAG="$3"
RUNNER_PATH="src/test/java/oigo/com/pe/runners" #Ruta donde están los runners de Java
RUNNER_CLASS="com.pe.runners.${RUNNER_NAME}"
AUTH="$USERNAME:$TOKEN"
ENCODED_TOKEN=$(echo -n "$AUTH" | base64 | tr -d '\n') # Codificación del token

html_unescape() {
  echo "$1" | sed 's/&quot;/"/g; s/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g; s/&apos;/'\''/g'
}

# -----------------------------------------------------------------------------------
# ✅  Validar que se pasaron ambos argumentos
if [ -z "$RUNNER_NAME" ] || [ -z "$TEST_CASE_TITLE" ]; then
  echo "X Debes proporcionar el nombre del runner y la descripción."
  echo "Ejemplo: ./run_devAzure.sh RegressionTestRunner \"Descripción del test\""
  exit 1
fi

# ✅  Validar que el runner existe físicamente
RUNNER_FILE="$RUNNER_PATH/$RUNNER_NAME.java"
if [ ! -f "$RUNNER_FILE" ]; then
  echo "X El runner '$RUNNER_NAME' no existe en '$RUNNER_PATH'."
  echo "Runners disponibles:"
  ls -1 "$RUNNER_PATH"/*.java | xargs -n 1 basename | sed 's/.java$//'
  exit 1
fi

# -----------------------------------------------------------------------------------
# Suites definidos manualmente
# Cada ID corresponde a una carpeta real en Azure DevOps
# SmokeTest
# ├── ms-gtm-order-management (34497)
# ├── ms-gtm-classification-management (34496)
# ├── ms-gtm-product-management (34495)
# └── ms-gtm-user-management (34494)

declare -A SUITE_ID_BY_KEY
declare -A SUITE_NAME_BY_ID

SUITE_ID_BY_KEY["suite:login"]=34281
SUITE_ID_BY_KEY["suite:MULTIDIRECCION"]=34351
SUITE_ID_BY_KEY["suite:BUSCADOR"]=34350

for SUITE_KEY in "${!SUITE_ID_BY_KEY[@]}"; do
  SID="${SUITE_ID_BY_KEY[$SUITE_KEY]}"
  SUITE_NAME_BY_ID[$SID]="$SUITE_KEY"
done

SUITE_IDS=()

if [[ "$SUITE_ID_key" == "suite:SmokeTest" ]]; then
  for KEY in "${!SUITE_ID_BY_KEY[@]}"; do
    SUITE_IDS+=("${SUITE_ID_BY_KEY[$KEY]}")
  done
elif [[ "$SUITE_ID_key" == "suite:Regression" ]]; then
  for KEY in "${!SUITE_ID_BY_KEY[@]}"; do
       SUITE_IDS+=("${SUITE_ID_BY_KEY[$KEY]}")
  done
else
  if [[ -z "${SUITE_ID_BY_KEY[$SUITE_ID_key]}" ]]; then
    echo ""
    echo "❌  ERROR: Suite no encontrada -> '$SUITE_ID_key'"
    echo "⚠️ Valores válidos:"
    printf " - %s\n" "${!SUITE_ID_BY_KEY[@]}"
    exit 1
  fi

  SUITE_IDS+=("${SUITE_ID_BY_KEY[$SUITE_ID_key]}")
fi

# ---------------------------------------------------------------------------------------------------------------------
echo ""
echo "✅  Suites a recorrer: ${SUITE_IDS[*]}"
declare -A POINT_BY_TESTCASE

echo "✅  Construyendo mapa global TestCaseId -> pointId (recorriendo suites)..."

for SID in "${SUITE_IDS[@]}"; do
  SUITE_NAME="${SUITE_NAME_BY_ID[$SID]}"
  echo ""
  echo "✅  Leyendo points del suiteId: $SID [$SUITE_NAME]"

  POINT_COUNT=0
  while read -r TCID PID; do
    echo "   * Encontrado → TestCaseId=$TCID | PointId=$PID"

    ((POINT_COUNT++))

    # Guardar SOLO el primer pointId por TestCaseId
    if [[ -z "${POINT_BY_TESTCASE[$TCID]}" ]]; then
      POINT_BY_TESTCASE["$TCID"]="$PID"
    fi
  done < <(
    curl -s -u ":$TOKEN" \
      -H "Accept: application/json" \
      "$ORG_URL/$PROJECT/_apis/test/plans/$PLAN_ID/suites/$SID/points?api-version=7.1-preview.2" |
      jq -r '.value[] | "\(.testCase.id) \(.id)"'
  )
  echo "   ➡️ PointIds encontrados: $POINT_COUNT"
done

echo ""
echo "✅  Mapa construido. Total TestCases mapeados: ${#POINT_BY_TESTCASE[@]}"
echo "✅  Nombre del Run: $TEST_CASE_TITLE"
echo "✅  Nombre del Runner a ejecutar: $RUNNER_NAME"
echo "✅  @tag a ejecutar (por default): '$FORMATO_TAG_FEATURE'"

# ------------------------------------------------------------------------------
# EJECUCIÓN DE PRUEBAS + REPORTE SERENITY (FORZADO Y CONSISTENTE)
# ------------------------------------------------------------------------------
echo ""
echo "➡️ Preparando pruebas con Gradle + Serenity..."

START_TIME=$(( $(date +%s) * 1000 ))
ERROR_LOG_FILE="error_log.txt"

# 0) Limpiar resultados viejos de Serenity (clave para evitar reportes “mezclados”)
rm -rf build
rm -rf target

# 1) Ejecutar tests (sin romper el flujo si fallan)
echo "✅  Ejecutando escenarios con tags: $CUCUMBER_TAG"
echo ""
./gradlew --stop
./gradlew --no-daemon clean test \
  -Dcucumber.filter.tags="$CUCUMBER_TAG" \
  --tests "$RUNNER_CLASS" || true
echo ""
echo "✅  Generando reporte Serenity (aggregate)"
./gradlew --no-daemon aggregate --rerun-tasks

#END_TIME=$(date +%s%3N)
#DURATION_MS=$((END_TIME - START_TIME))
END_TIME=$(( $(date +%s) * 1000 ))
DURATION_MS=$((END_TIME - START_TIME))

# 2) Mostrar paths
SERENITY_REPORT_PATH="target/site/serenity/index.html"
GRADLE_TEST_REPORT_PATH="build/reports/tests/test/index.html"

if [[ -f "$SERENITY_REPORT_PATH" ]]; then
  echo ""
  echo "✅  Reporte Serenity generado: $SERENITY_REPORT_PATH"
else
  echo "❌ No se encontró el reporte Serenity en: $SERENITY_REPORT_PATH"
fi

if [[ -f "$GRADLE_TEST_REPORT_PATH" ]]; then
  echo "✅  Reporte Gradle/JUnit: $GRADLE_TEST_REPORT_PATH"
fi

echo ""
echo "Contenido de $ERROR_LOG_FILE:"
echo ""
cat "$ERROR_LOG_FILE"

# (Opcional) si quieres que el script termine con el estado real de los tests:
# exit $TEST_EXIT_CODE

# ---------------------------------------------------------------------------------------------------------------------
# Validando existencia obligatoria de los parámetros de consola
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "❌ Debes proporcionar el RUNNER_NAME y el TEST_CASE_TITLE como parámetros."
  echo "Ejemplo: ./run_and_upload_to_azure.sh 2622 \"[TC6] Validar perfil de usuario DEX inactivo\""
  exit 1
fi

# ---------------------------------------------------------------------------------------------------------------------
# Ubicación de reportes
HTML_REPORT="target/site/serenity/index.html"
XML_RESULTS=$(find build/test-results/test -type f -name 'TEST-*.xml' ! -name 'TEST-com..runners.Runner.xml')
XML_RESULT=$(echo "$XML_RESULTS" | head -n 1)  # Para el attachment, usamos el primero
echo "✅  XML_RESULT detectado: $XML_RESULT"

# ❗ Validación de archivos generados
if [ ! -f "$HTML_REPORT" ]; then
  echo "❌ No se generó el HTML de Serenity: $HTML_REPORT"
  exit 1
fi

if [[ -z "$XML_RESULTS" ]]; then
  echo "❌ No se encontró el XML de resultados: $XML_RESULT"
  exit 1
fi

if [[ ${#POINT_BY_TESTCASE[@]} -eq 0 ]]; then
  echo "❌ No se mapearon TestCases desde ninguna suite. Revisa:"
  echo "   - PLAN_ID"
  echo "   - SUITE_IDS"
  echo "   - Token / permisos"
  exit 1
fi

# -----------------------------------------------------------------------------------
# 🔁 Obtener todos los TestCaseIds involucrados desde el XML
#TEST_CASE_IDS=$(grep -o '@TestCaseId:[0-9]\+' "$XML_RESULT" | sed 's/@TestCaseId://g' | sort -u)
TEST_CASE_IDS=$(echo "$XML_RESULTS" | xargs grep -oh '@TestCaseId:[0-9]\+' | sed 's/@TestCaseId://g' | sort -u)

if [[ -z "$TEST_CASE_IDS" ]]; then
  echo "❌ No se encontraron @TestCaseId en el XML de resultados."
  exit 1
fi

# 🧠 Obtener todos los pointIds válidos
ALL_POINT_IDS=""

for ID in $TEST_CASE_IDS; do
  POINT_ID="${POINT_BY_TESTCASE[$ID]}"

  if [[ -n "$POINT_ID" ]]; then
    ALL_POINT_IDS+="$POINT_ID,"
  else
    echo "⚠️ No se encontro ningun suite para el TestCaseId $ID"
  fi
done

ALL_POINT_IDS="${ALL_POINT_IDS%,}"

#if [[ -z "$ALL_POINT_IDS" ]]; then
#  echo "❌ No se encontró ningún pointId válido para crear el TestRun."
#  exit 1
#fi

if [[ -z "$ALL_POINT_IDS" ]]; then
  echo "⚠️ Ningún TestCase ejecutado pertenece a las suites configuradas."
  echo "⚠️ El TestRun no se creará, pero la ejecución fue válida."
  exit 0
fi

echo "✅  Todos los pointIds a ejecutar en el TestRun: [$ALL_POINT_IDS]"

# Remover última coma
ALL_POINT_IDS="${ALL_POINT_IDS%,}"

if [[ -z "$ALL_POINT_IDS" ]]; then
  echo "❌ No se encontró ningún suiteId/pointId válido. Verifica si los TestCases están en el plan y suite definidos."
  exit 1
fi

echo "✅  Todos los pointIds a ejecutar en el TestRun: [$ALL_POINT_IDS]"

# --------------------------------------------
# Crear JSON_BODY del Test Run con todos los pointIds
DATE=$(TZ="Etc/GMT+5" date +"%d-%m-%Y %H:%M:%S")
COMPLETED_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
JSON_BODY=$(
  cat <<EOF
{
  "name": "$TEST_CASE_TITLE $DATE",
  "automated": true,
  "plan": { "id": $PLAN_ID },
  "pointIds": [${ALL_POINT_IDS}],
  "state": "InProgress",
  "completedDate": "$COMPLETED_DATE",
  "build": {
    "buildNumber": "2025.06.16.001"
  }
}
EOF
)

echo "JSON enviado al API:"
echo "$JSON_BODY"

# Crear el Test Run
echo ""
echo "➡️ Creando Test Run en Azure DevOps..."
RUN_RESPONSE=$(echo "$JSON_BODY" | curl -s -X POST "$ORG_URL/$PROJECT/_apis/test/runs?api-version=7.1-preview.2" \
  -H "Authorization: Basic $ENCODED_TOKEN" \
  -H "Content-Type: application/json" \
  -d @-)

# Extraer RUN_ID del resultado
RUN_ID=$(echo "$RUN_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [[ -z "$RUN_ID" || "$RUN_ID" == "null" ]]; then
  echo "❌ No se pudo crear el Test Run. Respuesta:"
  echo "$RUN_RESPONSE"
  exit 1
fi

echo "✅  Test Run creado con ID: $RUN_ID"

# -----------------------------------------------------------------------------------
# Codificar el archivo XML a base64
#XML_BASE64=$(base64 -w 0 "$XML_RESULT")
TMP_XML="/tmp/result_tmp_$$.xml"
cp "$XML_RESULT" "$TMP_XML"
XML_BASE64=$(base64 -i "$TMP_XML" | tr -d '\n')
rm -f "$TMP_XML"

# Crear JSON de adjunto para el XML
XML_ATTACHMENT_JSON=$(
  cat <<EOF
{
  "stream": "$XML_BASE64",
  "fileName": "result.xml",
  "comment": "Resultado JUnit adjunto automáticamente",
  "attachmentType": "GeneralAttachment"
}
EOF
)

# Guardar JSON en archivo temporal
XML_ATTACHMENT_FILE_JSON="xml_attachment_payload.json"
echo "$XML_ATTACHMENT_JSON" >"$XML_ATTACHMENT_FILE_JSON"

# Subir archivo .XML
XML_ATTACHMENT_RESPONSE=$(curl -s -X POST "$ORG_URL/$PROJECT/_apis/test/Runs/$RUN_ID/attachments?api-version=7.1-preview.1" \
  -H "Authorization: Basic $ENCODED_TOKEN" \
  -H "Content-Type: application/json" \
  -d @"$XML_ATTACHMENT_FILE_JSON")

echo "Respuesta de Azure DevOps:"
echo "$XML_ATTACHMENT_RESPONSE"

if echo "$XML_ATTACHMENT_RESPONSE" | grep -q '"id"'; then
  echo "✅  Archivo XML subido correctamente como Attachment al Test Run."
else
  echo "❌ Error al subir el archivo XML como adjunto."
  exit 1
fi

# -----------------------------------------------------------------------------------
# Subir archivo .TXT
TXT_EVIDENCE_FILE="build/test-results/test/resumen_CP.txt"

if [[ -f "$TXT_EVIDENCE_FILE" ]]; then
  echo "Encontrado archivo $TXT_EVIDENCE_FILE para subir a Azure DevOps"

  #TXT_BASE64=$(base64 -w0 "$TXT_EVIDENCE_FILE")
  TMP_TXT="/tmp/resumen_tmp_$$.txt"
  cp "$TXT_EVIDENCE_FILE" "$TMP_TXT"
  TXT_BASE64=$(base64 -i "$TMP_TXT" | tr -d '\n')
  rm -f "$TMP_TXT"

  cat >txt_attachment_payload.json <<EOF
{
  "stream": "$TXT_BASE64",
  "fileName": "$(basename $TXT_EVIDENCE_FILE)",
  "comment": "Archivo generado por pruebas automáticas",
  "attachmentType": "GeneralAttachment"
}
EOF

  curl -s -X POST "$ORG_URL/$PROJECT/_apis/test/Runs/$RUN_ID/attachments?api-version=7.1-preview.1" \
    -H "Authorization: Basic $ENCODED_TOKEN" \
    -H "Content-Type: application/json" \
    -d @txt_attachment_payload.json |
    grep -q '"id"' && echo "✅  Archivo TXT subido correctamente como Attachment al Test Run." || {
    echo "❌ Error al subir archivo .txt."
    exit 1
  }
else
  echo "⚠️  No se encontró el archivo $TXT_EVIDENCE_FILE"
fi

# -----------------------------------------------------------------------------------
# ✅  SUBIR TODOS LOS RESULTADOS DE TESTCASEID INVOLUCRADOS AL TEST RUN

# Función para determinar si un TestCaseId tuvo fallos según el archivo SERENITY-JUNIT
set_outcome_for_test_case() {
  local testcase_id="$1"
  local failed_file="build/test-results/test/escenarios_fallidos.txt"

  if [[ -f "$failed_file" ]]; then
    if grep -q "@TestCaseId:$testcase_id" "$failed_file"; then
      echo "Failed"
    else
      echo "Passed"
    fi
  else
    # Solo loguea el mensaje, pero no lo mezcles con el return de la función
    #echo "⚠️ Archivo de escenarios fallidos no encontrado: $failed_file — Se asumirá que todos pasaron" >&2
    echo "Passed"
  fi
}

echo ""
#TEST_CASE_IDS=$(grep -o '@TestCaseId:[0-9]\+' "$XML_RESULT" | sed 's/@TestCaseId://g' | sort -u)
TEST_CASE_IDS=$(echo "$XML_RESULTS" | xargs grep -oh '@TestCaseId:[0-9]\+' | sed 's/@TestCaseId://g' | sort -u)

if [[ -z "$TEST_CASE_IDS" ]]; then
  echo "❌ No se encontraron @TestCaseId en el XML de resultados. Revisa el tag usado."
  exit 1
fi

ALL_PASSED=true
TRUNCATE_RUN=false
for ID in $TEST_CASE_IDS; do
  echo "✅  Procesando resultado del TestCaseId: $ID"

  # Obtener el PointId correspondiente al TestCaseId
  POINT_ID="${POINT_BY_TESTCASE[$ID]}"
  if [[ -z "$POINT_ID" || "$POINT_ID" == "null" ]]; then
    echo "⚠️ No se encontró ningún suite para el testCaseId $ID (se omitirá)"
    TRUNCATE_RUN=true
    echo ""
    continue
  fi

  # Obtener el resultId real creado por Azure
  RESULT_ID=$(curl -s -u :$TOKEN "$ORG_URL/$PROJECT/_apis/test/Runs/$RUN_ID/results?api-version=7.1-preview.6" \
    -H "Content-Type: application/json" | jq ".value[] | select(.testCase.id == \"$ID\") | .id")

  if [[ -z "$RESULT_ID" || "$RESULT_ID" == "null" ]]; then
    echo "❌ No se encontró el resultId para el testCaseId $ID"
    TRUNCATE_RUN=true
    continue
  fi

  TEST_CASE_TITLE="Resultado automatizado para el TestCase $ID"
  OUTCOME=$(set_outcome_for_test_case "$ID")

  echo "➡️ 'Outcome': '$OUTCOME'"

  if [[ "$OUTCOME" != "Passed" ]]; then
    ALL_PASSED=false
  fi

  ESTADO_FILE="build/test-results/test/estado_de_escenarios.txt"
  # Buscar mensaje de error según TestCaseId
  if [[ -f "$ESTADO_FILE" ]]; then
    ERROR_MESSAGE=$(grep "@TestCaseId:$ID" "$ESTADO_FILE" | awk -F'-' '{print $2}' | xargs)
  else
    ERROR_MESSAGE="Sin detalles de ejecución"
  fi

  TEST_RESULT_JSON=$(
    cat <<EOF
[
  {
    "id": $RESULT_ID,
    "testCase": {
      "id": "$ID"
    },
    "testPoint": {
      "id": $POINT_ID
    },
    "testCaseRevision": 1,
    "testCaseTitle": "$TEST_CASE_TITLE",
    "automatedTestName": "$AUTOMATED_TEST_NAME",
    "outcome": "$OUTCOME",
    "state": "Completed",
    "durationInMs": $DURATION_MS,
    "computerName": "$MACHINE_NAME",
    "errorMessage": "$ERROR_MESSAGE",
    "comment": "URL del reporte: "
  }
]
EOF
  )

  #echo "$TEST_RESULT_JSON" > result_patch_payload_$ID.json
  echo "$TEST_RESULT_JSON" >build/test-results/test/result_patch_payload_$ID.json

  #echo "Actualizando resultado del TestCase $ID..."
  RESULT_RESPONSE=$(curl -s -X PATCH "$ORG_URL/$PROJECT/_apis/test/Runs/$RUN_ID/results?api-version=7.1-preview.6" \
    -H "Authorization: Basic $ENCODED_TOKEN" \
    -H "Content-Type: application/json" \
    -d @build/test-results/test/result_patch_payload_$ID.json)

  #echo "$RESULT_RESPONSE" > "build/test-results/test/respuesta_testcase_$ID.json"

  if echo "$RESULT_RESPONSE" | grep -q '"id"'; then
    echo ""
  else
    echo "Error al actualizar resultado del TestCase $ID:"
    echo "$RESULT_RESPONSE"
  fi
done

# ------------------------------------------------------------------------------
# Construir el comentario del Test Run (PASS / FAIL + link Serenity)
# ------------------------------------------------------------------------------
if [[ "$TRUNCATE_RUN" == true ]]; then
  RUN_STATE="Aborted"
else
  RUN_STATE="Completed"
fi

CLOSE_RUN_JSON=$(
  cat <<EOF
{
  "state": "$RUN_STATE",
  "comment": "$URL_COMMENT"
}
EOF
)

CLOSE_RUN_RESPONSE=$(curl -s -X PATCH "$ORG_URL/$PROJECT/_apis/test/runs/$RUN_ID?api-version=7.1-preview.2" \
  -H "Authorization: Basic $ENCODED_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$CLOSE_RUN_JSON")

# ------------------------------------------------------------------------------
# Validar respuesta
# ------------------------------------------------------------------------------

if echo "$CLOSE_RUN_RESPONSE" | grep -q "\"state\":\"$RUN_STATE\""; then
  if [[ "$RUN_STATE" == "Completed" ]]; then
    echo ""
    echo "------------------------------------"
    printf "✅  Test Run %s cerrado... \033[0;32m(Completed)\033[0m\n" "$RUN_ID"
    echo "------------------------------------"
  elif [[ "$RUN_STATE" == "Aborted" ]]; then
    echo ""
    echo "------------------------------------"
    printf "⚠️ Test Run %s cerrado... \033[0;31m(Aborted)\033[0m\n" "$RUN_ID"
    echo "------------------------------------"
  fi
else
  echo "❌ Error al cerrar el Test Run $RUN_ID"
  echo "$CLOSE_RUN_RESPONSE"
fi

# ------------------------------------------------------------------------------
# Limpieza
# ------------------------------------------------------------------------------

rm -f "$ATTACHMENT_FILE_JSON" "$XML_ATTACHMENT_FILE_JSON"