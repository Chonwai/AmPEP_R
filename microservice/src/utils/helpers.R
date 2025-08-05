# AmPEP Microservice Helper Functions
# Utility functions for data processing and validation

#' Log messages with timestamp
#' @param message The message to log
#' @param level Log level (INFO, WARN, ERROR)
log_message <- function(message, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s] %s: %s\n", timestamp, level, message))
}

#' Format response object
#' @param status Response status (success, error)
#' @param message Response message
#' @param data Response data (optional)
#' @param metadata Additional metadata (optional)
format_response <- function(status, message, data = NULL, metadata = NULL) {
  response <- list(
    status = status,
    message = message,
    timestamp = Sys.time()
  )

  if (!is.null(data)) {
    response$data <- data
  }

  if (!is.null(metadata)) {
    response$metadata <- metadata
  }

  return(response)
}

#' Create error response
#' @param message Error message
#' @param error_code Error code
create_error_response <- function(message, error_code = "PROCESSING_ERROR") {
  format_response(
    status = "error",
    message = message,
    metadata = list(error_code = error_code)
  )
}

#' Create success response
#' @param message Success message
#' @param data Response data
create_success_response <- function(message, data = NULL) {
  metadata <- list(
    processing_time = Sys.time(),
    version = get_config("SERVICE_CONFIG", "version")
  )

  if (!is.null(data) && is.list(data)) {
    metadata$sequences_processed <- length(data)
  }

  format_response(
    status = "success",
    message = message,
    data = data,
    metadata = metadata
  )
}

#' Validate JSON input
#' @param json_string JSON string to validate
validate_json <- function(json_string) {
  tryCatch(
    {
      jsonlite::fromJSON(json_string)
      return(TRUE)
    },
    error = function(e) {
      return(FALSE)
    }
  )
}

#' Safe file reading
#' @param file_path Path to file
read_file_safe <- function(file_path) {
  if (!file.exists(file_path)) {
    return(NULL)
  }

  tryCatch(
    {
      readLines(file_path, warn = FALSE)
    },
    error = function(e) {
      log_message(paste("Error reading file:", file_path, "-", e$message), "ERROR")
      return(NULL)
    }
  )
}

#' Calculate processing time
#' @param start_time Start time
calculate_processing_time <- function(start_time) {
  end_time <- Sys.time()
  diff_time <- difftime(end_time, start_time, units = "secs")
  return(as.numeric(diff_time))
}
