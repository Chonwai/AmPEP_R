# API端點測試腳本
# 測試AmPEP微服務的各個端點

library(httr)
library(jsonlite)

# 配置
BASE_URL <- "http://127.0.0.1:8001"

# 測試函數
test_endpoint <- function(url, method = "GET", body = NULL) {
  cat("測試:", url, "\n")

  tryCatch(
    {
      if (method == "GET") {
        response <- GET(url)
      } else if (method == "POST") {
        response <- POST(url,
          body = body,
          encode = "json",
          add_headers("Content-Type" = "application/json")
        )
      }

      cat("狀態碼:", status_code(response), "\n")
      content_text <- content(response, "text", encoding = "UTF-8")
      cat("響應:", content_text, "\n")
      cat("---\n")

      return(list(
        status = status_code(response),
        content = content_text
      ))
    },
    error = function(e) {
      cat("錯誤:", e$message, "\n")
      cat("---\n")
      return(list(status = -1, content = e$message))
    }
  )
}

# 啟動API服務
cat("啟動API服務...\n")
pr_process <- callr::r_bg(function() {
  library(plumber)
  pr <- plumb("api/plumber.R")
  pr$run(host = "127.0.0.1", port = 8001)
})

# 等待服務啟動
Sys.sleep(3)

# 測試健康檢查
cat("=== 測試健康檢查端點 ===\n")
health_result <- test_endpoint(paste0(BASE_URL, "/health"))

# 測試服務信息
cat("=== 測試服務信息端點 ===\n")
info_result <- test_endpoint(paste0(BASE_URL, "/api/info"))

# 測試預測端點
cat("=== 測試預測端點 ===\n")
test_fasta <- ">test_sequence\nALWKTMLKKLGTMALHAGKAALGAAADTISQGTQ"
predict_body <- list(fasta = test_fasta)
predict_result <- test_endpoint(paste0(BASE_URL, "/api/predict"), "POST", predict_body)

# 停止服務
cat("停止API服務...\n")
pr_process$kill()

# 總結測試結果
cat("\n=== 測試總結 ===\n")
cat("健康檢查:", ifelse(health_result$status == 200, "✅ 通過", "❌ 失敗"), "\n")
cat("服務信息:", ifelse(info_result$status == 200, "✅ 通過", "❌ 失敗"), "\n")
cat("預測API:", ifelse(predict_result$status %in% c(200, 500), "✅ 響應", "❌ 無響應"), "\n")

cat("\n測試完成！\n")
