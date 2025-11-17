# BAD Dockerfile - Slow builds, large image
# Chapter 5: The Slow Release Nightmare
# Build time: ~45 minutes
# Image size: ~1.2 GB

FROM node:18

WORKDIR /app

# ❌ BAD: Copy everything first
# Any change to any file invalidates all layers below
COPY . .

# ❌ BAD: Install dependencies after copying code
# Runs every time any file changes
RUN npm install

# ❌ BAD: Build step included
RUN npm run build

# ❌ BAD: Runs as root user
# Security risk

# ❌ BAD: Includes dev dependencies, tests, docs, etc.
# Unnecessary files in production image

EXPOSE 8080

CMD ["npm", "start"]
