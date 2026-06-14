# Stage 1: Build
FROM golang:1.23-alpine AS builder

# Install gcc and musl-dev because go-sqlite3 requires CGO
RUN apk add --no-cache gcc musl-dev

# Set destination for COPY
WORKDIR /app

# Download Go modules
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code
COPY . .

# Build with CGO enabled
RUN CGO_ENABLED=1 GOOS=linux go build -o /app/server ./cmd/server

# Stage 2: Run
FROM alpine:latest

WORKDIR /app

# Install timezone data just in case
RUN apk add --no-cache tzdata

# Copy the compiled binary from the builder stage
COPY --from=builder /app/server /app/server
COPY --from=builder /app/.env /app/.env

# Optional: Ensure data directory exists
RUN mkdir -p /data

# Expose port
EXPOSE 7860

# Run the binary
CMD ["/app/server"]
