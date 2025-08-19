#!/bin/bash

echo "--- Starting post-creation setup ---"

# 1. Install uv (Python package manager)
echo "Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh
source /root/.cargo/env

# 2. Sync Python dependencies using uv
echo "Syncing Python requirements..."
# Assuming your requirements.txt is in the root of your project
uv sync

# 3. Download and install the Databricks CLI
echo "Installing Databricks CLI..."
curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh



echo "✅ Dev Container setup complete."
