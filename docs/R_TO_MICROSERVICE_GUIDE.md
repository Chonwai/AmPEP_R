# R科學計算服務微服務化完整實作指南

## 📋 專案概述

本文檔基於AmPEP專案的實際轉換經驗，提供將R科學計算腳本轉換為生產級微服務的完整方法論。AmPEP是一個抗菌肽預測工具，成功從命令行R腳本轉換為容器化的REST API微服務。

## 🎯 轉換前後對比

### 轉換前 - 傳統R腳本
```bash
# 原始使用方式
Rscript predict_amp_by_rf_model.R input.fasta output.txt

# 特點
- 命令行介面
- 檔案輸入輸出
- 單機運行
- 難以擴展
- 缺乏監控
```

### 轉換後 - 微服務架構
```bash
# Docker運行
docker run -p 8001:8001 ampep-microservice

# API調用
curl -X POST http://localhost:8001/api/predict \
  -H "Content-Type: application/json" \
  -d '{"fasta": ">seq1\nALWKTMLKKLGTMALHAGKAALGAAADTISQGTQ"}'

# 特點
- RESTful API
- JSON輸入輸出
- 容器化部署
- 水平擴展
- 完整監控
```

## 🏗️ 轉換架構設計

### 1. 專案結構設計

```
microservice/
├── api/                          # API層
│   └── plumber.R                # REST API端點定義
├── src/                         # 業務邏輯層
│   ├── models/
│   │   └── ampep_predictor.R    # 核心預測邏輯
│   ├── utils/
│   │   └── helpers.R            # 工具函數
│   └── validation/
│       └── fasta_validator.R    # 輸入驗證
├── config/                      # 配置層
│   └── config.R                 # 配置管理
├── docker/                      # 容器化配置
│   ├── Dockerfile               # 容器構建
│   └── docker-compose.yml       # 容器編排
├── tests/                       # 測試層
│   ├── unit/                    # 單元測試
│   ├── integration/             # 集成測試
│   └── fixtures/                # 測試數據
└── scripts/
    └── start.sh                 # 啟動腳本
```

### 2. 分層架構原則

1. **API層 (plumber.R)**
   - 端點路由定義
   - 請求/響應處理
   - 錯誤處理

2. **業務邏輯層 (src/)**
   - 核心算法實現
   - 數據處理邏輯
   - 驗證機制

3. **配置層 (config/)**
   - 環境配置管理
   - 參數設定
   - 多環境支援

4. **基礎設施層 (docker/)**
   - 容器化配置
   - 部署編排
   - 依賴管理

## 🔧 Docker化實現詳解

### 1. Dockerfile最佳實踐

```dockerfile
# 基礎映像選擇
FROM r-base:4.3.2

# 環境變數設定
ENV R_LIBS_USER=/usr/local/lib/R/library
ENV PLUMBER_PORT=8001
ENV PLUMBER_HOST=0.0.0.0

# 系統依賴安裝 (分層優化)
RUN apt-get update && apt-get install -y \
    build-essential \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# R套件安裝 (關鍵套件優先)
RUN R -e "install.packages('plumber', repos='https://cran.r-project.org/', dependencies=TRUE)" && \
    R -e "if (!require('plumber', quietly=TRUE)) { quit(status=1) }"

RUN R -e "install.packages(c('jsonlite', 'seqinr', 'randomForest', 'caret', 'protr'), repos='https://cran.r-project.org/', dependencies=TRUE)"

# 應用程式部署
WORKDIR /app
COPY microservice/api/ ./api/
COPY microservice/src/ ./src/
COPY microservice/config/ ./config/
COPY same_def_matlab_100tree_11mtry_rf.mdl ./

# 健康檢查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

# 服務啟動
CMD ["R", "-e", "plumber::plumb('api/plumber.R')$run(host='0.0.0.0', port=8001)"]
```

### 2. 關鍵設計決策

1. **基礎映像選擇**
   - 使用官方r-base映像確保穩定性
   - 指定具體版本避免兼容性問題

2. **分層構建策略**
   - 系統依賴、R套件、應用程式分層
   - 優化Docker緩存機制

3. **健康檢查機制**
   - 30秒間隔檢查API健康狀態
   - 支援容器編排自動重啟

## 📡 API微服務設計

### 1. REST API端點設計

```r
# 健康檢查端點
#* @get /health
#* @serializer json
function() {
  list(
    status = "healthy",
    service = "ampep-microservice",
    version = "1.0.0",
    timestamp = Sys.time(),
    model_loaded = model_env$loaded
  )
}

# 預測API端點
#* @post /api/predict
#* @serializer json
function(req) {
  tryCatch({
    # 解析請求
    body <- fromJSON(req$postBody)
    
    # 驗證輸入
    if (is.null(body$fasta)) {
      stop("Missing 'fasta' parameter")
    }
    
    # 處理預測
    sequences <- parse_fasta(body$fasta)
    results <- predict_sequences(sequences)
    
    # 返回結果
    list(
      status = "success",
      message = "Prediction completed successfully",
      data = results,
      metadata = list(
        processing_time = Sys.time(),
        sequences_processed = length(sequences),
        version = "1.0.0"
      )
    )
  }, error = function(e) {
    list(
      status = "error",
      message = e$message,
      error_code = "PROCESSING_ERROR",
      timestamp = Sys.time()
    )
  })
}
```

### 2. 輸入輸出標準化

**請求格式：**
```json
{
  "fasta": ">sequence_1\nALWKTMLKKLGTMALHAGKAALGAAADTISQGTQ\n>sequence_2\nAWKKWAKAWKWAKAKWWAKAA"
}
```

**響應格式：**
```json
{
  "status": "success",
  "message": "Prediction completed successfully",
  "data": [
    {
      "sequence_name": "sequence_1",
      "sequence": "ALWKTMLKKLGTMALHAGKAALGAAADTISQGTQ",
      "prediction": 1,
      "probability": 0.85,
      "method": "ampep"
    }
  ],
  "metadata": {
    "processing_time": "2024-01-15T10:30:00Z",
    "sequences_processed": 1,
    "version": "1.0.0"
  }
}
```

## 🔍 驗證和錯誤處理

### 1. 多層驗證機制

```r
# FASTA格式驗證
validate_fasta <- function(fasta_content) {
  lines <- strsplit(fasta_content, "\n")[[1]]
  
  # 檢查基本格式
  if (length(lines) < 2) return(FALSE)
  if (!grepl("^>", lines[1])) return(FALSE)
  
  # 檢查是否有序列內容
  has_sequence <- any(!grepl("^>", lines[-1]) & nzchar(trimws(lines[-1])))
  return(has_sequence)
}

# 胺基酸序列驗證
validate_sequence <- function(sequence) {
  valid_aa <- "ACDEFGHIKLMNPQRSTVWY"
  sequence_upper <- toupper(sequence)
  all(strsplit(sequence_upper, "")[[1]] %in% strsplit(valid_aa, "")[[1]])
}

# 綜合驗證
validate_sequence_comprehensive <- function(sequence) {
  results <- list(valid = TRUE, errors = c(), warnings = c())
  
  # 檢查序列空值
  if (is.null(sequence) || nchar(sequence) == 0) {
    results$valid <- FALSE
    results$errors <- c(results$errors, "Sequence is empty")
    return(results)
  }
  
  # 檢查胺基酸有效性
  if (!validate_sequence(sequence)) {
    results$valid <- FALSE
    results$errors <- c(results$errors, "Invalid amino acids")
  }
  
  # 檢查長度限制
  if (nchar(sequence) < 5 || nchar(sequence) > 200) {
    results$valid <- FALSE
    results$errors <- c(results$errors, "Sequence length out of range")
  }
  
  return(results)
}
```

### 2. 結構化錯誤響應

```r
# 錯誤響應格式
create_error_response <- function(message, error_code = "PROCESSING_ERROR") {
  list(
    status = "error",
    message = message,
    error_code = error_code,
    timestamp = Sys.time()
  )
}
```

## ⚙️ 配置管理策略

### 1. 分層配置設計

```r
# 服務配置
SERVICE_CONFIG <- list(
  name = "AmPEP Microservice",
  version = "1.0.0",
  port = as.numeric(Sys.getenv("PLUMBER_PORT", 8001)),
  host = Sys.getenv("PLUMBER_HOST", "0.0.0.0"),
  log_level = Sys.getenv("R_LOG_LEVEL", "INFO")
)

# 模型配置
MODEL_CONFIG <- list(
  model_path = Sys.getenv("MODEL_PATH", "../same_def_matlab_100tree_11mtry_rf.mdl"),
  supported_methods = c("ampep"),
  prediction_threshold = 0.5
)

# API配置
API_CONFIG <- list(
  max_request_size = "10MB",
  timeout_seconds = 3600,
  rate_limit = 100,
  cors_enabled = TRUE
)

# 驗證配置
VALIDATION_CONFIG <- list(
  max_sequence_length = 2000,
  min_sequence_length = 5,
  allowed_amino_acids = "ACDEFGHIKLMNPQRSTVWY",
  max_sequences_per_request = 100
)
```

### 2. 環境特定配置

```r
# 環境配置載入
load_environment_config <- function() {
  env <- Sys.getenv("R_ENV", "development")
  
  if (env == "production") {
    SERVICE_CONFIG$log_level <<- "WARN"
    API_CONFIG$timeout_seconds <<- 1800  # 30分鐘
    PERFORMANCE_CONFIG$cache_enabled <<- TRUE
  } else if (env == "testing") {
    SERVICE_CONFIG$log_level <<- "DEBUG"
    API_CONFIG$timeout_seconds <<- 300   # 5分鐘
    PERFORMANCE_CONFIG$cache_enabled <<- FALSE
  }
}
```

## 🧪 測試策略實施

### 1. 單元測試範例

```r
# 驗證函數測試
test_that("FASTA validation works correctly", {
  valid_fasta <- ">test_sequence_1\nALWKTMLKKLGTMALHAGKAALGAAADTISQGTQ"
  invalid_fasta <- "This is not a FASTA file"
  
  expect_true(validate_fasta(valid_fasta))
  expect_false(validate_fasta(invalid_fasta))
  expect_false(validate_fasta(""))
})

# API端點測試
test_that("Health check endpoint returns correct format", {
  health_response <- list(
    status = "healthy",
    service = "ampep-microservice",
    version = "1.0.0",
    timestamp = Sys.time(),
    model_loaded = FALSE
  )
  
  expect_equal(health_response$status, "healthy")
  expect_equal(health_response$service, "ampep-microservice")
})
```

### 2. 集成測試架構

```r
# API集成測試
test_api_integration <- function() {
  # 啟動測試服務器
  pr <- plumber::plumb("api/plumber.R")
  
  # 測試健康檢查
  response <- pr$call("GET", "/health")
  expect_equal(response$status, 200)
  
  # 測試預測端點
  test_data <- list(fasta = ">test\nALWKTMLKKLGTMALHAGKAALGAAADTISQGTQ")
  response <- pr$call("POST", "/api/predict", body = jsonlite::toJSON(test_data))
  expect_equal(response$status, 200)
}
```

## 🚀 部署和運維

### 1. Docker Compose編排

```yaml
version: '3.8'

services:
  ampep-microservice:
    build:
      context: ../../
      dockerfile: microservice/docker/Dockerfile
    ports:
      - "8001:8001"
    environment:
      - R_LOG_LEVEL=INFO
      - PLUMBER_PORT=8001
      - PLUMBER_HOST=0.0.0.0
    volumes:
      - ../logs:/app/logs
      - ../data:/app/data
    networks:
      - ampep-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    restart: unless-stopped

  # 可選監控堆疊
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    networks:
      - ampep-network
    profiles:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-storage:/var/lib/grafana
    networks:
      - ampep-network
    profiles:
      - monitoring

networks:
  ampep-network:
    driver: bridge

volumes:
  grafana-storage:
```

### 2. 監控和日誌

```r
# 結構化日誌
log_message <- function(message, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- list(
    timestamp = timestamp,
    level = level,
    message = message,
    service = "ampep-microservice"
  )
  cat(jsonlite::toJSON(log_entry, auto_unbox = TRUE), "\n")
}

# 性能監控
track_performance <- function(start_time, operation) {
  duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  log_message(paste("Operation", operation, "completed in", duration, "seconds"), "INFO")
}
```

## 📊 性能優化策略

### 1. 模型載入優化

```r
# 全域模型環境
model_env <- new.env()
model_env$model <- NULL
model_env$loaded <- FALSE

# 延遲載入策略
load_model <- function() {
  if (!model_env$loaded) {
    tryCatch({
      model_env$model <- readRDS(MODEL_PATH)
      model_env$loaded <- TRUE
      log_message("Model loaded successfully", "INFO")
    }, error = function(e) {
      log_message(paste("Model loading failed:", e$message), "ERROR")
      model_env$loaded <- FALSE
    })
  }
}
```

### 2. 批量處理優化

```r
# 批量預測處理
predict_sequences <- function(sequences) {
  if (!model_env$loaded) {
    stop("Model not loaded")
  }
  
  results <- list()
  for (seq in sequences) {
    tryCatch({
      # 特徵提取
      test_features <- constructDescMatrix(seq$sequence, 4, "D", class_label = NULL)
      
      # 模型預測
      prediction_probs <- predict(model_env$model, newdata = test_features, type = "vote")
      amp_probability <- prediction_probs[1, 2]
      prediction_class <- if (amp_probability >= 0.5) 1 else 0
      
      # 結果組裝
      result <- list(
        sequence_name = seq$name,
        sequence = seq$sequence,
        prediction = prediction_class,
        probability = round(amp_probability, 6),
        method = "ampep"
      )
      
      results[[length(results) + 1]] <- result
    }, error = function(e) {
      warning(paste("Failed to predict sequence", seq$name, ":", e$message))
      # 錯誤處理...
    })
  }
  
  return(results)
}
```

## 🔐 安全考量

### 1. 輸入清理和驗證

```r
# 輸入清理
sanitize_input <- function(input_string) {
  # 移除潛在危險字符
  input_string <- gsub("[<>\"'&]", "", input_string)
  
  # 限制長度
  if (nchar(input_string) > 10000) {
    input_string <- substr(input_string, 1, 10000)
  }
  
  return(input_string)
}

# 請求大小限制
validate_request_size <- function(req) {
  max_size <- 10 * 1024 * 1024  # 10MB
  if (nchar(req$postBody) > max_size) {
    stop("Request size exceeds limit")
  }
}
```

### 2. 資源限制

```dockerfile
# 容器資源限制
version: '3.8'
services:
  ampep-microservice:
    # ... 其他配置
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
        reservations:
          memory: 512M
          cpus: '0.5'
```

## 📈 可擴展性設計

### 1. 水平擴展支援

```yaml
# 負載均衡配置
version: '3.8'
services:
  ampep-microservice:
    # ... 基本配置
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - ampep-microservice
```

### 2. 快取策略

```r
# 簡單記憶體快取
cache_env <- new.env()

# 快取預測結果
get_cached_prediction <- function(sequence_hash) {
  if (exists(sequence_hash, envir = cache_env)) {
    return(cache_env[[sequence_hash]])
  }
  return(NULL)
}

set_cached_prediction <- function(sequence_hash, result) {
  cache_env[[sequence_hash]] <- result
}

# 序列雜湊
generate_sequence_hash <- function(sequence) {
  digest::digest(sequence, algo = "md5")
}
```

## 📋 最佳實踐檢查清單

### ✅ 開發階段
- [ ] 分析原始R腳本的核心功能和依賴
- [ ] 設計RESTful API端點和資料格式
- [ ] 實施分層架構和模組化設計
- [ ] 建立完整的驗證和錯誤處理機制
- [ ] 撰寫單元測試和集成測試

### ✅ 容器化階段
- [ ] 選擇適當的基礎映像
- [ ] 優化Dockerfile分層結構
- [ ] 實施健康檢查機制
- [ ] 設定環境變數和配置管理
- [ ] 測試容器構建和運行

### ✅ 部署階段
- [ ] 設定Docker Compose編排
- [ ] 配置監控和日誌系統
- [ ] 實施負載測試和性能調優
- [ ] 設定備份和災難恢復策略
- [ ] 建立CI/CD流水線

### ✅ 運維階段
- [ ] 監控服務健康狀態和性能指標
- [ ] 建立告警和通知機制
- [ ] 定期更新和安全補丁
- [ ] 文檔維護和知識共享
- [ ] 容量規劃和擴展策略

## 🚫 常見陷阱和解決方案

### 1. R套件依賴問題
**問題**：R套件安裝失敗或版本衝突
**解決方案**：
- 使用renv進行套件版本管理
- 在Dockerfile中明確指定套件版本
- 分層安裝關鍵套件

### 2. 記憶體洩漏
**問題**：長時間運行後記憶體使用量持續增長
**解決方案**：
- 明確清理臨時物件
- 使用gc()強制垃圾回收
- 監控記憶體使用量

### 3. 模型載入時間
**問題**：大型模型載入時間過長影響服務啟動
**解決方案**：
- 實施模型預載入機制
- 使用健康檢查延遲服務就緒時間
- 考慮模型快取策略

### 4. 併發處理
**問題**：R的單執行緒特性限制併發處理能力
**解決方案**：
- 使用容器水平擴展
- 實施負載均衡
- 考慮使用parallel套件進行平行處理

## 🎯 總結

這份指南基於AmPEP專案的實際轉換經驗，提供了將R科學計算腳本轉換為生產級微服務的完整方法論。關鍵成功因素包括：

1. **系統性分析**：深入理解原始腳本的功能和依賴關係
2. **架構設計**：採用分層架構確保程式碼的可維護性和可擴展性
3. **容器化策略**：優化Docker配置提高部署效率和一致性
4. **完善測試**：建立全面的測試策略確保服務品質
5. **運維監控**：實施完整的監控和日誌系統

通過遵循這個方法論，您可以成功將其他R科學計算服務轉換為現代化的微服務架構，提升系統的可擴展性、可維護性和運營效率。

---

**文檔版本**: 1.0.0  
**最後更新**: 2024年  
**基於專案**: AmPEP Microservice v1.0.0

**相關資源**：
- [AmPEP專案GitHub](https://github.com/[username]/AmPEP)
- [Plumber官方文檔](https://www.rplumber.io/)
- [Docker最佳實踐](https://docs.docker.com/develop/dev-best-practices/)