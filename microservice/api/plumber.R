# AmPEP Microservice API
# Plumber API for Antimicrobial Peptide Prediction

# Load required libraries
library(plumber)
library(jsonlite)
library(seqinr)
library(randomForest)
library(protr)

# Feature extraction function (simplified version)
constructDescMatrix <- function(seqs, lambda = 4, method = "AAC", class_label = 1) {
  require(protr)
  seqs_n <- length(seqs)
  data <- NULL

  if ("D" %in% method) {
    temp <- NULL
    for (i in 1:seqs_n) {
      T <- NULL
      if (length(seqs[i]) <= lambda) {
        l <- nchar(seqs[i]) - 1
      } else {
        l <- lambda
      }
      # Use protr's CTDD function for distribution composition
      t <- extractCTDD(seqs[i])
      T <- c(T, t)
      temp <- rbind(temp, T)
      rownames(temp)[i] <- i
    }
    data <- cbind(data, temp)
  }

  if (!is.null(class_label)) {
    class <- rep(class_label, seqs_n)
    data <- cbind(data, class)
  }

  data <- as.data.frame(data)
  return(data)
}

# Configure JSON serialization
options(jsonlite.auto_unbox = TRUE)

# Global variables
MODEL_PATH <- "../same_def_matlab_100tree_11mtry_rf.mdl"

# Initialize model storage environment
model_env <- new.env()
model_env$model <- NULL
model_env$loaded <- FALSE

# Initialize model on startup
load_model <- function() {
  tryCatch(
    {
      model_env$model <- readRDS(MODEL_PATH)
      model_env$loaded <- TRUE
      message("Model loaded successfully")
      return(TRUE)
    },
    error = function(e) {
      message("Warning: Could not load model: ", e$message)
      model_env$loaded <- FALSE
      return(FALSE)
    }
  )
}

# Load model when the script is sourced
tryCatch(
  {
    model_env$model <- readRDS(MODEL_PATH)
    model_env$loaded <- TRUE
    message("Model loaded successfully at startup")
  },
  error = function(e) {
    message("Warning: Could not load model at startup: ", e$message)
    message("Working directory: ", getwd())
    message("Files in working directory: ", paste(list.files("."), collapse = ", "))
    model_env$loaded <- FALSE
  }
)

#* Health check endpoint
#* @get /health
#* @serializer json
function() {
  list(
    status = "healthy",
    service = "ampep-microservice",
    version = "1.0.0",
    timestamp = Sys.time(),
    model_loaded = model_env$loaded
  )
}

#* Get service information
#* @get /api/info
#* @serializer json
function() {
  list(
    service_name = "AmPEP Microservice",
    description = "Antimicrobial Peptide Prediction Service",
    version = "1.0.0",
    supported_methods = c("ampep"),
    api_documentation = "/__docs__/"
  )
}

#* Predict antimicrobial activity
#* @param req Plumber request object
#* @post /api/predict
#* @serializer json
function(req) {
  tryCatch(
    {
      # Parse request body
      body <- fromJSON(req$postBody)

      # Validate input
      if (is.null(body$fasta)) {
        stop("Missing 'fasta' parameter")
      }

      # Extract FASTA content
      fasta_content <- body$fasta

      # Validate FASTA format
      if (!validate_fasta(fasta_content)) {
        stop("Invalid FASTA format")
      }

      # Parse sequences
      sequences <- parse_fasta(fasta_content)

      # Validate sequences
      for (seq in sequences) {
        if (!validate_sequence(seq$sequence)) {
          stop(paste("Invalid amino acid sequence in:", seq$name))
        }
      }

      # Perform prediction
      results <- predict_sequences(sequences)

      # Return response with unboxed values
      response <- list(
        status = jsonlite::unbox("success"),
        message = jsonlite::unbox("Prediction completed successfully"),
        data = results,
        metadata = list(
          processing_time = jsonlite::unbox(as.character(Sys.time())),
          sequences_processed = jsonlite::unbox(length(sequences)),
          version = jsonlite::unbox("1.0.0")
        )
      )

      return(response)
    },
    error = function(e) {
      # Error response with unboxed values
      list(
        status = jsonlite::unbox("error"),
        message = jsonlite::unbox(e$message),
        error_code = jsonlite::unbox("PROCESSING_ERROR"),
        timestamp = jsonlite::unbox(as.character(Sys.time()))
      )
    }
  )
}

# Helper functions

#* Validate FASTA format
validate_fasta <- function(fasta_content) {
  lines <- strsplit(fasta_content, "\n")[[1]]
  if (length(lines) < 2) {
    return(FALSE)
  }

  # Check if first line starts with '>'
  if (!grepl("^>", lines[1])) {
    return(FALSE)
  }

  # Check if there are sequence lines
  has_sequence <- FALSE
  for (line in lines[-1]) {
    if (nchar(trimws(line)) > 0 && !grepl("^>", line)) {
      has_sequence <- TRUE
      break
    }
  }

  has_sequence
}

#* Parse FASTA content
parse_fasta <- function(fasta_content) {
  lines <- strsplit(fasta_content, "\n")[[1]]
  sequences <- list()
  current_name <- NULL
  current_sequence <- ""

  for (line in lines) {
    line <- trimws(line)
    if (nchar(line) == 0) next

    if (grepl("^>", line)) {
      # Save previous sequence
      if (!is.null(current_name)) {
        sequences[[length(sequences) + 1]] <- list(
          name = current_name,
          sequence = current_sequence
        )
      }

      # Start new sequence
      current_name <- substring(line, 2)
      current_sequence <- ""
    } else {
      # Append to current sequence
      current_sequence <- paste0(current_sequence, line)
    }
  }

  # Add last sequence
  if (!is.null(current_name)) {
    sequences[[length(sequences) + 1]] <- list(
      name = current_name,
      sequence = current_sequence
    )
  }

  sequences
}

#* Validate amino acid sequence
validate_sequence <- function(sequence) {
  valid_aa <- "ACDEFGHIKLMNPQRSTVWY"
  sequence_upper <- toupper(sequence)

  # Check if all characters are valid amino acids
  all(strsplit(sequence_upper, "")[[1]] %in% strsplit(valid_aa, "")[[1]])
}

#* Predict sequences using existing model
predict_sequences <- function(sequences) {
  if (!model_env$loaded || is.null(model_env$model)) {
    stop("Model not loaded")
  }

  # Set threshold (matching the standard 0.5 from the original code)
  threshold <- 0.5

  results <- list()

  for (seq in sequences) {
    tryCatch(
      {
        # Extract sequence for feature calculation
        sequence_string <- seq$sequence

        # Generate features using the same method as training
        # constructDescMatrix function with parameters matching training
        test_features <- constructDescMatrix(sequence_string, 4, "D", class_label = NULL)

        # Make prediction using the loaded model
        # type = "vote" returns probability matrix
        prediction_probs <- predict(model_env$model, newdata = test_features, type = "vote")

        # Extract probability for positive class (AMP)
        amp_probability <- prediction_probs[1, 2] # Second column is positive class

        # Apply threshold to get binary classification
        prediction_class <- if (amp_probability >= threshold) 1 else 0

        # Create result with correct format
        prediction_result <- list(
          sequence_name = jsonlite::unbox(seq$name),
          sequence = jsonlite::unbox(seq$sequence),
          prediction = jsonlite::unbox(prediction_class), # Now returns 0 or 1
          probability = jsonlite::unbox(round(amp_probability, 6)), # Real probability
          method = jsonlite::unbox("ampep")
        )

        results[[length(results) + 1]] <- prediction_result
      },
      error = function(e) {
        # Handle individual sequence prediction errors
        warning(paste("Failed to predict sequence", seq$name, ":", e$message))

        # Return error result for this sequence
        error_result <- list(
          sequence_name = jsonlite::unbox(seq$name),
          sequence = jsonlite::unbox(seq$sequence),
          prediction = jsonlite::unbox(-1), # -1 indicates error
          probability = jsonlite::unbox(0.0),
          method = jsonlite::unbox("ampep"),
          error = jsonlite::unbox(e$message)
        )

        results[[length(results) + 1]] <<- error_result
      }
    )
  }

  results
}

#* @plumber
function(pr) {
  pr
}
