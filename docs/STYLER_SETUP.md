# AmPEP 專案 Styler 設定指南

## 🎯 概述

本專案已成功整合 **styler** 作為R程式碼格式化工具，類似於Node.js的prettier。styler遵循tidyverse風格指南，確保程式碼的一致性和可讀性。

## 📦 已安裝的組件

### 1. styler 套件
- **版本**: 1.10.3
- **功能**: R程式碼自動格式化
- **風格指南**: tidyverse風格指南

### 2. 配置檔案
- `.stylerignore`: 定義不需要格式化的檔案類型
- `format_project.R`: 專案格式化腳本
- `test_styler.R`: 功能測試腳本

## 🚀 快速開始

### 基本使用

```bash
# 格式化單一檔案
Rscript -e "library(styler); style_file('your_file.R')"

# 格式化整個專案
Rscript format_project.R

# 測試styler功能
Rscript test_styler.R
```

### RStudio 整合

1. 安裝styler後，RStudio會自動顯示Addins選單
2. 在RStudio中選擇：Addins → Styler → Style active file
3. 或使用快捷鍵（如果已設定）

## 📋 格式化規則

### 基本規則
- **縮排**: 2個空格
- **運算子**: 前後加空格 (`=` → ` = `)
- **逗號**: 後加空格 (`, `)
- **引號**: 優先使用雙引號
- **註解**: 以一個空格開始

### 範例

**格式化前:**
```r
x=1+2*3
y<-function(a,b){return(a+b)}
z=c(1,2,3,4,5)
if(x>0){print('positive')}else{print('negative')}
```

**格式化後:**
```r
x <- 1 + 2 * 3
y <- function(a, b) {
  return(a + b)
}
z <- c(1, 2, 3, 4, 5)
if (x > 0) {
  print("positive")
} else {
  print("negative")
}
```

## 🔧 進階配置

### 自定義風格

```r
# 建立自定義風格
custom_style <- function(are_you_sure = FALSE) {
  tidyverse_style(
    indent_by = 4,  # 4個空格縮排
    start_comments_with_one_space = TRUE
  )
}

# 使用自定義風格
style_file("your_file.R", style = custom_style)
```

### 忽略特定檔案

在 `.stylerignore` 中定義：
```
# 忽略非R檔案
*.fasta
*.out
*.log
*.md

# 忽略資料檔案
*.RData
*.csv
```

## 📁 專案結構

```
AmPEP/
├── .stylerignore          # 忽略檔案配置
├── format_project.R       # 專案格式化腳本
├── test_styler.R         # 功能測試腳本
├── predict_amp_by_rf_model.R  # 已格式化的主要腳本
├── predict.R             # 已格式化的預測腳本
└── microservice/         # 微服務目錄（已格式化）
    ├── api/
    ├── config/
    └── tests/
```

## 🧪 測試功能

### 運行測試
```bash
Rscript test_styler.R
```

### 測試輸出
- 顯示格式化前後的程式碼對比
- 測試不同風格選項
- 測試檔案格式化功能
- 自動清理測試檔案

## 📊 格式化統計

### 已格式化的檔案
- ✅ `predict_amp_by_rf_model.R`
- ✅ `predict.R`
- ✅ `test_different_length_seqs.R`
- ✅ `microservice/api/plumber.R`
- ✅ `microservice/config/config.R`
- ✅ `microservice/tests/unit/test_api.R`
- ✅ `test/predict_amp_by_rf_model.R`

## 🔄 持續整合

### Git Hooks (可選)
```bash
# 在 .git/hooks/pre-commit 中加入
#!/bin/sh
Rscript -e "styler::style_dir('.')"
```

### CI/CD 整合
```yaml
# GitHub Actions 範例
- name: Format R code
  run: |
    Rscript -e "install.packages('styler')"
    Rscript -e "styler::style_dir('.')"
```

## 🎨 風格指南

### 命名慣例
- **變數**: 使用小寫和底線 (`my_variable`)
- **函數**: 使用小寫和底線 (`my_function`)
- **常數**: 使用大寫和底線 (`MY_CONSTANT`)

### 程式碼結構
- 函數定義前後空行
- 邏輯區塊間空行
- 適當的縮排層級

## 🐛 故障排除

### 常見問題

1. **套件未安裝**
   ```r
   install.packages("styler")
   ```

2. **權限問題**
   ```bash
   chmod +x format_project.R
   ```

3. **風格函數錯誤**
   - 使用預設的 `tidyverse_style()`
   - 避免複雜的自定義配置

## 📚 參考資源

- [styler 官方文檔](https://styler.r-lib.org/)
- [tidyverse 風格指南](https://style.tidyverse.org/)
- [R 程式碼風格最佳實踐](https://adv-r.had.co.nz/Style.html)

## 🤝 貢獻指南

1. 在提交程式碼前運行格式化
2. 遵循專案的風格指南
3. 使用提供的格式化腳本

---

**最後更新**: 2024年
**版本**: 1.0.0 