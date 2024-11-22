# Use the Ubuntu 22.04 base image
FROM ubuntu:22.04

# Switch to the root user to perform installations
USER root

# Update package list and install required tools
RUN apt-get -y update && apt-get install -y curl && \
    # Install Azure CLI
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash && az aks install-cli && \
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh && sh ./get-docker.sh && \
    # Create a directory for the DevOps runner
    mkdir devops-runner && cd devops-runner && \
    # Download and extract the Azure DevOps agent
    curl -o vsts-agent-linux-x64-3.217.1.tar.gz -L https://vstsagentpackage.azureedge.net/agent/3.217.1/vsts-agent-linux-x64-3.217.1.tar.gz && \
    tar xzf ./vsts-agent-linux-x64-3.217.1.tar.gz && \
    # Clean up package cache
    apt-get clean

# Create a devops user and group with specific IDs
RUN addgroup --gid 110 devops && adduser devops --uid 111 --system && adduser devops devops && \
    # Change ownership of the devops-runner directory
    chown -R devops:devops devops-runner

# Switch to the devops user to run the application
USER devops
