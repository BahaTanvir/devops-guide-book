# GOOD Dockerfile - Fast builds, small image
# Chapter 5: The Slow Release Nightmare
# Build time: ~8 minutes (with caching)
# Image size: ~180 MB

# Multi-stage build

# Stage 1: Install production dependencies
FROM node:18-alpine AS deps
WORKDIR /app

# ✅ GOOD: Copy only dependency files first
COPY package*.json ./

# ✅ GOOD: Install only production dependencies
# This layer is cached if package.json hasn't changed
RUN npm ci --only=production

# Stage 2: Build application
FROM node:18-alpine AS builder
WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install all dependencies (including dev)
RUN npm ci

# ✅ GOOD: Copy source code last
# Code changes don't invalidate dependency layer
COPY . .

# Build the application
RUN npm run build

# Stage 3: Production runtime
FROM node:18-alpine AS runtime
WORKDIR /app

# ✅ GOOD: Only copy necessary files from previous stages
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./

# ✅ GOOD: Run as non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001
USER nodejs

EXPOSE 8080

# ✅ GOOD: Direct node command (no npm overhead)
CMD ["node", "dist/index.js"]

# Final image only contains:
# - Alpine base (5MB)
# - Node runtime (small)
# - Production dependencies
# - Compiled application
# - No build tools, dev dependencies, or source code
