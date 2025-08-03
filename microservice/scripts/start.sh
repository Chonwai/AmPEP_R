#!/bin/bash

# AmPEP Microservice Startup Script
# This script starts the AmPEP microservice for development

set -e

echo "🚀 Starting AmPEP Microservice..."

# Check if R is installed
if ! command -v R &> /dev/null; then
    echo "❌ Error: R is not installed. Please install R 4.0+ first."
    exit 1
fi

# Check if required R packages are installed
echo "📦 Checking R package dependencies..."
R -e "if (!require(plumber)) install.packages('plumber', repos='https://cran.r-project.org/')"
R -e "if (!require(jsonlite)) install.packages('jsonlite', repos='https://cran.r-project.org/')"
R -e "if (!require(seqinr)) install.packages('seqinr', repos='https://cran.r-project.org/')"
R -e "if (!require(randomForest)) install.packages('randomForest', repos='https://cran.r-project.org/')"

# Create logs directory if it doesn't exist
mkdir -p logs

# Set environment variables
export PLUMBER_PORT=8001
export PLUMBER_HOST=0.0.0.0
export R_LOG_LEVEL=INFO

echo "🔧 Environment configured:"
echo "   - Port: $PLUMBER_PORT"
echo "   - Host: $PLUMBER_HOST"
echo "   - Log Level: $R_LOG_LEVEL"

# Check if model file exists
if [ ! -f "../same_def_matlab_100tree_11mtry_rf.mdl" ]; then
    echo "⚠️  Warning: Model file not found. Some features may not work."
fi

# Start the service
echo "🌐 Starting plumber API server..."
echo "📖 API documentation will be available at: http://localhost:8001/__docs__/"
echo "🏥 Health check available at: http://localhost:8001/health"
echo ""

R -e "plumber::plumb('api/plumber.R')$run(host='$PLUMBER_HOST', port=$PLUMBER_PORT)" 