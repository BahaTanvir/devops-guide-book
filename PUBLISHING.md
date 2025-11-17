# Publishing Guide

## Repository Information

**GitHub Repository:** https://github.com/BahaTanvir/devops-guide-book  
**GitHub Pages:** https://bahatanvir.github.io/devops-guide-book/  
**Author:** BahaTanvir  

## Quick Start for New Contributors

```bash
# Clone the repository
git clone https://github.com/BahaTanvir/devops-guide-book.git
cd devops-guide-book

# Install mdBook if you haven't
cargo install mdbook

# Serve locally for development
mdbook serve

# View at http://localhost:3000
```

## GitHub Pages Deployment

### Automatic Deployment

This repository is configured for automatic deployment to GitHub Pages:

1. **Workflow File:** `.github/workflows/deploy.yml`
2. **Trigger:** Automatically runs on push to `main` branch
3. **Process:** 
   - Builds the book with mdBook
   - Deploys to GitHub Pages
   - Available at https://bahatanvir.github.io/devops-guide-book/

### Enabling GitHub Pages (First Time)

1. Go to repository Settings
2. Navigate to "Pages" section
3. Under "Build and deployment":
   - Source: GitHub Actions
4. The workflow will automatically deploy on next push

### Manual Deployment

To manually trigger deployment:
```bash
# Via GitHub UI: Actions → Deploy mdBook → Run workflow

# Or push to main
git push origin main
```

## Making Changes

### Writing Content

1. Create a new branch:
   ```bash
   git checkout -b feature/chapter-2
   ```

2. Edit markdown files in `src/`

3. Test locally:
   ```bash
   mdbook serve
   ```

4. Commit and push:
   ```bash
   git add .
   git commit -m "Add Chapter 2 content"
   git push origin feature/chapter-2
   ```

5. Open a Pull Request on GitHub

### Adding Code Examples

1. Add examples to appropriate `examples/chapter-XX/` directory

2. Test the examples:
   ```bash
   cd examples/chapter-01
   ./test.sh
   ```

3. Update the chapter's README.md with instructions

4. Commit and push as above

## Repository Structure

```
devops-guide-book/
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Pages deployment
├── src/                        # Book content
│   ├── SUMMARY.md             # Table of contents
│   ├── introduction.md
│   ├── part-01/               # Part I chapters
│   └── ...
├── examples/                   # Code examples
│   ├── chapter-01/
│   ├── scripts/
│   └── ...
├── book.toml                   # mdBook configuration
├── README.md                   # Project README
├── LICENSE                     # Dual license
└── CONTRIBUTING.md             # Contribution guidelines
```

## Publishing Checklist

Before making content public:

- [x] Repository created on GitHub
- [x] URLs updated to actual repository
- [x] GitHub Actions workflow configured
- [x] LICENSE file added
- [ ] GitHub Pages enabled
- [ ] Test deployment successful
- [ ] README badges updated
- [ ] All code examples tested
- [ ] Links verified
- [ ] Proofread content

## Content Status

### Completed
- ✅ Book structure (47 markdown files)
- ✅ Examples structure (43 directories)
- ✅ Chapter 1 complete (~25 pages + 10 code files)
- ✅ Helper scripts (setup, test, deploy, rollback)
- ✅ GitHub repository setup
- ✅ GitHub Pages workflow

### In Progress
- ⏳ Chapters 2-36 (35 chapters remaining)
- ⏳ Appendices (5 sections)
- ⏳ Diagrams and illustrations

### Planned
- 📋 Community contributions
- 📋 Translations
- 📋 PDF/EPUB versions
- 📋 Video walkthroughs

## Release Process

When ready to release new content:

1. **Test Everything:**
   ```bash
   mdbook test
   ./examples/scripts/test-examples.sh
   ```

2. **Create Release Branch:**
   ```bash
   git checkout -b release/v0.1.0
   ```

3. **Update Version Info:**
   - Update PROGRESS.md
   - Update README.md progress section
   - Tag significant milestones

4. **Merge to Main:**
   ```bash
   git checkout main
   git merge release/v0.1.0
   git tag v0.1.0
   git push origin main --tags
   ```

5. **Create GitHub Release:**
   - Go to Releases on GitHub
   - Create new release from tag
   - Add release notes
   - Attach PDF if available

## Monitoring

### Check Deployment Status
- Visit: https://github.com/BahaTanvir/devops-guide-book/actions
- Check latest workflow run
- View deployment logs if issues occur

### View Published Book
- Visit: https://bahatanvir.github.io/devops-guide-book/
- Test all links work
- Verify examples are accessible

## Troubleshooting

### Deployment Failed
1. Check workflow logs in Actions tab
2. Verify mdBook version compatibility
3. Check for broken links in SUMMARY.md
4. Ensure all referenced files exist

### Pages Not Updating
1. Check if deployment completed successfully
2. Clear browser cache
3. Wait a few minutes for CDN propagation
4. Check GitHub Pages settings

### Build Errors Locally
```bash
# Clean and rebuild
mdbook clean
mdbook build

# Check for specific errors
mdbook test
```

## Support

For issues or questions:
- **Issues:** https://github.com/BahaTanvir/devops-guide-book/issues
- **Discussions:** https://github.com/BahaTanvir/devops-guide-book/discussions
- **Contributing:** See CONTRIBUTING.md

---

**Repository:** https://github.com/BahaTanvir/devops-guide-book  
**Published Book:** https://bahatanvir.github.io/devops-guide-book/  
**License:** CC BY-SA 4.0 (content) + MIT (code examples)
