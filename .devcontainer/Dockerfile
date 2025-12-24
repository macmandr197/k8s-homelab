FROM mcr.microsoft.com/devcontainers/base:ubuntu

ARG GOLANGCI_LINT_VERSION=2.1.6 # renovate: depName=golangci/golangci-lint datasource=github-releases
ARG TARGETARCH

#install GO
# To pin a version, set: 
ARG GO_VERSION=1.25.3 # renovate: depName=golang/go datasource=github-releases
RUN if [ "$GO_VERSION" = "latest" ]; then \
        GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | sed 's/go//'); \
    fi && \
    curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz -o /tmp/go.tar.gz && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"

# Install Helm
# To pin a version, set: ARG HELM_VERSION=3.16.1 # renovate: depName=helm/helm datasource=github-releases
ARG HELM_VERSION=latest
RUN ARCH=$(dpkg --print-architecture | sed 's/amd64/amd64/; s/arm64/arm64/') && \
    if [ "$HELM_VERSION" = "latest" ]; then \
        HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep 'tag_name' | cut -d '"' -f 4 | sed 's/v//'); \
    fi && \
    curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz" -o /tmp/helm.tar.gz && \
    tar -xzf /tmp/helm.tar.gz -C /tmp && \
    mv /tmp/linux-${ARCH}/helm /usr/local/bin/helm && \
    rm -rf /tmp/helm.tar.gz /tmp/linux-${ARCH}

RUN apt update && apt upgrade -y && \
    apt-get install --no-install-recommends -y iputils-ping ca-certificates curl gnupg lsb-release jq zsh neovim git sudo unzip gh && \
    rm -rf /var/lib/apt/lists/*

# Configure zsh as default shell and install oh-my-zsh
RUN chsh -s $(which zsh) && \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true

# Install Terraform
# To pin a version, set: ARG TERRAFORM_VERSION=1.9.0 # renovate: depName=hashicorp/terraform datasource=github-releases
ARG TERRAFORM_VERSION=latest
RUN ARCH=$(dpkg --print-architecture | sed 's/amd64/amd64/; s/arm64/arm64/') && \
    if [ "$TERRAFORM_VERSION" = "latest" ]; then \
        TERRAFORM_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep 'tag_name' | cut -d '"' -f 4 | sed 's/v//'); \
    fi && \
    curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" -o /tmp/terraform.zip && \
    unzip -q /tmp/terraform.zip -d /usr/local/bin && \
    rm /tmp/terraform.zip && \
    chmod +x /usr/local/bin/terraform

# Install kubectl
# To pin a version, set: ARG KUBECTL_VERSION=1.32.0 # renovate: depName=kubernetes/kubectl datasource=github-releases extractVersion=^v(?<version>.*)$
ARG KUBECTL_VERSION=latest
RUN ARCH=$(dpkg --print-architecture | sed 's/amd64/amd64/; s/arm64/arm64/') && \
    if [ "$KUBECTL_VERSION" = "latest" ]; then \
        KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt | sed 's/v//'); \
    fi && \
    curl -fsSL "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Install Krew (kubectl plugin manager) to system-wide location
ENV KREW_ROOT=/usr/local/krew
ENV PATH="${KREW_ROOT}/bin:${PATH}"
RUN set -x; \
    export KREW_ROOT=/usr/local/krew && \
    mkdir -p "${KREW_ROOT}" && \
    chmod -R a+rwX "${KREW_ROOT}" && \
    cd "$(mktemp -d)" && \
    OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
    KREW="krew-${OS}_${ARCH}" && \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
    tar zxvf "${KREW}.tar.gz" && \
    KREW_ROOT="${KREW_ROOT}" ./"${KREW}" install krew && \
    rm -rf "${KREW}.tar.gz" ./"${KREW}" && \
    chmod -R a+rwX "${KREW_ROOT}"

# Install kubelogin OIDC plugin via Krew
RUN kubectl krew install oidc-login

RUN kubectl krew install get-all

#install golangci-lint
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b $(go env GOPATH)/bin v${GOLANGCI_LINT_VERSION}

#install cilium CLI
# To pin a version, set: ARG CILIUM_CLI_VERSION=0.16.20 # renovate: depName=cilium/cilium-cli datasource=github-releases
ARG CILIUM_CLI_VERSION=latest
RUN case "$TARGETARCH" in \
        "amd64") CLI_ARCH=amd64 ;; \
        "arm64") CLI_ARCH=arm64 ;; \
        *) echo "Unsupported architecture: $TARGETARCH"; exit 1 ;; \
    esac && \
    if [ "$CILIUM_CLI_VERSION" = "latest" ]; then \
        CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt | sed 's/v//'); \
    fi && \
    curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/v${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum} && \
    sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum && \
    tar xzvf cilium-linux-${CLI_ARCH}.tar.gz -C /usr/local/bin && \
    rm cilium-linux-${CLI_ARCH}.tar.gz cilium-linux-${CLI_ARCH}.tar.gz.sha256sum

#install latest talosctl
RUN curl -sL https://talos.dev/install | sh

#install omnictl
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/') && \
    OS=$(uname -s | tr '[:upper:]' '[:lower:]') && \
    FILENAME="omnictl-${OS}-${ARCH}" && \
    curl -LO "https://github.com/siderolabs/omni/releases/latest/download/${FILENAME}" && \
    mv "${FILENAME}" /usr/local/bin/omnictl && \
    chmod +x /usr/local/bin/omnictl

#install 1p-cli
RUN curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
  gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
  tee /etc/apt/sources.list.d/1password.list && \
  mkdir -p /etc/debsig/policies/AC2D62742012EA22/ && \
  curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
  tee /etc/debsig/policies/AC2D62742012EA22/1password.pol && \
  mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22 && \
  curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
  gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg && \
  apt update && apt install 1password-cli

RUN  curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh && \
     chmod +x install-opentofu.sh && \
     ./install-opentofu.sh --install-method deb && \
    rm -f install-opentofu.sh