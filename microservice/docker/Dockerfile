# AmPEP Microservice Dockerfile
# Based on R 4.2.0 with plumber support

FROM r-base:4.3.2

# Set environment variables
ENV R_LIBS_USER=/usr/local/lib/R/library
ENV PLUMBER_PORT=8001
ENV PLUMBER_HOST=0.0.0.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    automake \
    autoconf \
    libtool \
    pkg-config \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libsodium-dev \
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install required R packages
# Install plumber first (most critical for API)
RUN R -e "install.packages('plumber', repos='https://cran.r-project.org/', dependencies=TRUE)" && \
    R -e "if (!require('plumber', quietly=TRUE)) { quit(status=1) }"

# Install other required R packages
RUN R -e "install.packages(c('jsonlite', 'seqinr', 'randomForest', 'caret', 'protr', 'MLmetrics', 'ggplot2', 'ROCR', 'pROC', 'PRROC', 'psych'), repos='https://cran.r-project.org/', dependencies=TRUE)"

# Create app directory
WORKDIR /app

# Copy application files
COPY microservice/api/ ./api/
COPY microservice/src/ ./src/
COPY microservice/config/ ./config/

# Copy model and data files from root directory
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