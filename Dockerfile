#################################
# Build stage
#################################
FROM openjdk:17-slim AS builder

# Install curl for JBang installation
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Install JBang
RUN curl -Ls https://sh.jbang.dev | bash -s - app setup

# Add JBang to PATH
ENV PATH="/root/.jbang/bin:${PATH}"

# Create and set working directory
WORKDIR /build

# Copy your application files
COPY application.properties .
COPY simple-routing.camel.yaml .
COPY routing.properties .

# Install Camel JBang and prepare the application
RUN jbang trust add https://github.com/apache/camel
RUN jbang app install camel@apache/camel

#################################
# Final stage
#################################
FROM openjdk:17-slim

# Create a non-root user
RUN useradd -m -s /bin/bash camel

# Create and set working directory
WORKDIR /app

# Copy JBang and application from builder
COPY --from=builder /root/.jbang /home/camel/.jbang
COPY --from=builder /build/*.properties /app/
COPY --from=builder /build/*.yaml /app/

# Set environment variables
ENV PATH="/home/camel/.jbang/bin:${PATH}"
ENV EXAMPLE_ENV="default_value"

# Set ownership
RUN chown -R camel:camel /app /home/camel/.jbang

# Switch to non-root user
USER camel

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:8080/q/health || exit 1

# Run the Camel application with environment variable support
CMD ["sh", "-c", "camel run simple-routing.camel.yaml"]