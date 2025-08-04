# AmPEP Microservice Dockerfile
# Based on R 4.2.0 with plumber support

FROM r-base:4.2.0

# Set environment variables
ENV R_LIBS_USER=/usr/local/lib/R/library
ENV PLUMBER_PORT=8001
ENV PLUMBER_HOST=0.0.0.0

# Install system dependencies (minimal set)
RUN apt-get update && apt-get install -y \
    curl \
    --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install R packages with error handling
RUN R -e "install.packages(c('plumber', 'jsonlite', 'seqinr', 'randomForest', 'caret', 'protr', 'MLmetrics', 'ggplot2', 'ROCR', 'pROC', 'PRROC', 'psych'), repos='https://cran.r-project.org/', dependencies=TRUE)"

# Install required R packages
RUN R -e "install.packages(c('plumber', 'jsonlite', 'seqinr', 'randomForest', 'caret', 'protr', 'MLmetrics', 'ggplot2', 'ROCR', 'pROC', 'PRROC', 'psych'), repos='https://cran.r-project.org/')"

# Create app directory
WORKDIR /app

# Copy application files
COPY microservice/api/ ./api/
COPY microservice/src/ ./src/
COPY microservice/config/ ./config/

# Copy model and data files from parent directory
COPY same_def_matlab_100tree_11mtry_rf.mdl ./
COPY trian_po_set3298_for_ampep_sever.fasta ./
COPY trian_ne_set9894_for_ampep_sever.fasta ./

# Create necessary directories
RUN mkdir -p logs

# Expose port
EXPOSE 8001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

# Start the application
CMD ["R", "-e", "plumber::plumb('api/plumber.R')$run(host='0.0.0.0', port=8001)"] 