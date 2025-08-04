#!/usr/bin/env Rscript

# AmPEP Docker Container Tests
# 測試容器化部署和健康檢查

library(httr)
library(jsonlite)
library(testthat)

# Docker配置
CONTAINER_NAME <- "ampep-microservice"
API_BASE_URL <- "http://localhost:8001"
DOCKER_COMPOSE_FILE <- "../../microservice/docker/docker-compose.yml"

# 輔助函數
run_docker_command <- function(command) {
  result <- system(command, intern = TRUE, ignore.stderr = TRUE)
  return(result)
}

check_container_status <- function() {
  command <- paste0("docker ps --filter name=", CONTAINER_NAME, " --format '{{.Status}}'")
  status <- run_docker_command(command)
  return(length(status) > 0 && grepl("Up", status[1]))
}

get_container_logs <- function() {
  command <- paste0("docker logs ", CONTAINER_NAME, " --tail 50")
  logs <- run_docker_command(command)
  return(logs)
}

wait_for_container_ready <- function(timeout = 60) {
  cat("Waiting for container to be ready...\n")
  start_time <- Sys.time()
  
  while (TRUE) {
    current_time <- Sys.time()
    if (as.numeric(difftime(current_time, start_time, units = "secs")) > timeout) {
      return(FALSE)
    }
    
    # 檢查容器狀態
    if (check_container_status()) {
      # 檢查API健康狀態
      tryCatch({
        response <- GET(paste0(API_BASE_URL, "/health"), timeout(5))
        if (response$status_code == 200) {
          return(TRUE)
        }
      }, error = function(e) {
        # API還不可用，繼續等待
      })
    }
    
    Sys.sleep(2)
  }
}

# 測試函數
test_that("Docker container can be built", {
  # 測試Docker鏡像構建
  cat("Testing Docker image build...\n")
  
  # 檢查Docker是否可用
  docker_version <- run_docker_command("docker --version")
  if (length(docker_version) == 0) {
    skip("Docker is not available")
  }
  
  # 構建鏡像
  build_command <- "cd ../../microservice && docker build -t ampep-test ."
  build_result <- system(build_command, intern = TRUE)
  
  # 驗證構建成功
  expect_equal(attr(build_result, "status"), 0)
  
  cat("✓ Docker image built successfully\n")
})

test_that("Docker container can be started", {
  # 測試容器啟動
  cat("Testing container startup...\n")
  
  # 停止現有容器
  run_docker_command(paste0("docker stop ", CONTAINER_NAME, " 2>/dev/null || true"))
  run_docker_command(paste0("docker rm ", CONTAINER_NAME, " 2>/dev/null || true"))
  
  # 啟動容器
  start_command <- paste0("docker run -d --name ", CONTAINER_NAME, 
                         " -p 8001:8001 ampep-test")
  start_result <- system(start_command, intern = TRUE)
  
  # 驗證容器啟動
  expect_equal(attr(start_result, "status"), 0)
  
  # 等待容器就緒
  expect_true(wait_for_container_ready())
  
  cat("✓ Container started successfully\n")
})

test_that("Container health check works", {
  # 測試容器健康檢查
  cat("Testing container health check...\n")
  
  # 檢查容器狀態
  expect_true(check_container_status())
  
  # 檢查健康檢查端點
  response <- GET(paste0(API_BASE_URL, "/health"))
  expect_equal(response$status_code, 200)
  
  response_data <- fromJSON(rawToChar(response$content))
  expect_equal(response_data$status, "healthy")
  
  cat("✓ Container health check passed\n")
})

test_that("Container logs are accessible", {
  # 測試容器日誌
  cat("Testing container logs...\n")
  
  logs <- get_container_logs()
  expect_true(length(logs) > 0)
  
  # 檢查是否有錯誤日誌
  error_logs <- logs[grepl("error|Error|ERROR", logs)]
  if (length(error_logs) > 0) {
    cat("⚠ Warning: Found error logs:\n")
    cat(paste(error_logs, collapse = "\n"), "\n")
  }
  
  cat("✓ Container logs are accessible\n")
})

test_that("Container resource usage is reasonable", {
  # 測試容器資源使用
  cat("Testing container resource usage...\n")
  
  # 獲取容器資源使用情況
  stats_command <- paste0("docker stats ", CONTAINER_NAME, " --no-stream --format '{{.CPUPerc}} {{.MemUsage}}'")
  stats <- run_docker_command(stats_command)
  
  if (length(stats) > 0) {
    # 解析CPU使用率
    cpu_perc <- as.numeric(gsub("%", "", strsplit(stats[1], " ")[[1]][1]))
    
    # 驗證CPU使用率合理（小於50%）
    expect_true(cpu_perc < 50)
    
    cat(sprintf("✓ CPU usage: %.1f%%\n", cpu_perc))
  }
  
  cat("✓ Resource usage is reasonable\n")
})

test_that("Container can handle API requests", {
  # 測試容器API請求處理
  cat("Testing container API requests...\n")
  
  # 測試健康檢查
  response <- GET(paste0(API_BASE_URL, "/health"))
  expect_equal(response$status_code, 200)
  
  # 測試預測端點
  test_fasta <- ">test_sequence\nACDEFGHIKLMNPQRSTVWY"
  request_body <- list(fasta = test_fasta)
  
  response <- POST(
    paste0(API_BASE_URL, "/api/predict"),
    body = toJSON(request_body, auto_unbox = TRUE),
    content_type("application/json")
  )
  
  expect_equal(response$status_code, 200)
  
  response_data <- fromJSON(rawToChar(response$content))
  expect_true("status" %in% names(response_data))
  
  cat("✓ Container API requests work correctly\n")
})

test_that("Container restart works", {
  # 測試容器重啟
  cat("Testing container restart...\n")
  
  # 重啟容器
  restart_command <- paste0("docker restart ", CONTAINER_NAME)
  restart_result <- system(restart_command, intern = TRUE)
  
  expect_equal(attr(restart_result, "status"), 0)
  
  # 等待容器重新就緒
  expect_true(wait_for_container_ready())
  
  # 驗證API仍然可用
  response <- GET(paste0(API_BASE_URL, "/health"))
  expect_equal(response$status_code, 200)
  
  cat("✓ Container restart works correctly\n")
})

test_that("Docker Compose works", {
  # 測試Docker Compose
  cat("Testing Docker Compose...\n")
  
  # 檢查docker-compose.yml文件
  compose_file <- "../../microservice/docker/docker-compose.yml"
  expect_true(file.exists(compose_file))
  
  # 停止現有容器
  run_docker_command(paste0("docker stop ", CONTAINER_NAME, " 2>/dev/null || true"))
  run_docker_command(paste0("docker rm ", CONTAINER_NAME, " 2>/dev/null || true"))
  
  # 使用docker-compose啟動
  compose_command <- "cd ../../microservice/docker && docker-compose up -d"
  compose_result <- system(compose_command, intern = TRUE)
  
  # 等待容器就緒
  expect_true(wait_for_container_ready())
  
  # 驗證API可用
  response <- GET(paste0(API_BASE_URL, "/health"))
  expect_equal(response$status_code, 200)
  
  cat("✓ Docker Compose works correctly\n")
})

test_that("Container cleanup works", {
  # 測試容器清理
  cat("Testing container cleanup...\n")
  
  # 停止並刪除容器
  stop_command <- paste0("docker stop ", CONTAINER_NAME)
  stop_result <- system(stop_command, intern = TRUE)
  
  rm_command <- paste0("docker rm ", CONTAINER_NAME)
  rm_result <- system(rm_command, intern = TRUE)
  
  # 驗證容器已停止
  expect_false(check_container_status())
  
  cat("✓ Container cleanup works correctly\n")
})

# 性能測試
test_that("Container performance meets requirements", {
  # 測試容器性能
  cat("Testing container performance...\n")
  
  # 確保容器運行
  if (!check_container_status()) {
    skip("Container is not running")
  }
  
  # 測試響應時間
  start_time <- Sys.time()
  response <- GET(paste0(API_BASE_URL, "/health"))
  end_time <- Sys.time()
  
  response_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
  
  # 驗證響應時間小於2秒
  expect_true(response_time < 2)
  
  cat(sprintf("✓ Container response time: %.3f seconds\n", response_time))
})

# 運行測試
if (require(testthat)) {
  cat("Running Docker container tests...\n")
  
  # 檢查Docker是否可用
  docker_version <- run_docker_command("docker --version")
  if (length(docker_version) == 0) {
    cat("Docker is not available. Please install Docker first.\n")
    quit(status = 1)
  }
  
  test_results <- test_dir(".", reporter = "summary")
  
  # 輸出測試摘要
  cat("\n=== Docker測試結果摘要 ===\n")
  cat(sprintf("總測試數: %d\n", length(test_results)))
  cat(sprintf("通過測試: %d\n", sum(sapply(test_results, function(x) x$result == "PASS"))))
  cat(sprintf("失敗測試: %d\n", sum(sapply(test_results, function(x) x$result == "FAIL"))))
  
  # 清理容器
  cat("\nCleaning up containers...\n")
  run_docker_command(paste0("docker stop ", CONTAINER_NAME, " 2>/dev/null || true"))
  run_docker_command(paste0("docker rm ", CONTAINER_NAME, " 2>/dev/null || true"))
  
} else {
  cat("testthat package not available, running basic Docker tests\n")
  
  # 基本Docker測試
  cat("Testing Docker functionality...\n")
  
  # 檢查Docker
  tryCatch({
    docker_version <- run_docker_command("docker --version")
    if (length(docker_version) > 0) {
      cat("✓ Docker is available\n")
    } else {
      cat("✗ Docker is not available\n")
    }
  }, error = function(e) {
    cat("✗ Docker error:", e$message, "\n")
  })
  
  # 檢查容器狀態
  tryCatch({
    if (check_container_status()) {
      cat("✓ Container is running\n")
    } else {
      cat("⚠ Container is not running\n")
    }
  }, error = function(e) {
    cat("✗ Container check error:", e$message, "\n")
  })
} 