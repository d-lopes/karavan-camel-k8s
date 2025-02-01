#################################
# Build stage
#################################
FROM openjdk:17-slim AS builder

# Install required tools
RUN apt-get update && \
    apt-get install -y \
    curl \
    procps && \
    rm -rf /var/lib/apt/lists/*

# Install JBang
RUN curl -Ls https://sh.jbang.dev | bash -s - app setup

# Add JBang to PATH
ENV PATH="/root/.jbang/bin:${PATH}"

# Create and set working directory
WORKDIR /build

# Install Camel JBang
RUN jbang trust add https://github.com/apache/camel
RUN jbang app install camel@apache/camel

# Copy your application files
COPY application.properties .
COPY simple-routing.camel.yaml .
COPY routing.properties .

# Pre-cache dependencies by running Camel in the background and killing it after a few seconds
RUN (camel run simple-routing.camel.yaml & ) \
    && sleep 30 \
    && pkill -f camel

#################################
# Final stage
#################################
FROM openjdk:17-slim

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -s /bin/bash camel

# Create app directory
WORKDIR /app

# Copy JBang and application from builder, including the cached dependencies
COPY --from=builder /root/.jbang /home/camel/.jbang
COPY --from=builder /root/.m2 /home/camel/.m2
COPY --from=builder /build/application.properties /app/
COPY --from=builder /build/simple-routing.camel.yaml /app/
COPY --from=builder /build/routing.properties /app/

# Set environment variables
ENV PATH="/home/camel/.jbang/bin:${PATH}"
ENV EXAMPLE_ENV="default_value"

# Set ownership
RUN chown -R camel:camel /app /home/camel/.jbang /home/camel/.m2

# Switch to non-root user
USER camel

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Run the Camel application
CMD ["sh", "-c", "camel run *"]