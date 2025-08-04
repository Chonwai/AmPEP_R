# AmPEP 測試快速開始指南

## 🚀 快速開始

### 1. 安裝依賴

首先確保你已安裝所需的R包：

```r
install.packages(c("testthat", "httr", "jsonlite", "randomForest", "seqinr", "protr"))
```

### 2. 運行所有測試

```bash
Rscript run_tests.R
```

### 3. 運行特定測試

```bash
# 只運行單元測試
Rscript run_tests.R --unit

# 只運行API測試
Rscript run_tests.R --integration

# 只運行Docker測試
Rscript run_tests.R --docker

# 只運行性能測試
Rscript run_tests.R --performance
```

## 📋 測試類型說明

### 單元測試 (Unit Tests)
- **位置**: `tests/unit/test_model.R`
- **功能**: 測試核心預測邏輯、特徵提取、數據驗證
- **運行**: `Rscript tests/unit/test_model.R`

### 集成測試 (Integration Tests)
- **位置**: `tests/integration/test_api.R`
- **功能**: 測試API端點、請求處理、錯誤處理
- **運行**: `Rscript tests/integration/test_api.R`
- **前提**: 需要先啟動微服務

### Docker測試 (Container Tests)
- **位置**: `tests/docker/test_container.R`
- **功能**: 測試容器構建、啟動、健康檢查
- **運行**: `Rscript tests/docker/test_container.R`
- **前提**: 需要安裝Docker

### 性能測試 (Performance Tests)
- **功能**: 測試響應時間、吞吐量
- **運行**: 包含在主測試腳本中
- **前提**: 需要API服務運行

## 🔧 環境準備

### 啟動微服務 (用於API測試)

```bash
# 進入微服務目錄
cd microservice

# 啟動服務
docker-compose up -d

# 檢查服務狀態
curl http://localhost:8001/health
```

### 檢查Docker (用於容器測試)

```bash
# 檢查Docker版本
docker --version

# 檢查Docker Compose
docker-compose --version
```

## 📊 測試結果解讀

### 成功指標
- ✅ 所有測試通過
- ⚠️ 部分測試跳過（依賴不可用）
- ❌ 測試失敗

### 性能基準
- API響應時間: < 2秒
- 預測準確率: > 85%
- 系統可用性: > 99.9%

## 🛠️ 故障排除

### 常見問題

#### 1. 依賴包缺失
```
錯誤: 缺少依賴包: testthat, httr, jsonlite
解決: install.packages(c("testthat", "httr", "jsonlite"))
```

#### 2. API不可用
```
錯誤: API不可用，跳過集成測試
解決: 啟動微服務 - cd microservice && docker-compose up
```

#### 3. Docker不可用
```
錯誤: Docker不可用，跳過Docker測試
解決: 安裝Docker Desktop
```

#### 4. 模型文件缺失
```
錯誤: Model file not found
解決: 確保 same_def_matlab_100tree_11mtry_rf.mdl 文件存在
```

### 調試模式

運行測試時添加詳細輸出：

```bash
Rscript run_tests.R --unit 2>&1 | tee test.log
```

## 📈 持續集成

### GitHub Actions 配置

創建 `.github/workflows/test.yml`:

```yaml
name: AmPEP Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up R
      uses: r-lib/actions/setup-r@v1
      with:
        r-version: '4.2.0'
    
    - name: Install dependencies
      run: |
        R -e "install.packages(c('testthat', 'httr', 'jsonlite', 'randomForest', 'seqinr', 'protr'))"
    
    - name: Run tests
      run: Rscript run_tests.R
```

## 🎯 下一步

1. **完善測試覆蓋率**: 添加更多邊界條件測試
2. **設置監控**: 配置性能監控和警報
3. **自動化部署**: 集成CI/CD管道
4. **文檔更新**: 根據測試結果更新API文檔

## 📞 支持

如果遇到問題：

1. 檢查 `docs/testing-strategy.md` 了解完整測試策略
2. 查看測試日誌文件
3. 確保所有依賴正確安裝
4. 驗證環境配置正確 