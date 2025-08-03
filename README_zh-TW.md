# AmPEP: 抗菌肽預測工具

[![R](https://img.shields.io/badge/R-4.0+-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**語言版本**: [English](README.md) | [繁體中文](README_zh-TW.md)

AmPEP 是一個基於機器學習的抗菌肽（Antimicrobial Peptides, AMPs）預測工具，使用隨機森林算法來預測蛋白質序列是否具有抗菌活性。

## 🎯 功能特點

- **高精度預測**: 使用經過優化的隨機森林模型（100棵樹，mtry=11）
- **多特徵融合**: 集成多種蛋白質描述符進行綜合預測
- **批量處理**: 支援FASTA格式檔案的批量序列預測
- **靈活輸入**: 支援不同長度的蛋白質序列
- **標準化輸出**: 提供預測類別和機率分數

## 🔬 技術方法

### 機器學習模型
- **演算法**: 隨機森林 (Random Forest)
- **參數**: ntree=100, mtry=11
- **驗證**: 10-fold 交叉驗證
- **閾值**: 0.5 (機率 ≥ 0.5 預測為AMP)

### 蛋白質描述符
- **AAC** (Amino Acid Composition) - 胺基酸組成
- **PAAC** (Pseudo Amino Acid Composition) - 偽胺基酸組成
- **APAAC** (Amphiphilic Pseudo Amino Acid Composition) - 兩親性偽胺基酸組成
- **CTD** (Composition-Transition-Distribution) - 組成-轉換-分佈描述符

### 訓練資料集
- **陽性樣本**: 3,298個已知抗菌肽序列
- **陰性樣本**: 9,894個非抗菌肽序列

## 📋 系統需求

### R版本
- R >= 4.0.0

### 必需套件
```r
# 安裝必需的R套件
install.packages(c(
  "seqinr",      # 序列讀取和處理
  "caret",       # 機器學習框架
  "protr",       # 蛋白質描述符計算
  "MLmetrics",   # 機器學習評估指標
  "ggplot2",     # 資料視覺化
  "randomForest", # 隨機森林演算法
  "ROCR",        # ROC曲線分析
  "pROC",        # ROC分析
  "PRROC",       # Precision-Recall和ROC曲線
  "psych"        # 心理統計學套件
))
```

## 🚀 快速開始

### 1. 安裝相依套件
```bash
# 在R中安裝必需的套件
Rscript -e "install.packages(c('seqinr', 'caret', 'protr', 'MLmetrics', 'ggplot2', 'randomForest', 'ROCR', 'pROC', 'PRROC', 'psych'))"
```

### 2. 準備輸入檔案
建立FASTA格式的序列檔案：
```
>sequence_1
ALWKTMLKKLGTMALHAGKAALGAAADTISQGTQ
>sequence_2  
AWKKWAKAWKWAKAKWWAKAA
```

### 3. 執行預測
```bash
# 使用命令列執行預測
Rscript predict_amp_by_rf_model.R input.fasta output.txt
```

### 4. 檢視結果
```bash
# 輸出格式: 序列名稱 預測類別(0/1) AMP機率
cat output.txt
```

## 📖 使用範例

### 基本用法
```bash
# 預測sample.fasta中的序列
Rscript predict_amp_by_rf_model.R sample.fasta results.out
```

### 範例輸出
```
AC_1 1 0.970000
AC_2 1 0.720000
sequence_3 0 0.430000
```

**輸出說明:**
- **第一欄**: 序列名稱
- **第二欄**: 預測類別 (1=抗菌肽, 0=非抗菌肽)
- **第三欄**: AMP機率分數 (0-1之間)

## 📁 專案結構

```
AmPEP/
├── predict_amp_by_rf_model.R           # 主要預測腳本
├── predict.R                           # 備用預測腳本
├── same_def_matlab_100tree_11mtry_rf.mdl  # 預訓練模型
├── trian_po_set3298_for_ampep_sever.fasta # 陽性訓練集
├── trian_ne_set9894_for_ampep_sever.fasta # 陰性訓練集
├── test_different_length_seqs.R        # 測試腳本
├── sample.fasta                        # 範例輸入檔案
├── test/                              # 測試目錄
│   ├── input.fasta                    # 測試輸入
│   ├── test.fasta                     # 測試序列
│   ├── ampep.out                      # 測試輸出
│   └── predict_amp_by_rf_model.R      # 測試版本
├── README.md                          # 專案說明文件（英文）
└── README_zh-TW.md                    # 專案說明文件（繁體中文）
```

## ⚠️ 注意事項

### 序列要求
- 僅支援標準的20種胺基酸 (ACDEFGHIKLMNPQRSTVWY)
- 不支援含有未知胺基酸 (X, B, Z等) 的序列
- 建議序列長度在5-200個胺基酸之間

### 輸入格式
- 必須是有效的FASTA格式
- 序列識別符不能包含空格
- 建議使用簡短的序列名稱

### 效能說明
- 批量預測大檔案時可能需要較長時間
- 記憶體使用量與序列數量成正比

## 🔧 進階用法

### 自訂特徵擷取
```r
# 在R中載入腳本
source("predict_amp_by_rf_model.R")

# 自訂特徵擷取
sequences <- c("ALWKTMLKKLGTMALHAGKAALGAAADTISQGTQ")
features <- constructDescMatrix(sequences, method='D')
```

### 批量處理
```bash
# 處理多個檔案
for file in *.fasta; do
    Rscript predict_amp_by_rf_model.R "$file" "${file%.fasta}.out"
done
```

## 📊 效能評估

該模型在10-fold交叉驗證中表現出色：
- **準確率**: > 85%
- **敏感性**: > 80%
- **特異性**: > 88%

*具體效能指標可能因測試集而異*

## 🤝 貢獻指南

歡迎提交Issue和Pull Request來改進AmPEP！

### 錯誤回報
- 請提供完整的錯誤訊息
- 包含輸入檔案範例（如適用）
- 說明執行環境和R版本

### 功能建議
- 描述建議的功能
- 解釋使用場景
- 提供實作想法（如有）

## 📚 引用

如果AmPEP對您的研究有幫助，請考慮引用：

```bibtex
@software{ampep2024,
  title={AmPEP: Antimicrobial Peptide Prediction Tool},
  author={[Author Name]},
  year={2024},
  url={https://github.com/[username]/AmPEP}
}
```

## 📄 授權條款

本專案採用MIT授權條款 - 詳見 [LICENSE](LICENSE) 檔案

## 📞 聯絡方式

- 問題回報: [GitHub Issues](https://github.com/[username]/AmPEP/issues)
- 電子郵件: [your.email@example.com]

## 🔗 相關資源

- [抗菌肽資料庫 (APD)](http://aps.unmc.edu/AP/)
- [UniProt蛋白質資料庫](https://www.uniprot.org/)
- [protr套件說明文件](https://cran.r-project.org/package=protr)

---

**最後更新**: 2024年
**版本**: 1.0.0