# AmPEP Microservice

基於R + plumber的抗菌肽預測微服務。

## 🚀 快速開始

### 本地開發

1. **安裝依賴**
```bash
# 安裝R包
R -e "install.packages(c('plumber', 'jsonlite', 'seqinr', 'randomForest'), repos='https://cran.r-project.org/')"
```

2. **啟動服務**
```bash
# 使用啟動腳本
./scripts/start.sh

# 或直接使用R
R -e "plumber::plumb('api/plumber.R')$run(host='0.0.0.0', port=8001)"
```

3. **測試服務**
```bash
# 健康檢查
curl http://localhost:8001/health

# API文檔
open http://localhost:8001/__docs__/
```

### Docker部署

1. **構建鏡像**
```bash
cd microservice
docker build -f docker/Dockerfile -t ampep-microservice .
```

2. **運行容器**
```bash
docker run -p 8001:8001 ampep-microservice
```

3. **使用docker-compose**
```bash
cd microservice/docker
docker-compose up
```

## 📋 API端點

### 健康檢查
```http
GET /health
```

**響應:**
```json
{
  "status": "healthy",
  "service": "ampep-microservice",
  "version": "1.0.0",
  "timestamp": "2024-01-15T10:30:00Z",
  "model_loaded": true
}
```

### 預測API
```http
POST /api/predict
Content-Type: application/json

{
  "fasta": ">sequence_1\nALWKTMLKKLGTMALHAGKAALGAAADTISQGTQ"
}
```

**響應:**
```json
{
  "status": "success",
  "message": "Prediction completed successfully",
  "data": [
    {
      "sequence_name": "sequence_1",
      "sequence": "ALWKTMLKKLGTMALHAGKAALGAAADTISQGTQ",
      "prediction": "AMP",
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

## 🏗️ 項目結構

```
microservice/
├── api/
│   └── plumber.R          # 主要API文件
├── src/
│   ├── models/            # 模型相關
│   ├── utils/             # 工具函數
│   └── validation/        # 驗證邏輯
├── tests/
│   ├── unit/              # 單元測試
│   ├── integration/       # 集成測試
│   └── fixtures/          # 測試數據
├── config/
│   └── config.R           # 配置文件
├── docker/
│   ├── Dockerfile         # Docker配置
│   └── docker-compose.yml # 容器編排
├── scripts/
│   └── start.sh           # 啟動腳本
└── README.md              # 本文檔
```

## 🔧 配置

### 環境變量

| 變量 | 默認值 | 描述 |
|------|--------|------|
| `PLUMBER_PORT` | 8001 | API服務端口 |
| `PLUMBER_HOST` | 0.0.0.0 | 綁定地址 |
| `R_LOG_LEVEL` | INFO | 日誌級別 |
| `MODEL_PATH` | ../same_def_matlab_100tree_11mtry_rf.mdl | 模型文件路徑 |

### 配置文件

主要配置在 `config/config.R` 中：

- **SERVICE_CONFIG**: 服務基本配置
- **MODEL_CONFIG**: 模型相關配置
- **API_CONFIG**: API行為配置
- **VALIDATION_CONFIG**: 驗證規則配置

## 🧪 測試

### 運行測試
```bash
# 單元測試
R -e "testthat::test_dir('tests/unit')"

# 集成測試
R -e "testthat::test_dir('tests/integration')"
```

### 測試覆蓋率
```bash
# 安裝covr包
R -e "install.packages('covr', repos='https://cran.r-project.org/')"

# 生成覆蓋率報告
R -e "covr::report(covr::package_coverage())"
```

## 📊 監控

### 健康檢查
- 端點: `GET /health`
- 檢查項目: 服務狀態、模型加載、響應時間

### 日誌
- 位置: `logs/ampep-microservice.log`
- 格式: JSON結構化日誌
- 級別: INFO, WARN, ERROR

### 指標
- API響應時間
- 請求成功率
- 內存使用量
- 模型預測準確率

## 🚨 故障排除

### 常見問題

1. **模型加載失敗**
   - 檢查模型文件路徑
   - 確認文件權限
   - 查看錯誤日誌

2. **API響應超時**
   - 檢查序列長度限制
   - 調整超時配置
   - 優化預測算法

3. **內存不足**
   - 增加容器內存限制
   - 優化模型加載
   - 實施緩存機制

### 日誌查看
```bash
# 實時日誌
tail -f logs/ampep-microservice.log

# 錯誤日誌
grep ERROR logs/ampep-microservice.log
```

## 🔄 開發流程

1. **功能開發**
   - 在 `api/plumber.R` 中添加新端點
   - 在 `src/` 中添加業務邏輯
   - 更新配置文件

2. **測試**
   - 編寫單元測試
   - 運行集成測試
   - 檢查代碼覆蓋率

3. **部署**
   - 構建Docker鏡像
   - 運行容器測試
   - 部署到生產環境

## 📚 相關文檔

- [項目管理文檔](../docs/)
- [API規格說明](../docs/technical-specs/)
- [部署指南](../docs/operations/)

---

**版本**: 1.0.0  
**最後更新**: 2024-01-15 