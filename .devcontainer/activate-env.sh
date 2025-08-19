#!/bin/bash

# Environment activation script for Databricks Ad Monitor
# This script ensures the UV virtual environment is always activated

PROJECT_ROOT="/workspaces/ad_monitor"
VENV_PATH="$PROJECT_ROOT/.venv"

# Function to activate environment
activate_env() {
    if [ -f "$VENV_PATH/bin/activate" ]; then
        source "$VENV_PATH/bin/activate"
        echo "🐍 Virtual environment activated: $(basename $VIRTUAL_ENV)"
        return 0
    else
        echo "❌ Virtual environment not found at $VENV_PATH"
        return 1
    fi
}

# Function to create and setup environment
setup_env() {
    echo "🔧 Setting up UV virtual environment..."
    
    cd "$PROJECT_ROOT"
    
    # Install/upgrade uv if needed
    if ! command -v uv >/dev/null 2>&1; then
        echo "📦 Installing uv..."
        pip install uv
    fi
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "$VENV_PATH" ]; then
        echo "🏗️  Creating virtual environment..."
        uv venv --python 3.11
    fi
    
    # Activate environment
    activate_env
    
    # Sync dependencies
    if [ -f "pyproject.toml" ]; then
        echo "📋 Syncing dependencies from pyproject.toml..."
        uv sync --dev
    elif [ -f "requirements.txt" ]; then
        echo "📋 Installing dependencies from requirements.txt..."
        uv pip install -r requirements.txt
    else
        echo "⚠️  No dependency file found"
    fi
    
    echo "✅ Environment setup complete!"
}

# Main logic
main() {
    # Change to project directory
    cd "$PROJECT_ROOT" 2>/dev/null || {
        echo "❌ Project directory not found: $PROJECT_ROOT"
        exit 1
    }
    
    # Check if virtual environment exists and activate it
    if [ -d "$VENV_PATH" ]; then
        activate_env || setup_env
    else
        setup_env
    fi
    
    # Verify installation
    echo ""
    echo "🔍 Environment verification:"
    echo "  Python: $(python --version 2>/dev/null || echo 'Not available')"
    echo "  UV: $(uv --version 2>/dev/null || echo 'Not available')"
    echo "  Databricks CLI: $(databricks --version 2>/dev/null || echo 'Not available')"
    echo "  Virtual Env: ${VIRTUAL_ENV:+$(basename $VIRTUAL_ENV)} ${VIRTUAL_ENV:-Not active}"
    
    # Show available commands
    echo ""
    echo "🛠️  Available commands:"
    echo "  uvs           - Sync dependencies"
    echo "  uvstatus      - Check environment status"
    echo "  dab validate  - Validate Databricks bundle"
    echo "  dab deploy    - Deploy to Databricks"
}

# Run main function
main "$@"