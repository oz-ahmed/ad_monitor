#!/bin/bash

set -e  # Exit on any error

echo "🚀 Starting post-creation setup..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Verify uv installation and install if needed
log_info "Checking uv installation..."
if ! command_exists uv; then
    log_info "Installing uv via pip..."
    pip install uv
    log_success "uv installed successfully"
else
    UV_VERSION=$(uv --version 2>/dev/null || echo "unknown")
    log_success "uv is already installed: $UV_VERSION"
fi

# 2. Verify Databricks CLI installation
log_info "Checking Databricks CLI installation..."
if command_exists databricks; then
    DATABRICKS_VERSION=$(databricks --version 2>/dev/null || echo "unknown")
    log_success "Databricks CLI is installed: $DATABRICKS_VERSION"
else
    log_error "Databricks CLI is not installed or not in PATH"
    exit 1
fi

# 3. Initialize Python project and activate environment
log_info "Setting up Python environment with uv..."

# Create Python environment with uv
# if [ ! -d ".venv" ]; then
#     log_info "Creating virtual environment with uv..."
#     uv venv --python 3.11
#     log_success "Virtual environment created"
# fi

# Activate the virtual environment
# log_info "Activating virtual environment..."
# source .venv/bin/activate

# Verify activation
# if [ "$VIRTUAL_ENV" ]; then
#     log_success "Virtual environment activated: $VIRTUAL_ENV"
# else
#     log_error "Failed to activate virtual environment"
#     exit 1
# fi

if [ -f "pyproject.toml" ]; then
    log_info "Found pyproject.toml, running uv sync..."
    uv sync
    log_success "Python dependencies synced with uv"
elif [ -f "requirements.txt" ]; then
    log_info "Found requirements.txt, installing dependencies..."
    uv pip install -r requirements.txt
    log_success "Python dependencies installed with uv"
else
    log_info "No pyproject.toml or requirements.txt found, creating minimal Python environment..."
    # Create a basic pyproject.toml for the project
    cat > pyproject.toml << 'EOF'
[project]
name = "ad-monitor"
version = "0.1.0"
description = "Databricks Ad Spend Monitoring Dashboard"
dependencies = [
    "databricks-cli>=0.18.0",
    "databricks-sdk>=0.12.0",
    "pyspark>=3.4.0",
    "pandas>=2.0.0",
    "numpy>=1.24.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "black>=23.0.0",
    "flake8>=6.0.0",
    "mypy>=1.0.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.black]
line-length = 88
target-version = ['py311']

[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true
EOF
    
    log_info "Running uv sync to install dependencies..."
    uv sync --dev
    log_success "Created pyproject.toml and synced dependencies"
fi

# 4. Set up Databricks configuration directory
log_info "Setting up Databricks configuration..."
mkdir -p ~/.databricks
if [ ! -f ~/.databricks/databricks-cli ]; then
    # Create a template configuration file
    cat > ~/.databricks/databricks-cli << 'EOF'
[DEFAULT]
# host = https://your-workspace.cloud.databricks.com
# token = your-access-token

# Uncomment and configure the above settings after container creation
# Run: databricks configure --token
EOF
    log_success "Created Databricks CLI configuration template"
else
    log_info "Databricks configuration already exists"
fi

# 5. Create useful aliases and functions
log_info "Setting up shell aliases..."
cat >> ~/.bashrc << 'EOF'


# Project aliases
alias cdp='cd /workspaces/ad_monitor'

# Useful functions
dabstatus() {
    echo "Databricks Bundle Status:"
    databricks bundle validate --target "${1:-dev}" 2>/dev/null && echo "✅ Valid" || echo "❌ Invalid"
}

uvcheck() {
    echo "UV Environment Status:"
    uv pip list | head -10
}
EOF

# 6. Create project structure if it doesn't exist
log_info "Ensuring project structure exists..."
mkdir -p {resources,src/notebooks,tests,.databricks}

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'EOF'
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# Databricks
.databricks/
*.dbc

# Python virtual environments
venv/
env/
.env

# IDE
.vscode/settings.json
.idea/

# OS
.DS_Store
Thumbs.db

# Logs
*.log

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# PyInstaller
*.manifest
*.spec

# Unit test / coverage reports
htmlcov/
.tox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
.hypothesis/
.pytest_cache/

# Jupyter Notebook
.ipynb_checkpoints

# Environment variables
.env
.venv
EOF
    log_success "Created .gitignore"
fi

# 7. Final verification with activated environment
log_info "Running final verification with activated environment..."

# Ensure we're in the virtual environment
if [ ! "$VIRTUAL_ENV" ]; then
    log_info "Activating virtual environment for verification..."
    source .venv/bin/activate
fi

# Test uv
if uv --version >/dev/null 2>&1; then
    UV_VERSION=$(uv --version)
    log_success "✅ uv is working correctly: $UV_VERSION"
else
    log_error "❌ uv verification failed"
fi

# Test Databricks CLI
if databricks --version >/dev/null 2>&1; then
    DATABRICKS_VERSION=$(databricks --version)
    log_success "✅ Databricks CLI is working correctly: $DATABRICKS_VERSION"
else
    log_error "❌ Databricks CLI verification failed"
fi

# Test Python environment
if python -c "import sys; print(f'Python {sys.version}')" 2>/dev/null; then
    PYTHON_VERSION=$(python -c "import sys; print(f'{sys.version.split()[0]}')")
    log_success "✅ Python environment is ready: $PYTHON_VERSION"
    
    # Test if key packages are available
    if python -c "import pandas, numpy" 2>/dev/null; then
        log_success "✅ Core data packages (pandas, numpy) are available"
    else
        log_info "ℹ️  Core data packages will be installed when uv sync runs"
    fi
else
    log_error "❌ Python environment verification failed"
fi

# Check virtual environment status
if [ "$VIRTUAL_ENV" ]; then
    log_success "✅ Virtual environment is active: $(basename $VIRTUAL_ENV)"
else
    log_error "❌ Virtual environment is not active"
fi

echo ""
echo "🎉 Post-creation setup completed successfully!"
echo ""
echo "📋 Environment Summary:"
echo "  🐍 Python: $(python --version 2>/dev/null || echo 'Not available')"
echo "  📦 UV: $(uv --version 2>/dev/null || echo 'Not available')"
echo "  🧱 Databricks CLI: $(databricks --version 2>/dev/null || echo 'Not available')"
echo "  🌍 Virtual Environment: ${VIRTUAL_ENV:+Active ($(basename $VIRTUAL_ENV))} ${VIRTUAL_ENV:-Inactive}"
echo ""
echo "🔧 Next steps:"
echo "1. Configure Databricks CLI: databricks configure"
echo "2. Set your workspace URL and personal access token"
echo "3. Validate your bundle: make validate"
echo "4. If you need to manually activate the environment: source .venv/bin/activate"
echo ""
echo "🛠️  Useful commands:"
echo "- make validate    # Validate bundle"
echo "- make deploy      # Deploy bundle" 
