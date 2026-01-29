# ================================
# Build image
# ================================
FROM swift:6.2-noble AS build

# Install OS updates, PostgreSQL client libs, and libgd for image rendering
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y libjemalloc-dev libpq-dev libgd-dev \
    && rm -r /var/lib/apt/lists/*

# Set up a build area
WORKDIR /build

# First just resolve dependencies.
# This creates a cached layer that can be reused
# as long as your Package.swift/Package.resolved
# files do not change.
COPY ./Package.* ./
RUN swift package resolve \
        $([ -f ./Package.resolved ] && echo "--force-resolved-versions" || true)

# Copy entire repo into container
COPY . .

# Build the application, with optimizations, with static linking, and using jemalloc
RUN swift build -c release \
        --product Vaultown \
        --static-swift-stdlib \
        -Xlinker -ljemalloc

# Switch to the staging area
WORKDIR /staging

# Copy main executable to staging area
RUN cp "$(swift build --package-path /build -c release --show-bin-path)/Vaultown" ./

# Copy static swift backtracer binary to staging area
RUN cp "/usr/libexec/swift/linux/swift-backtrace-static" ./

# Copy resources bundled by SPM to staging area
RUN find -L "$(swift build --package-path /build -c release --show-bin-path)/" -regex '.*\.resources$' -exec cp -Ra {} ./ \; 2>/dev/null || true

# Copy any resources from the public directory and views directory if the directories exist
# Ensure that by default, neither the directory nor any of its contents are writable.
RUN [ -d /build/Public ] && { mv /build/Public ./Public && chmod -R a-w ./Public; } || true
RUN [ -d /build/Localizations ] && { mv /build/Localizations ./Localizations && chmod -R a-w ./Localizations; } || true

# ================================
# Run image
# ================================
FROM ubuntu:noble

# Make sure all system packages are up to date, and install only essential packages.
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y \
      libjemalloc2 \
      ca-certificates \
      tzdata \
      libcurl4 \
      libpq5 \
      libgd3 \
    && rm -r /var/lib/apt/lists/*

# Create a non-root user to run the app
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vaultown

# Switch to the new home directory
WORKDIR /app

# Copy built executable and any staged resources from builder
COPY --from=build --chown=vaultown:vaultown /staging /app

# Switch to non-root user
USER vaultown:vaultown

# Provide configuration needed by the built-in crash reporter and some sensible default behaviors.
ENV SWIFT_BACKTRACE=enable=yes,sanitize=yes,threads=all,images=all,interactive=no,swift-backtrace=./swift-backtrace-static

# Expose the HTTP port
EXPOSE 8080

# Start the Vaultown bot (no Vapor CLI - just run the executable directly)
ENTRYPOINT ["./Vaultown"]
