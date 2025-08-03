# AmPEP Microservice Configuration
# Configuration file for the AmPEP microservice

# Service Configuration
SERVICE_CONFIG <- list(
  name = "AmPEP Microservice",
  version = "1.0.0",
  port = as.numeric(Sys.getenv("PLUMBER_PORT", 8001)),
  host = Sys.getenv("PLUMBER_HOST", "0.0.0.0"),
  log_level = Sys.getenv("R_LOG_LEVEL", "INFO")
)

# Model Configuration
MODEL_CONFIG <- list(
  model_path = Sys.getenv("MODEL_PATH", "../same_def_matlab_100tree_11mtry_rf.mdl"),
  supported_methods = c("ampep"),
  prediction_threshold = 0.5
)

# API Configuration
API_CONFIG <- list(
  max_request_size = "10MB",
  timeout_seconds = 3600,  # 1 hour
  rate_limit = 100,  # requests per minute
  cors_enabled = TRUE
)

# Validation Configuration
VALIDATION_CONFIG <- list(
  max_sequence_length = 2000,
  min_sequence_length = 5,
  allowed_amino_acids = "ACDEFGHIKLMNPQRSTVWY",
  max_sequences_per_request = 100
)

# Logging Configuration
LOGGING_CONFIG <- list(
  log_file = "logs/ampep-microservice.log",
  log_level = "INFO",
  log_format = "json"
)

# Performance Configuration
PERFORMANCE_CONFIG <- list(
  model_preload = TRUE,
  cache_enabled = TRUE,
  cache_size = 1000,
  parallel_processing = TRUE
)

# Security Configuration
SECURITY_CONFIG <- list(
  input_validation = TRUE,
  sanitize_input = TRUE,
  max_input_size = 10485760  # 10MB
)

# Get configuration value
get_config <- function(config_name, key, default = NULL) {
  config <- get(config_name)
  if (is.null(config[[key]])) {
    return(default)
  }
  config[[key]]
}

# Set configuration value
set_config <- function(config_name, key, value) {
  config <- get(config_name)
  config[[key]] <- value
  assign(config_name, config, envir = .GlobalEnv)
}

# Load environment-specific configuration
load_environment_config <- function() {
  env <- Sys.getenv("R_ENV", "development")
  
  if (env == "production") {
    SERVICE_CONFIG$log_level <<- "WARN"
    API_CONFIG$timeout_seconds <<- 1800  # 30 minutes
    PERFORMANCE_CONFIG$cache_enabled <<- TRUE
  } else if (env == "testing") {
    SERVICE_CONFIG$log_level <<- "DEBUG"
    API_CONFIG$timeout_seconds <<- 300   # 5 minutes
    PERFORMANCE_CONFIG$cache_enabled <<- FALSE
  }
} 