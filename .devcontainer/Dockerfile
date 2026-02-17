FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# 1. Define Arguments & Versions
ARG TARGETARCH
ARG GO_VERSION=v1.25.5
ARG HELM_VERSION=v4.1.1
ARG TERRAFORM_VERSION=1.14.5
ARG KUBECTL_VERSION=v1.35.0
ARG KREW_VERSION=latest
ARG CILIUM_CLI_VERSION=v0.18.9
ARG OMNICTL_VERSION=v1.4.7
ARG OP_CLI_VERSION=v2.32.0
ARG GOLANGCI_LINT_VERSION=v1.61.0

# 2. Environment Configuration
ENV PIPX_HOME=/usr/local/pipx \
    PIPX_BIN_DIR=/usr/local/bin \
    KREW_ROOT=/usr/local/krew \
    PATH="/usr/local/go/bin:/usr/local/krew/bin:${PATH}"

# 3. Base System & Pre-reqs
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    python3-venv \
    pipx \
    neovim \
    iputils-ping \
    unzip \
    bash-completion \
    jq \
    && rm -rf /var/lib/apt/lists/*

# 4. Install Pre-commit
RUN pipx install pre-commit

# 5. Architecture Detection
RUN echo "Setting up architecture variables..." \
    && case ${TARGETARCH:-amd64} in \
         "amd64") echo "amd64" > /tmp/arch && echo "x86_64" > /tmp/arch_uname ;; \
         "arm64") echo "arm64" > /tmp/arch && echo "aarch64" > /tmp/arch_uname ;; \
       esac

# 6. Tool Installation
RUN set -e; \
    ARCH=$(cat /tmp/arch); \

    # GO
    echo "Installing Go..." && \
    if [ "$GO_VERSION" = "latest" ]; then GO_VER=$(curl -s https://go.dev/VERSION?m=text | head -n1 | sed 's/go//'); else GO_VER="${GO_VERSION#v}"; fi && \
    curl -fsSL "https://go.dev/dl/go${GO_VER}.linux-${ARCH}.tar.gz" -o go.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz; \

    # HELM
    echo "Installing Helm..." && \
    if [ "$HELM_VERSION" = "latest" ]; then HELM_VER=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep 'tag_name' | cut -d '"' -f 4 | sed 's/v//'); else HELM_VER="${HELM_VERSION#v}"; fi && \
    curl -fsSL "https://get.helm.sh/helm-v${HELM_VER}-linux-${ARCH}.tar.gz" -o helm.tar.gz && \
    tar -xzf helm.tar.gz && \
    mv linux-${ARCH}/helm /usr/local/bin/helm && \
    rm -rf helm.tar.gz linux-${ARCH}; \

    # TERRAFORM
    echo "Installing Terraform..." && \
    if [ "$TERRAFORM_VERSION" = "latest" ]; then TF_VER=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep 'tag_name' | cut -d '"' -f 4 | sed 's/v//'); else TF_VER="${TERRAFORM_VERSION#v}"; fi && \
    curl -fsSL "https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_${ARCH}.zip" -o terraform.zip && \
    unzip -q terraform.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/terraform && \
    rm terraform.zip; \

    # KUBECTL
    echo "Installing Kubectl..." && \
    if [ "$KUBECTL_VERSION" = "latest" ]; then K8S_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt); else K8S_VER="v${KUBECTL_VERSION#v}"; fi && \
    curl -fsSL "https://dl.k8s.io/release/${K8S_VER}/bin/linux/${ARCH}/kubectl" -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl; \

    # KREW
    echo "Installing Krew..." && \
    if [ "$KREW_VERSION" = "latest" ]; then KREW_VER=$(curl -fsSL "https://api.github.com/repos/kubernetes-sigs/krew/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'); else KREW_VER="v${KREW_VERSION#v}"; fi && \
    KREW_BINARY="krew-linux_${ARCH}" && \
    mkdir -p "${KREW_ROOT}" && \
    chmod -R a+rwX "${KREW_ROOT}" && \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/${KREW_VER}/${KREW_BINARY}.tar.gz" && \
    tar zxvf "${KREW_BINARY}.tar.gz" && \
    KREW_ROOT="${KREW_ROOT}" ./"${KREW_BINARY}" install krew && \
    rm -rf "${KREW_BINARY}.tar.gz" ./"${KREW_BINARY}" && \
    # 6. Re-assert permissions (Post-install fix)
    chmod -R a+rwX "${KREW_ROOT}"; \

    # CILIUM CLI
    echo "Installing Cilium CLI..." && \
    if [ "$CILIUM_CLI_VERSION" = "latest" ]; then CILIUM_VER=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt); else CILIUM_VER="v${CILIUM_CLI_VERSION#v}"; fi && \
    curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_VER}/cilium-linux-${ARCH}.tar.gz && \
    tar xzvf cilium-linux-${ARCH}.tar.gz -C /usr/local/bin && \
    rm cilium-linux-${ARCH}.tar.gz; \

    # OMNICTL
    echo "Installing omnictl..." && \
    if [ "$OMNICTL_VERSION" = "latest" ]; then OMNI_VER=$(curl -s https://api.github.com/repos/siderolabs/omni/releases/latest | grep 'tag_name' | cut -d '"' -f 4 | sed 's/v//'); else OMNI_VER="${OMNICTL_VERSION#v}"; fi && \
    curl -fsSLO "https://github.com/siderolabs/omni/releases/download/v${OMNI_VER}/omnictl-linux-${ARCH}" && \
    chmod +x omnictl-linux-${ARCH} && \
    mv omnictl-linux-${ARCH} /usr/local/bin/omnictl; \

    # 1PASSWORD CLI
    echo "Installing 1Password CLI..." && \
    if [ "$OP_CLI_VERSION" = "latest" ]; then OP_VER=$(curl -s https://app-updates.agilebits.com/check/1/0/CLI2/en/2.0.0/N | jq -r .version); else OP_VER="${OP_CLI_VERSION#v}"; fi && \
    curl -fsSL "https://cache.agilebits.com/dist/1P/op2/pkg/v${OP_VER}/op_linux_${ARCH}_v${OP_VER}.zip" -o op.zip && \
    unzip -o op.zip -d /tmp/op_extracted && \
    mv /tmp/op_extracted/op /usr/local/bin/op && \
    chmod +x /usr/local/bin/op && \
    rm -rf op.zip /tmp/op_extracted

# 7. Install Tools via Scripts
RUN curl -sL https://talos.dev/install | sh && \
    curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh | sh -s -- --install-method deb

# 8. Install Krew Plugins
RUN kubectl krew install oidc-login get-all

# Cleanup
RUN rm /tmp/arch /tmp/arch_uname
