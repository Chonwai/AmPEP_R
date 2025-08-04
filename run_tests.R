#!/usr/bin/env Rscript

# AmPEP 測試執行器
# 運行所有類型的測試

library(testthat)
library(httr)
library(jsonlite)

# 配置
TEST_TYPES <- c("unit", "integration", "docker", "performance")
API_BASE_URL <- "http://localhost:8001"

# 顏色輸出
colors <- list(
  green = "\033[32m",
  red = "\033[31m",
  yellow = "\033[33m",
  blue = "\033[34m",
  reset = "\033[0m"
)

print_colored <- function(message, color = "blue") {
  cat(paste0(colors[[color]], message, colors$reset, "\n"))
}

# 檢查依賴
check_dependencies <- function() {
  print_colored("檢查測試依賴...", "blue")
  
  required_packages <- c("testthat", "httr", "jsonlite", "randomForest", "seqinr", "protr")
  missing_packages <- c()
  
  for (pkg in required_packages) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      missing_packages <- c(missing_packages, pkg)
    }
  }
  
  if (length(missing_packages) > 0) {
    print_colored(paste("缺少依賴包:", paste(missing_packages, collapse = ", ")), "red")
    print_colored("請運行: install.packages(c('testthat', 'httr', 'jsonlite'))", "yellow")
    return(FALSE)
  }
  
  print_colored("✓ 所有依賴包已安裝", "green")
  return(TRUE)
}

# 檢查API可用性
check_api_availability <- function() {
  tryCatch({
    response <- GET(paste0(API_BASE_URL, "/health"), timeout(5))
    return(response$status_code == 200)
  }, error = function(e) {
    return(FALSE)
  })
}

# 運行單元測試
run_unit_tests <- function() {
  print_colored("\n=== 運行單元測試 ===", "blue")
  
  if (!file.exists("tests/unit/test_model.R")) {
    print_colored("✗ 單元測試文件不存在", "red")
    return(FALSE)
  }
  
  tryCatch({
    source("tests/unit/test_model.R")
    print_colored("✓ 單元測試完成", "green")
    return(TRUE)
  }, error = function(e) {
    print_colored(paste("✗ 單元測試失敗:", e$message), "red")
    return(FALSE)
  })
}

# 運行集成測試
run_integration_tests <- function() {
  print_colored("\n=== 運行集成測試 ===", "blue")
  
  if (!file.exists("tests/integration/test_api.R")) {
    print_colored("✗ 集成測試文件不存在", "red")
    return(FALSE)
  }
  
  # 檢查API是否可用
  if (!check_api_availability()) {
    print_colored("⚠ API不可用，跳過集成測試", "yellow")
    print_colored("請先啟動微服務: cd microservice && docker-compose up", "yellow")
    return(FALSE)
  }
  
  tryCatch({
    source("tests/integration/test_api.R")
    print_colored("✓ 集成測試完成", "green")
    return(TRUE)
  }, error = function(e) {
    print_colored(paste("✗ 集成測試失敗:", e$message), "red")
    return(FALSE)
  })
}

# 運行Docker測試
run_docker_tests <- function() {
  print_colored("\n=== 運行Docker測試 ===", "blue")
  
  if (!file.exists("tests/docker/test_container.R")) {
    print_colored("✗ Docker測試文件不存在", "red")
    return(FALSE)
  }
  
  # 檢查Docker是否可用
  docker_version <- system("docker --version", intern = TRUE, ignore.stderr = TRUE)
  if (length(docker_version) == 0) {
    print_colored("✗ Docker不可用，跳過Docker測試", "red")
    return(FALSE)
  }
  
  tryCatch({
    source("tests/docker/test_container.R")
    print_colored("✓ Docker測試完成", "green")
    return(TRUE)
  }, error = function(e) {
    print_colored(paste("✗ Docker測試失敗:", e$message), "red")
    return(FALSE)
  })
}

# 運行性能測試
run_performance_tests <- function() {
  print_colored("\n=== 運行性能測試 ===", "blue")
  
  if (!check_api_availability()) {
    print_colored("⚠ API不可用，跳過性能測試", "yellow")
    return(FALSE)
  }
  
  # 測試響應時間
  print_colored("測試API響應時間...", "blue")
  
  response_times <- c()
  for (i in 1:10) {
    start_time <- Sys.time()
    response <- GET(paste0(API_BASE_URL, "/health"))
    end_time <- Sys.time()
    
    response_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
    response_times <- c(response_times, response_time)
    
    Sys.sleep(0.1)
  }
  
  avg_response_time <- mean(response_times)
  max_response_time <- max(response_times)
  
  print_colored(sprintf("平均響應時間: %.3f秒", avg_response_time), "green")
  print_colored(sprintf("最大響應時間: %.3f秒", max_response_time), "green")
  
  # 驗證性能要求
  if (avg_response_time < 2 && max_response_time < 5) {
    print_colored("✓ 性能測試通過", "green")
    return(TRUE)
  } else {
    print_colored("✗ 性能測試失敗", "red")
    return(FALSE)
  }
}

# 生成測試報告
generate_test_report <- function(results) {
  print_colored("\n=== 測試報告 ===", "blue")
  
  total_tests <- length(results)
  passed_tests <- sum(sapply(results, function(x) x == TRUE))
  failed_tests <- total_tests - passed_tests
  
  print_colored(sprintf("總測試類型: %d", total_tests), "blue")
  print_colored(sprintf("通過測試: %d", passed_tests), "green")
  print_colored(sprintf("失敗測試: %d", failed_tests), "red")
  
  # 詳細結果
  for (test_type in names(results)) {
    status <- if (results[[test_type]]) "✓" else "✗"
    color <- if (results[[test_type]]) "green" else "red"
    print_colored(sprintf("%s %s", status, test_type), color)
  }
  
  # 總體評估
  if (failed_tests == 0) {
    print_colored("\n🎉 所有測試通過！", "green")
  } else {
    print_colored(sprintf("\n⚠ %d個測試失敗，請檢查問題", failed_tests), "yellow")
  }
}

# 主函數
main <- function() {
  print_colored("🚀 AmPEP 測試執行器", "blue")
  print_colored("==================", "blue")
  
  # 檢查依賴
  if (!check_dependencies()) {
    quit(status = 1)
  }
  
  # 運行測試
  results <- list()
  
  # 單元測試
  results$unit <- run_unit_tests()
  
  # 集成測試
  results$integration <- run_integration_tests()
  
  # Docker測試
  results$docker <- run_docker_tests()
  
  # 性能測試
  results$performance <- run_performance_tests()
  
  # 生成報告
  generate_test_report(results)
  
  # 返回狀態碼
  if (sum(sapply(results, function(x) x == TRUE)) == length(results)) {
    quit(status = 0)
  } else {
    quit(status = 1)
  }
}

# 命令行參數處理
args <- commandArgs(trailingOnly = TRUE)

if (length(args) > 0) {
  if (args[1] == "--help" || args[1] == "-h") {
    cat("AmPEP 測試執行器\n")
    cat("用法: Rscript run_tests.R [選項]\n")
    cat("選項:\n")
    cat("  --help, -h    顯示幫助信息\n")
    cat("  --unit         只運行單元測試\n")
    cat("  --integration  只運行集成測試\n")
    cat("  --docker       只運行Docker測試\n")
    cat("  --performance  只運行性能測試\n")
    quit(status = 0)
  }
  
  # 根據參數運行特定測試
  if (args[1] == "--unit") {
    print_colored("運行單元測試...", "blue")
    run_unit_tests()
  } else if (args[1] == "--integration") {
    print_colored("運行集成測試...", "blue")
    run_integration_tests()
  } else if (args[1] == "--docker") {
    print_colored("運行Docker測試...", "blue")
    run_docker_tests()
  } else if (args[1] == "--performance") {
    print_colored("運行性能測試...", "blue")
    run_performance_tests()
  }
} else {
  # 運行所有測試
  main()
} 