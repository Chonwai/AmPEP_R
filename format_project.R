#!/usr/bin/env Rscript
# AmPEP Project Code Formatter
# This script formats all R files in the project using styler

# Load styler package
library(styler)

# Custom style function for AmPEP project
ampep_style <- function(are_you_sure = FALSE) {
  tidyverse_style(
    indent_by = 2,  # 2 spaces indentation
    start_comments_with_one_space = TRUE
  )
}

# Function to format project
format_ampep_project <- function() {
  cat("🎯 Starting AmPEP project formatting...\n")
  
  # Format main R files
  main_files <- c(
    "predict_amp_by_rf_model.R",
    "predict.R",
    "test_different_length_seqs.R"
  )
  
  for (file in main_files) {
    if (file.exists(file)) {
      cat(sprintf("📝 Formatting %s...\n", file))
      tryCatch({
        style_file(file, style = ampep_style)
        cat(sprintf("✅ Successfully formatted %s\n", file))
      }, error = function(e) {
        cat(sprintf("❌ Error formatting %s: %s\n", file, e$message))
      })
    }
  }
  
  # Format microservice R files if they exist
  microservice_dir <- "microservice"
  if (dir.exists(microservice_dir)) {
    cat("🔧 Formatting microservice R files...\n")
    tryCatch({
      style_dir(microservice_dir, style = ampep_style)
      cat("✅ Successfully formatted microservice files\n")
    }, error = function(e) {
      cat(sprintf("❌ Error formatting microservice: %s\n", e$message))
    })
  }
  
  # Format test R files
  test_dir <- "test"
  if (dir.exists(test_dir)) {
    cat("🧪 Formatting test R files...\n")
    tryCatch({
      style_dir(test_dir, style = ampep_style)
      cat("✅ Successfully formatted test files\n")
    }, error = function(e) {
      cat(sprintf("❌ Error formatting test files: %s\n", e$message))
    })
  }
  
  cat("🎉 AmPEP project formatting completed!\n")
}

# Run formatting if script is executed directly
if (!interactive()) {
  format_ampep_project()
} 