# Use Python 3.11 slim for better performance and security updates
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Set working directory
WORKDIR /workspaces/ad_monitor

# Install system dependencies in a single layer
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    unzip \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user for security
RUN apt-get update && apt-get install -y sudo \
    && mkdir -p /etc/sudoers.d \
    && useradd --create-home --shell /bin/bash vscode \
    && usermod -aG sudo vscode \
    && echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

# Install uv through pip for better compatibility
RUN pip install --no-cache-dir uv

# Install Databricks CLI globally
RUN curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh

# Copy scripts
COPY post-create.sh /usr/local/bin/post-create.sh
COPY activate-env.sh /usr/local/bin/activate-env.sh
RUN chmod +x /usr/local/bin/post-create.sh /usr/local/bin/activate-env.sh

# Switch to non-root user
USER vscode

# Set the default command
CMD ["/bin/bash"]