FROM debian:bookworm-slim

ARG USERNAME=psm
ARG USER_UID=1000
ARG USER_GID=1000
ARG AWS_CLI_VERSION=2.33.31
ARG TERRAFORM_VERSION=1.15.6
ARG SOPS_VERSION=3.12.1
ARG AGE_VERSION=1.2.1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  git \
  less \
  unzip \
  vim \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN ARCH=$(uname -m) && \
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}-${AWS_CLI_VERSION}.zip" -o awscliv2.zip && \
  unzip -q awscliv2.zip && ./aws/install && rm -rf aws awscliv2.zip

RUN ARCH=$(dpkg --print-architecture) && \
  curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" -o terraform.zip && \
  unzip -q terraform.zip terraform -d /usr/local/bin && \
  rm terraform.zip

RUN ARCH=$(dpkg --print-architecture) && \
  curl -fsSL "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${ARCH}" -o /usr/local/bin/sops && \
  chmod +x /usr/local/bin/sops

RUN ARCH=$(dpkg --print-architecture) && \
  curl -fsSL "https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-linux-${ARCH}.tar.gz" | \
  tar -xz -C /usr/local/bin --strip-components=1 age/age age/age-keygen

RUN groupadd --gid "${USER_GID}" "${USERNAME}" && \
  useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${USERNAME}" && \
  mkdir -p "/home/${USERNAME}/.aws" "/home/${USERNAME}/.config/sops/age" && \
  chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}"

USER ${USERNAME}
WORKDIR /workspace
