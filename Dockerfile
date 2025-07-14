# Multi-stage build for vkQuake dedicated server
FROM ubuntu:22.04 AS builder

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    meson \
    ninja-build \
    gcc \
    g++ \
    make \
    pkg-config \
    libsdl2-dev \
    libvorbis-dev \
    libmpg123-dev \
    libflac-dev \
    libopusfile-dev \
    libx11-xcb-dev \
    libvulkan-dev \
    glslang-tools \
    spirv-tools \
    && rm -rf /var/lib/apt/lists/*

# Clone vkQuake repository
WORKDIR /build
RUN git clone https://github.com/Novum/vkQuake.git .

# Build vkQuake (we'll use the regular build but run in dedicated mode)
# For ARM64 compatibility, we'll use the traditional make approach
WORKDIR /build/Quake
RUN make -j$(nproc)

# Download and prepare Frogbot for bot support
WORKDIR /build/mods
RUN git clone https://github.com/mittorn/frogbot.git || \
    (mkdir -p frogbot && echo "# Frogbot placeholder - download manually" > frogbot/README.md)

# Runtime stage
FROM ubuntu:22.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libsdl2-2.0-0 \
    libvorbis0a \
    libvorbisfile3 \
    libmpg123-0 \
    libflac8 \
    libopusfile0 \
    libx11-6 \
    libxcb1 \
    libgl1-mesa-glx \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create quake user and directories
RUN groupadd -r quake && useradd -r -g quake quake

# Create directory structure
RUN mkdir -p /quake/{bin,game,config,logs,mods} && \
    chown -R quake:quake /quake

# Copy built binary
# COPY --from=builder /build/Quake/quakespasm /quake/bin/quakespasm # wrong
COPY --from=builder /build/Quake/quake /quake/bin/quake

# Copy mods
COPY --from=builder /build/mods /quake/mods

# Copy startup script
COPY start.sh /quake/start.sh
RUN chmod +x /quake/start.sh

# Set working directory
WORKDIR /quake

# Expose Quake server port
EXPOSE 26000/udp

# Environment variables with defaults
ENV QUAKE_SERVER_NAME="vkQuake Docker Server" \
    QUAKE_MAX_PLAYERS="16" \
    QUAKE_GAME_MODE="0" \
    QUAKE_SKILL="1" \
    QUAKE_TEAMPLAY="0" \
    QUAKE_COOP="0" \
    QUAKE_DEATHMATCH="1" \
    QUAKE_FRAGLIMIT="20" \
    QUAKE_TIMELIMIT="15" \
    QUAKE_MAP="start" \
    QUAKE_ADMIN_PASSWORD="" \
    QUAKE_ENABLE_BOTS="0" \
    QUAKE_BOT_COUNT="4" \
    QUAKE_BOT_SKILL="1" \
    QUAKE_MOD="" \
    QUAKE_PORT="26000" \
    QUAKE_CONDEBUG="1" \
    QUAKE_MAP_ROTATION="start,e1m1,e1m2,e1m3,e1m4,e1m5,e1m6,e1m7,e1m8" \
    QUAKE_ROTATION_MODE="1"

# Default user
USER quake

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD netstat -an | grep :${QUAKE_PORT} > /dev/null || exit 1

# Entry point
ENTRYPOINT ["/quake/start.sh"]
