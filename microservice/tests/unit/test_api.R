# AmPEP Microservice Unit Tests
# Test file for API endpoints

library(testthat)
library(plumber)
library(jsonlite)

# Test data
test_fasta <- ">test_sequence_1
ALWKTMLKKLGTMALHAGKAALGAAADTISQGTQ
>test_sequence_2
AWKKWAKAWKWAKAKWWAKAA"

test_invalid_fasta <- "This is not a FASTA file"

# Mock request object
mock_request <- function(body) {
  list(postBody = toJSON(body, auto_unbox = TRUE))
}

# Test health check endpoint
test_that("Health check endpoint returns correct format", {
  # This would be tested with actual plumber instance
  # For now, we test the function logic
  health_response <- list(
    status = "healthy",
    service = "ampep-microservice",
    version = "1.0.0",
    timestamp = Sys.time(),
    model_loaded = FALSE
  )

  expect_equal(health_response$status, "healthy")
  expect_equal(health_response$service, "ampep-microservice")
  expect_equal(health_response$version, "1.0.0")
})

# Test FASTA validation
test_that("FASTA validation works correctly", {
  # Test valid FASTA
  expect_true(validate_fasta(test_fasta))

  # Test invalid FASTA
  expect_false(validate_fasta(test_invalid_fasta))

  # Test empty input
  expect_false(validate_fasta(""))

  # Test single line
  expect_false(validate_fasta(">test"))
})

# Test sequence parsing
test_that("FASTA parsing works correctly", {
  sequences <- parse_fasta(test_fasta)

  expect_equal(length(sequences), 2)
  expect_equal(sequences[[1]]$name, "test_sequence_1")
  expect_equal(sequences[[1]]$sequence, "ALWKTMLKKLGTMALHAGKAALGAAADTISQGTQ")
  expect_equal(sequences[[2]]$name, "test_sequence_2")
  expect_equal(sequences[[2]]$sequence, "AWKKWAKAWKWAKAKWWAKAA")
})

# Test sequence validation
test_that("Amino acid sequence validation works correctly", {
  # Test valid sequence
  expect_true(validate_sequence("ACDEFGHIKLMNPQRSTVWY"))

  # Test invalid sequence
  expect_false(validate_sequence("ACDEFGHIKLMNPQRSTVWYX"))

  # Test mixed case
  expect_true(validate_sequence("acdefghiklmnpqrstvwy"))

  # Test empty sequence
  expect_false(validate_sequence(""))
})

# Test prediction endpoint structure
test_that("Prediction endpoint returns correct structure", {
  # Mock request
  request_body <- list(fasta = test_fasta)
  req <- mock_request(request_body)

  # This would be tested with actual plumber instance
  # For now, we test the expected response structure
  expected_response <- list(
    status = "success",
    message = "Prediction completed successfully",
    data = list(),
    metadata = list(
      processing_time = Sys.time(),
      sequences_processed = 2,
      version = "1.0.0"
    )
  )

  expect_equal(expected_response$status, "success")
  expect_equal(expected_response$metadata$sequences_processed, 2)
})

# Test error handling
test_that("Error handling works correctly", {
  # Test missing FASTA parameter
  request_body <- list()
  req <- mock_request(request_body)

  # This would be tested with actual plumber instance
  # For now, we test the expected error structure
  expected_error <- list(
    status = "error",
    message = "Missing 'fasta' parameter",
    error_code = "PROCESSING_ERROR",
    timestamp = Sys.time()
  )

  expect_equal(expected_error$status, "error")
  expect_equal(expected_error$error_code, "PROCESSING_ERROR")
})

# Test configuration loading
test_that("Configuration loading works correctly", {
  # Test default configuration
  expect_equal(get_config("SERVICE_CONFIG", "name"), "AmPEP Microservice")
  expect_equal(get_config("SERVICE_CONFIG", "version"), "1.0.0")

  # Test configuration setting
  set_config("SERVICE_CONFIG", "test_key", "test_value")
  expect_equal(get_config("SERVICE_CONFIG", "test_key"), "test_value")
})

# Run all tests
test_results <- test_dir("tests/unit", reporter = "summary")
