# AmPEP: Antimicrobial Peptide Prediction Tool

[![R](https://img.shields.io/badge/R-4.0+-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Language**: [English](README.md) | [繁體中文](README_zh-TW.md)

AmPEP is a machine learning-based tool for predicting antimicrobial peptides (AMPs) using Random Forest algorithm to determine whether protein sequences have antimicrobial activity.

## 🎯 Key Features

- **High Accuracy Prediction**: Uses optimized Random Forest model (100 trees, mtry=11)
- **Multi-Feature Integration**: Integrates multiple protein descriptors for comprehensive prediction
- **Batch Processing**: Supports batch prediction of FASTA format files
- **Flexible Input**: Supports protein sequences of different lengths
- **Standardized Output**: Provides prediction class and probability scores

## 🔬 Technical Methods

### Machine Learning Model
- **Algorithm**: Random Forest
- **Parameters**: ntree=100, mtry=11
- **Validation**: 10-fold Cross Validation
- **Threshold**: 0.5 (probability ≥ 0.5 predicted as AMP)

### Protein Descriptors
- **AAC** (Amino Acid Composition)
- **PAAC** (Pseudo Amino Acid Composition)
- **APAAC** (Amphiphilic Pseudo Amino Acid Composition)
- **CTD** (Composition-Transition-Distribution) descriptors

### Training Dataset
- **Positive Samples**: 3,298 known antimicrobial peptide sequences
- **Negative Samples**: 9,894 non-antimicrobial peptide sequences

## 📋 System Requirements

### R Version
- R >= 4.0.0

### Required Packages
```r
# Install required R packages
install.packages(c(
  "seqinr",      # Sequence reading and processing
  "caret",       # Machine learning framework
  "protr",       # Protein descriptor calculation
  "MLmetrics",   # Machine learning evaluation metrics
  "ggplot2",     # Data visualization
  "randomForest", # Random Forest algorithm
  "ROCR",        # ROC curve analysis
  "pROC",        # ROC analysis
  "PRROC",       # Precision-Recall and ROC curves
  "psych"        # Psychometric analysis
))
```

## 🚀 Quick Start

### 1. Install Dependencies
```bash
# Install required packages in R
Rscript -e "install.packages(c('seqinr', 'caret', 'protr', 'MLmetrics', 'ggplot2', 'randomForest', 'ROCR', 'pROC', 'PRROC', 'psych'))"
```

### 2. Prepare Input File
Create a FASTA format sequence file:
```
>sequence_1
ALWKTMLKKLGTMALHAGKAALGAAADTISQGTQ
>sequence_2  
AWKKWAKAWKWAKAKWWAKAA
```

### 3. Run Prediction
```bash
# Run prediction using command line
Rscript predict_amp_by_rf_model.R input.fasta output.txt
```

### 4. View Results
```bash
# Output format: sequence_name predicted_class(0/1) AMP_probability
cat output.txt
```

## 📖 Usage Examples

### Basic Usage
```bash
# Predict sequences in sample.fasta
Rscript predict_amp_by_rf_model.R sample.fasta results.out
```

### Example Output
```
AC_1 1 0.970000
AC_2 1 0.720000
sequence_3 0 0.430000
```

**Output Description:**
- **Column 1**: Sequence name
- **Column 2**: Predicted class (1=AMP, 0=non-AMP)
- **Column 3**: AMP probability score (between 0-1)

## 📁 Project Structure

```
AmPEP/
├── predict_amp_by_rf_model.R           # Main prediction script
├── predict.R                           # Alternative prediction script
├── same_def_matlab_100tree_11mtry_rf.mdl  # Pre-trained model
├── trian_po_set3298_for_ampep_sever.fasta # Positive training set
├── trian_ne_set9894_for_ampep_sever.fasta # Negative training set
├── test_different_length_seqs.R        # Testing script
├── sample.fasta                        # Example input file
├── test/                              # Test directory
│   ├── input.fasta                    # Test input
│   ├── test.fasta                     # Test sequences
│   ├── ampep.out                      # Test output
│   └── predict_amp_by_rf_model.R      # Test version
├── README.md                          # Project documentation (English)
└── README_zh-TW.md                    # Project documentation (Traditional Chinese)
```

## ⚠️ Important Notes

### Sequence Requirements
- Only supports standard 20 amino acids (ACDEFGHIKLMNPQRSTVWY)
- Does not support sequences containing unknown amino acids (X, B, Z, etc.)
- Recommended sequence length: 5-200 amino acids

### Input Format
- Must be valid FASTA format
- Sequence identifiers cannot contain spaces
- Short sequence names are recommended

### Performance Notes
- Batch prediction of large files may take considerable time
- Memory usage is proportional to the number of sequences

## 🔧 Advanced Usage

### Custom Feature Extraction
```r
# Load script in R
source("predict_amp_by_rf_model.R")

# Custom feature extraction
sequences <- c("ALWKTMLKKLGTMALHAGKAALGAAADTISQGTQ")
features <- constructDescMatrix(sequences, method='D')
```

### Batch Processing
```bash
# Process multiple files
for file in *.fasta; do
    Rscript predict_amp_by_rf_model.R "$file" "${file%.fasta}.out"
done
```

## 📊 Performance Evaluation

The model demonstrates excellent performance in 10-fold cross-validation:
- **Accuracy**: > 85%
- **Sensitivity**: > 80%
- **Specificity**: > 88%

*Specific performance metrics may vary depending on the test set*

## 🤝 Contributing

Contributions to improve AmPEP are welcome! Please submit Issues and Pull Requests.

### Bug Reports
- Provide complete error messages
- Include input file examples (if applicable)
- Specify your environment and R version

### Feature Requests
- Describe the proposed feature
- Explain the use case
- Provide implementation ideas (if any)

## 📚 Citation

If AmPEP is helpful for your research, please consider citing:

```bibtex
@software{ampep2024,
  title={AmPEP: Antimicrobial Peptide Prediction Tool},
  author={[Author Name]},
  year={2024},
  url={https://github.com/[username]/AmPEP}
}
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Contact

- Bug Reports: [GitHub Issues](https://github.com/[username]/AmPEP/issues)
- Email: [your.email@example.com]

## 🔗 Related Resources

- [Antimicrobial Peptide Database (APD)](http://aps.unmc.edu/AP/)
- [UniProt Protein Database](https://www.uniprot.org/)
- [protr Package Documentation](https://cran.r-project.org/package=protr)

---

**Last Updated**: 2024
**Version**: 1.0.0