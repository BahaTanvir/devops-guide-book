# Setup Guide

This guide helps you set up the book for local development or publishing.

## For Local Reading and Development

### Prerequisites
- Install mdBook: `cargo install mdbook` or `brew install mdbook`

### Build and Read the Book

```bash
# Serve the book locally (with live reload)
mdbook serve

# Build static HTML
mdbook build

# Clean build artifacts
mdbook clean
```

The book will be available at `http://localhost:3000` when serving.

## For Publishing to GitHub

### Step 1: Create GitHub Repository

1. Create a new repository on GitHub (e.g., `devops-engineering-guide`)
2. Note your repository URL

### Step 2: Update Configuration

Update the following files with your actual GitHub repository URL:

**book.toml:**
```toml
git-repository-url = "https://github.com/YOUR-USERNAME/YOUR-REPO"
edit-url-template = "https://github.com/YOUR-USERNAME/YOUR-REPO/edit/main/{path}"
```

**README.md:**
- Update all references to repository URL
- Update community links (Issues, Discussions)

### Step 3: Initialize Git (if not already done)

```bash
git init
git add .
git commit -m "Initial commit: DevOps Guide book structure and Chapter 1"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
git push -u origin main
```

### Step 4: Enable GitHub Pages

1. Go to your repository settings
2. Navigate to "Pages" section
3. Set source to GitHub Actions
4. Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy mdBook

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pages: write
      id-token: write
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup mdBook
        uses: peaceiris/actions-mdbook@v1
        with:
          mdbook-version: 'latest'
      
      - name: Build book
        run: mdbook build
      
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v2
        with:
          path: ./book
      
      - name: Deploy to GitHub Pages
        uses: actions/deploy-pages@v2
```

### Step 5: Set Custom Domain (Optional)

If you have a custom domain:

1. Update `book.toml`:
   ```toml
   [output.html]
   cname = "yourdomain.com"
   ```

2. Configure DNS:
   - Add CNAME record pointing to `YOUR-USERNAME.github.io`

## For Contributing

If you're contributing to this book:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/chapter-X`
3. Make your changes
4. Test locally: `mdbook serve`
5. Commit and push
6. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## Directory Structure

```
devops-guide-book/
├── book.toml              # mdBook configuration
├── src/                   # Book content (Markdown files)
│   ├── SUMMARY.md        # Table of contents
│   ├── chapter-*.md      # Chapter files
│   └── ...
├── examples/             # Code examples
│   ├── chapter-01/       # Chapter-specific examples
│   ├── scripts/          # Helper scripts
│   └── ...
├── book/                 # Generated output (gitignored)
└── README.md            # Project README
```

## Troubleshooting

### mdBook not found
```bash
# Install via cargo
cargo install mdbook

# Or via package manager
brew install mdbook  # macOS
```

### Port 3000 already in use
```bash
# Serve on different port
mdbook serve --port 3001
```

### Changes not reflecting
```bash
# Hard refresh browser (Ctrl+Shift+R or Cmd+Shift+R)
# Or restart mdbook serve
```

### Build errors
```bash
# Check SUMMARY.md for broken links
# Ensure all referenced files exist
# Validate markdown syntax
```

## Publishing Checklist

Before publishing publicly:

- [ ] Update all repository URLs from placeholder
- [ ] Review and update README.md
- [ ] Add LICENSE file
- [ ] Configure GitHub Pages
- [ ] Test all code examples work
- [ ] Proofread content
- [ ] Add contributing guidelines
- [ ] Set up issue templates
- [ ] Create release notes

## Next Steps

- [ ] Complete remaining chapters
- [ ] Add diagrams and illustrations
- [ ] Set up automated testing for code examples
- [ ] Create PDF/EPUB versions
- [ ] Gather community feedback
- [ ] Iterate and improve

---

For questions or issues with setup, please refer to:
- [mdBook Documentation](https://rust-lang.github.io/mdBook/)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
