#!/usr/bin/env Rscript

# Test script to verify API functionality
library(httr)
library(jsonlite)

# Test endpoints
base_url <- "http://localhost:8001"

cat("Testing AmPEP Microservice API\n")
cat("================================\n\n")

# Test 1: Health Check
cat("1. Testing Health Check...\n")
response <- GET(paste0(base_url, "/health"))
if (status_code(response) == 200) {
  result <- fromJSON(content(response, "text"))
  cat("✅ Health Check Success\n")
  cat("   Status:", result$status, "\n")
  cat("   Model Loaded:", result$model_loaded, "\n")
} else {
  cat("❌ Health Check Failed\n")
}

cat("\n")

# Test 2: Info Endpoint
cat("2. Testing Info Endpoint...\n")
response <- GET(paste0(base_url, "/api/info"))
if (status_code(response) == 200) {
  result <- fromJSON(content(response, "text"))
  cat("✅ Info Endpoint Success\n")
  cat("   Service:", result$service_name, "\n")
  cat("   Version:", result$version, "\n")
} else {
  cat("❌ Info Endpoint Failed\n")
}

cat("\n")

# Test 3: Prediction Endpoint
cat("3. Testing Prediction Endpoint...\n")
test_data <- list(fasta = ">test_sequence\nGLFDIVKKVVGALG")
response <- POST(
  paste0(base_url, "/api/predict"),
  body = toJSON(test_data, auto_unbox = TRUE),
  add_headers("Content-Type" = "application/json")
)

if (status_code(response) == 200) {
  result <- fromJSON(content(response, "text"))
  cat("✅ Prediction Success\n")
  cat("   Status:", result$status, "\n")
  if (!is.null(result$data)) {
    cat("   Predictions:", length(result$data), "\n")
  }
} else {
  result <- fromJSON(content(response, "text"))
  cat("❌ Prediction Failed\n")
  cat("   Error:", result$message, "\n")
}

cat("\n")
cat("Testing completed!\n")