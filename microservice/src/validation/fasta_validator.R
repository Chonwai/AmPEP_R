# AmPEP Microservice FASTA Validation Functions
# Functions for validating and parsing FASTA sequences

library(seqinr)

#' Validate FASTA format
#' @param fasta_text FASTA formatted text
#' @return Boolean indicating if FASTA is valid
validate_fasta <- function(fasta_text) {
  if (is.null(fasta_text) || nchar(fasta_text) == 0) {
    return(FALSE)
  }

  lines <- strsplit(fasta_text, "\n")[[1]]
  lines <- lines[nzchar(lines)] # Remove empty lines

  if (length(lines) < 2) {
    return(FALSE)
  }

  # Check if first line starts with >
  if (!grepl("^>", lines[1])) {
    return(FALSE)
  }

  # Check for alternating header and sequence pattern
  has_sequence <- FALSE
  for (i in 1:length(lines)) {
    if (grepl("^>", lines[i])) {
      # Header line - check if we have a sequence after header
      if (i < length(lines) && !grepl("^>", lines[i + 1])) {
        has_sequence <- TRUE
      }
    }
  }

  return(has_sequence)
}

#' Parse FASTA text into sequences
#' @param fasta_text FASTA formatted text
#' @return List of sequence objects with name and sequence
parse_fasta <- function(fasta_text) {
  if (!validate_fasta(fasta_text)) {
    stop("Invalid FASTA format")
  }

  lines <- strsplit(fasta_text, "\n")[[1]]
  lines <- lines[nzchar(lines)] # Remove empty lines

  sequences <- list()
  current_name <- NULL
  current_seq <- ""

  for (line in lines) {
    if (grepl("^>", line)) {
      # Save previous sequence if exists
      if (!is.null(current_name) && nchar(current_seq) > 0) {
        sequences[[length(sequences) + 1]] <- list(
          name = current_name,
          sequence = current_seq
        )
      }

      # Start new sequence
      current_name <- sub("^>", "", line)
      current_seq <- ""
    } else {
      # Append to current sequence
      current_seq <- paste0(current_seq, line)
    }
  }

  # Don't forget the last sequence
  if (!is.null(current_name) && nchar(current_seq) > 0) {
    sequences[[length(sequences) + 1]] <- list(
      name = current_name,
      sequence = current_seq
    )
  }

  return(sequences)
}

#' Validate amino acid sequence
#' @param sequence Amino acid sequence string
#' @return Boolean indicating if sequence is valid
validate_sequence <- function(sequence) {
  valid_aa <- "ACDEFGHIKLMNPQRSTVWY"
  sequence_upper <- toupper(sequence)

  # Check if all characters are valid amino acids
  for (i in 1:nchar(sequence_upper)) {
    char <- substr(sequence_upper, i, i)
    if (!grepl(char, valid_aa)) {
      return(FALSE)
    }
  }

  return(TRUE)
}

#' Validate sequence length
#' @param sequence Amino acid sequence
#' @param min_length Minimum allowed length
#' @param max_length Maximum allowed length
#' @return Boolean indicating if length is valid
validate_sequence_length <- function(sequence, min_length = 5, max_length = 200) {
  seq_length <- nchar(sequence)
  return(seq_length >= min_length && seq_length <= max_length)
}

#' Comprehensive sequence validation
#' @param sequence Amino acid sequence
#' @return List with validation results
validate_sequence_comprehensive <- function(sequence) {
  results <- list(
    valid = TRUE,
    errors = c(),
    warnings = c()
  )

  # Check if sequence is empty
  if (is.null(sequence) || nchar(sequence) == 0) {
    results$valid <- FALSE
    results$errors <- c(results$errors, "Sequence is empty")
    return(results)
  }

  # Check amino acid validity
  if (!validate_sequence(sequence)) {
    results$valid <- FALSE
    results$errors <- c(results$errors, "Sequence contains invalid amino acids")
  }

  # Check sequence length
  if (!validate_sequence_length(sequence)) {
    results$valid <- FALSE
    results$errors <- c(results$errors, "Sequence length is outside valid range (5-200)")
  }

  # Check for suspicious patterns
  if (nchar(sequence) > 0) {
    # Check for too many repeats
    for (aa in c("A", "G", "P", "S", "T")) {
      pattern <- paste0(rep(aa, 10), collapse = "")
      if (grepl(pattern, toupper(sequence))) {
        results$warnings <- c(results$warnings, paste("Long repeat of", aa, "detected"))
      }
    }
  }

  return(results)
}
