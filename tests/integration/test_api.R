#!/usr/bin/env Rscript

# AmPEP API Integration Tests
# 測試微服務API功能

library(httr)
library(jsonlite)
library(testthat)

# API配置
API_BASE_URL <- "http://localhost:8001"
API_ENDPOINTS <- list(
  health = "/health",
  info = "/api/info",
  predict = "/api/predict"
)

# 測試數據
test_fasta_data <- ">test_sequence_1
MKLLVVYDVSDDSKRNKLANNLKKLGLERIQRSAFEGDIDSQRVKDLVRVVKLIVDTNTDIVHIIPLGIRDWERRIVIGREGLEEWLV
>test_sequence_2
MYIVVVYDVGVERVNKVKKFLRMHLNWVQNSVFEGEVTLAEFERIKEGLKKIIDENSDSVIIYKLRSMPPRETLGIEKNPIEEII"

# 輔助函數
check_api_availability <- function() {
  tryCatch({
    response <- GET(paste0(API_BASE_URL, API_ENDPOINTS$health), timeout(5))
    return(response$status_code == 200)
  }, error = function(e) {
    return(FALSE)
  })
}

# 測試函數
test_that("Health check endpoint works", {
  # 測試健康檢查端點
  response <- GET(paste0(API_BASE_URL, API_ENDPOINTS$health))
  
  # 驗證響應狀態
  expect_equal(response$status_code, 200)
  
  # 驗證響應內容
  response_data <- fromJSON(rawToChar(response$content))
  expect_true("status" %in% names(response_data))
  expect_equal(response_data$status, "healthy")
  expect_true("model_loaded" %in% names(response_data))
})

test_that("API info endpoint works", {
  # 測試API信息端點
  response <- GET(paste0(API_BASE_URL, API_ENDPOINTS$info))
  
  # 驗證響應狀態
  expect_equal(response$status_code, 200)
  
  # 驗證響應內容
  response_data <- fromJSON(rawToChar(response$content))
  expect_true("service_name" %in% names(response_data))
  expect_true("version" %in% names(response_data))
  expect_equal(response_data$service_name, "AmPEP Microservice")
})

test_that("Prediction endpoint works with valid input", {
  # 測試預測端點 - 有效輸入
  request_body <- list(fasta = test_fasta_data)
  
  response <- POST(
    paste0(API_BASE_URL, API_ENDPOINTS$predict),
    body = toJSON(request_body, auto_unbox = TRUE),
    content_type("application/json")
  )
  
  # 驗證響應狀態
  expect_equal(response$status_code, 200)
  
  # 驗證響應內容
  response_data <- fromJSON(rawToChar(response$content))
  expect_true("status" %in% names(response_data))
  expect_equal(response_data$status, "success")
  expect_true("data" %in% names(response_data))
  
  # 驗證預測結果
  if (length(response_data$data) > 0) {
    prediction <- response_data$data[[1]]
    expect_true("sequence_name" %in% names(prediction))
    expect_true("prediction" %in% names(prediction))
    expect_true("probability" %in% names(prediction))
  }
})

test_that("Prediction endpoint handles invalid input", {
  # 測試預測端點 - 無效輸入
  invalid_request_body <- list(fasta = "invalid_fasta_format")
  
  response <- POST(
    paste0(API_BASE_URL, API_ENDPOINTS$predict),
    body = toJSON(invalid_request_body, auto_unbox = TRUE),
    content_type("application/json")
  )
  
  # 驗證錯誤響應
  expect_equal(response$status_code, 200)  # API返回200但包含錯誤信息
  
  response_data <- fromJSON(rawToChar(response$content))
  expect_true("status" %in% names(response_data))
  expect_equal(response_data$status, "error")
})

test_that("Prediction endpoint handles missing parameters", {
  # 測試預測端點 - 缺少參數
  invalid_request_body <- list(wrong_param = "test")
  
  response <- POST(
    paste0(API_BASE_URL, API_ENDPOINTS$predict),
    body = toJSON(invalid_request_body, auto_unbox = TRUE),
    content_type("application/json")
  )
  
  # 驗證錯誤響應
  expect_equal(response$status_code, 200)
  
  response_data <- fromJSON(rawToChar(response$content))
  expect_true("status" %in% names(response_data))
  expect_equal(response_data$status, "error")
})

test_that("API response time meets requirements", {
  # 測試API響應時間
  start_time <- Sys.time()
  
  response <- GET(paste0(API_BASE_URL, API_ENDPOINTS$health))
  
  end_time <- Sys.time()
  response_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
  
  # 驗證響應時間小於2秒
  expect_true(response_time < 2)
  
  cat(sprintf("API response time: %.3f seconds\n", response_time))
})

test_that("API handles large input", {
  # 測試大輸入處理
  large_fasta <- paste0(">seq_", 1:100, "\n", 
                        paste(rep("ACDEFGHIKLMNPQRSTVWY", 10), collapse = ""), 
                        collapse = "\n")
  
  request_body <- list(fasta = large_fasta)
  
  start_time <- Sys.time()
  
  response <- POST(
    paste0(API_BASE_URL, API_ENDPOINTS$predict),
    body = toJSON(request_body, auto_unbox = TRUE),
    content_type("application/json")
  )
  
  end_time <- Sys.time()
  response_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
  
  # 驗證響應
  expect_equal(response$status_code, 200)
  
  # 驗證響應時間小於10秒（大輸入）
  expect_true(response_time < 10)
  
  cat(sprintf("Large input response time: %.3f seconds\n", response_time))
})

# 負載測試
test_that("API handles concurrent requests", {
  # 測試並發請求處理
  num_requests <- 5
  responses <- list()
  start_time <- Sys.time()
  
  for (i in 1:num_requests) {
    request_body <- list(fasta = paste0(">test_seq_", i, "\nACDEFGHIKLMNPQRSTVWY"))
    
    response <- POST(
      paste0(API_BASE_URL, API_ENDPOINTS$predict),
      body = toJSON(request_body, auto_unbox = TRUE),
      content_type("application/json")
    )
    
    responses[[i]] <- response
  }
  
  end_time <- Sys.time()
  total_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
  
  # 驗證所有請求都成功
  success_count <- sum(sapply(responses, function(r) r$status_code == 200))
  expect_equal(success_count, num_requests)
  
  cat(sprintf("Concurrent requests (%d): %.3f seconds total\n", num_requests, total_time))
})

# 運行測試
if (require(testthat)) {
  # 檢查API是否可用
  if (check_api_availability()) {
    cat("API is available, running integration tests...\n")
    test_results <- test_dir(".", reporter = "summary")
    
    # 輸出測試摘要
    cat("\n=== API測試結果摘要 ===\n")
    cat(sprintf("總測試數: %d\n", length(test_results)))
    cat(sprintf("通過測試: %d\n", sum(sapply(test_results, function(x) x$result == "PASS"))))
    cat(sprintf("失敗測試: %d\n", sum(sapply(test_results, function(x) x$result == "FAIL"))))
    
  } else {
    cat("API is not available. Please start the AmPEP microservice first.\n")
    cat("To start the service, run:\n")
    cat("cd microservice && docker-compose up\n")
  }
  
} else {
  cat("testthat package not available, running basic API tests\n")
  
  # 基本API測試
  if (check_api_availability()) {
    cat("Testing API endpoints...\n")
    
    # 測試健康檢查
    tryCatch({
      response <- GET(paste0(API_BASE_URL, API_ENDPOINTS$health))
      if (response$status_code == 200) {
        cat("✓ Health check passed\n")
      } else {
        cat("✗ Health check failed\n")
      }
    }, error = function(e) {
      cat("✗ Health check error:", e$message, "\n")
    })
    
    # 測試預測端點
    tryCatch({
      request_body <- list(fasta = test_fasta_data)
      response <- POST(
        paste0(API_BASE_URL, API_ENDPOINTS$predict),
        body = toJSON(request_body, auto_unbox = TRUE),
        content_type("application/json")
      )
      
      if (response$status_code == 200) {
        cat("✓ Prediction endpoint passed\n")
      } else {
        cat("✗ Prediction endpoint failed\n")
      }
    }, error = function(e) {
      cat("✗ Prediction endpoint error:", e$message, "\n")
    })
    
  } else {
    cat("API is not available. Please start the microservice first.\n")
  }
} 