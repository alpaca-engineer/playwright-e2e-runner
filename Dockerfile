FROM myoung34/github-runner:ubuntu-noble

ENV TZ=Asia/Tokyo

RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb default-jre curl ca-certificates \
    locales fontconfig \
    fonts-dejavu-core fonts-noto-core fonts-noto-cjk fonts-noto-color-emoji \
  && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/^# *ja_JP.UTF-8/ja_JP.UTF-8/' /etc/locale.gen && locale-gen
ENV LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8

# フォント描画の揺れを抑える
RUN mkdir -p /etc/fonts/conf.d && \
  printf '%s\n' \
'<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd"><fontconfig>'\
'  <match target="font"><edit name="hinting" mode="assign"><bool>false</bool></edit>'\
'  <edit name="antialias" mode="assign"><bool>true</bool></edit>'\
'  <edit name="rgba" mode="assign"><const>none</const></edit></match></fontconfig>' \
  > /etc/fonts/conf.d/99-no-hinting.conf

ENV NODE_VERSION=24.6.0
ARG TARGETARCH
RUN set -eux; \
  case "${TARGETARCH:-amd64}" in \
    amd64) NODE_ARCH='x64' ;; \
    arm64) NODE_ARCH='arm64' ;; \
    *) echo "Unsupported TARGETARCH: ${TARGETARCH}"; exit 1 ;; \
  esac; \
  curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -o /tmp/node.tar.xz; \
  mkdir -p /usr/local; \
  tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1; \
  node -v && npm -v && corepack enable

ENV ALLURE_VERSION=2.35.1
RUN curl -fsSL -o /tmp/allure.tgz \
    "https://github.com/allure-framework/allure2/releases/download/${ALLURE_VERSION}/allure-${ALLURE_VERSION}.tgz" && \
    tar -xf /tmp/allure.tgz -C /opt/ && ln -s /opt/allure-${ALLURE_VERSION}/bin/allure /usr/bin/allure && \
    allure --version

ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
WORKDIR /work
COPY package.json package-lock.json ./
RUN npm ci
RUN npx playwright@1.53.0 install --with-deps
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

WORKDIR /actions-runner
