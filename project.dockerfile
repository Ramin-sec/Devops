# Base image: Azure CLI with a lightweight Ubuntu distribution-mcr.microsoft.com/azure-cli:2.52.0
FROM ubuntu:20.04
# Set environment variables for Azure DevOps agent
ENV AZP_URL=https://dev.azure.com/RaminEB
ENV AZP_TOKEN=3ZGS1XLyxTU2wXlrXy71ldl1tBKceXM9ks6mVAeQchvWIErzkwtBJQQJ99AKACAAAAAAAAAAAAASAZDO5BA2
ENV AZP_POOL=CoolPool

# Install necessary tools and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git unzip software-properties-common \
    openjdk-11-jdk python3-pip docker.io \
    && apt-get clean

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x ./kubectl && mv ./kubectl /usr/local/bin/kubectl

# Install Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt-get update && apt-get install terraform -y

    # Install Bicep
RUN az bicep install

# Install Helm (optional for Kubernetes deployments)
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add the Azure DevOps agent
RUN mkdir /azagent
WORKDIR /azagent
RUN curl -o agent.tar.gz -L https://vstsagentpackage.azureedge.net/agent/2.220.2/vsts-agent-linux-x64-2.220.2.tar.gz && \
    tar zxvf agent.tar.gz && rm agent.tar.gz

# Configure and start the Azure DevOps agent
CMD ./config.sh --unattended --url $AZP_URL --auth pat --token $AZP_TOKEN --pool $AZP_POOL --replace && ./run.sh
