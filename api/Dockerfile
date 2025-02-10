ARG NODE_VERSION=22.13.0

# Base Stage
FROM node:${NODE_VERSION}-slim AS base

WORKDIR /app

# Define build-time ARGs
ARG NODE_ENV
ARG PROXY_URL
ARG DEFAULT_HEADERS
ARG CHROME_EXECUTABLE_PATH
ARG LOG_LEVEL
ARG HOST

ENV NODE_ENV=${NODE_ENV} \
    PUPPETEER_CACHE_DIR=/app/.cache \
    DISPLAY=:99 \
    PATH="/usr/bin:/app/selenium/driver:${PATH}" \
    CHROME_BIN=/usr/bin/google-chrome-stable \
    CHROME_PATH=/usr/bin/google-chrome-stable \
    PROXY_URL=${PROXY_URL} \
    DEFAULT_HEADERS=${DEFAULT_HEADERS} \
    CHROME_EXECUTABLE_PATH=${CHROME_EXECUTABLE_PATH} \
    LOG_LEVEL=${LOG_LEVEL} \
    HOST=${HOST}

LABEL org.opencontainers.image.source="https://github.com/steel-dev/steel-browser"

# Create .env file with environment variables
RUN printf "NODE_ENV=$NODE_ENV\nPROXY_URL=$PROXY_URL\nDEFAULT_HEADERS=$DEFAULT_HEADERS\nCHROME_EXECUTABLE_PATH=$CHROME_EXECUTABLE_PATH\nLOG_LEVEL=$LOG_LEVEL\nHOST=$HOST\n" > /app/.env

# Install build dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/var/log/apt \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade

# Build Stage
FROM base AS build

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/var/log/apt \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      build-essential \
      pkg-config \
      python-is-python3 \
      xvfb \
      x11vnc \
      websockify \
      novnc \
      nginx

COPY --link package-lock.json package.json ./

RUN npm ci --include=dev

COPY --link . .

RUN npm run build

RUN npm prune --omit=dev


# Production Stage
FROM base AS production

# Install runtime dependencies, including remote desktop-related tools
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/var/log/apt \
    apt-get update && \ 
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
      wget \
      nginx \
      gnupg \
      fonts-ipafont-gothic \
      fonts-wqy-zenhei \
      fonts-thai-tlwg \
      fonts-kacst \
      fonts-freefont-ttf \
      libxss1 \
      curl \
      unzip \
      default-jre \
      dbus \
      dbus-x11 \
      xvfb \
      x11vnc \
      websockify \
      novnc

# Install CA certificates before curl commands
RUN apt-get update && apt-get install -y ca-certificates

# Install Chrome and ChromeDriver
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/var/log/apt \
    curl -o chrome.deb https://mirror.cs.uchicago.edu/google-chrome/pool/main/g/google-chrome-stable/google-chrome-stable_128.0.6613.119-1_amd64.deb \
    && apt-get install -y ./chrome.deb \
    && rm chrome.deb \
    && mkdir -p /selenium/driver \
    && curl -o chromedriver.zip https://storage.googleapis.com/chrome-for-testing-public/128.0.6613.119/linux64/chromedriver-linux64.zip \
    && unzip chromedriver.zip -d /tmp \
    && mv /tmp/chromedriver-linux64/chromedriver /selenium/driver/chromedriver \
    && rm -rf chromedriver.zip /tmp/chromedriver-linux64 \
    && chmod +x /selenium/driver/chromedriver

COPY --chmod=755 entrypoint.sh /app/entrypoint.sh

# Expose necessary ports
EXPOSE 3000 9223 5900 6080

ENV HOST_IP=localhost \
    DBUS_SESSION_BUS_ADDRESS=autolaunch:

ENTRYPOINT ["/app/entrypoint.sh"]

COPY --from=patcher /app /app