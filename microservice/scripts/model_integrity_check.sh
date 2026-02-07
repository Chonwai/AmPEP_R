#!/bin/bash

# AmPEP Model Integrity Check
# Checks RDS readability and API health/predict endpoints

set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-docker-ampep-microservice-1}"
MODEL_PATH="${MODEL_PATH:-/app/same_def_matlab_100tree_11mtry_rf.mdl}"
API_BASE_URL="${API_BASE_URL:-http://localhost:8001}"

info() {
  echo "[INFO] $*"
}

error() {
  echo "[ERROR] $*" >&2
}

if ! command -v docker >/dev/null 2>&1; then
  error "docker 未安裝或不可用"
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  error "curl 未安裝或不可用"
  exit 1
fi

info "檢查容器是否存在: ${CONTAINER_NAME}"
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  error "找不到容器: ${CONTAINER_NAME}"
  exit 1
fi

info "檢查 RDS 檔案可讀性: ${MODEL_PATH}"
if ! docker exec -it "${CONTAINER_NAME}" R -q -e "readRDS('${MODEL_PATH}'); cat('OK\n')" >/dev/null 2>&1; then
  error "readRDS 失敗，請確認模型檔格式或內容是否完整"
  exit 1
fi
info "RDS 可讀性 OK"

info "檢查 /health"
health_response=$(curl -s "${API_BASE_URL}/health" || true)
if ! echo "${health_response}" | grep -q '"model_loaded"\s*:\s*\[true\]'; then
  error "/health 回應異常: ${health_response}"
  exit 1
fi
info "/health OK"

info "檢查 /api/predict"
predict_response=$(curl -s -H "Content-Type: application/json" \
  -d '{"fasta":">seq1\nACDEFGHIK"}' \
  "${API_BASE_URL}/api/predict" || true)
if ! echo "${predict_response}" | grep -q '"status"\s*:\s*"success"'; then
  error "/api/predict 回應異常: ${predict_response}"
  exit 1
fi
info "/api/predict OK"

info "模型完整性檢查完成: OK"
