# Git Workflow for DevOps Guide Book

## Strategy: Main-Based Development with Tags

### Philosophy
- `main` branch is always in a deployable state
- Commit frequently with clear messages
- Tag major milestones (parts, chapters)
- GitHub Pages auto-deploys from `main`

## Commit Message Convention

### Format
```
<type>: <description>

[optional body]
[optional footer]
```

### Types
- `content:` - Chapter content changes
- `examples:` - Code example updates
- `fix:` - Bug fixes in examples or content
- `docs:` - Documentation updates (README, etc.)
- `structure:` - Book structure changes
- `chore:` - Maintenance tasks

### Examples
```bash
# Single chapter
git commit -m "content: Complete Chapter 6 - Terraform State"

# Multiple changes
git commit -m "content: Add Chapter 6 content and examples

- Write Chapter 6 narrative (23 pages)
- Add 12 Terraform examples
- Create test scripts
- Update PROGRESS.md"

# Fix
git commit -m "fix: Correct Terraform syntax in Chapter 6 example"

# Structure
git commit -m "structure: Reorganize Part II outline"
```

## Tagging Strategy

### Tag Format
```
v<major>.<minor>[-description]

Examples:
v0.1          - Part I complete
v0.2          - Part II complete
v0.3          - Part III complete
v1.0          - Full book v1.0
v1.1          - Book update
```

### Creating Tags
```bash
# Lightweight tag (simple marker)
git tag v0.1

# Annotated tag (with message - recommended)
git tag -a v0.1 -m "Part I: Foundations Complete (5 chapters, 115 pages)"

# Push tags
git push origin v0.1
git push origin --tags  # Push all tags
```

### Tag Milestones
- `v0.1` - Part I Complete ✅
- `v0.2` - Part II Complete
- `v0.3` - Part III Complete
- `v0.4` - Part IV Complete
- `v0.5` - Part V Complete
- `v0.6` - Part VI Complete
- `v0.7` - Part VII Complete
- `v0.9` - All chapters complete (pre-release)
- `v1.0` - First official release
- `v1.1` - Updates and improvements

## Daily Workflow

### Starting Work
```bash
# Make sure you're on main
git checkout main

# Pull latest changes (if collaborating)
git pull origin main

# Start writing!
```

### Committing Work
```bash
# Check what changed
git status
git diff

# Stage changes
git add src/part-02/chapter-06*.md
git add examples/chapter-06/

# Commit with clear message
git commit -m "content: Complete Chapter 6 narrative and examples"

# Push to GitHub
git push origin main
```

### Tagging Milestones
```bash
# When you complete a part
git tag -a v0.2 -m "Part II: Infrastructure as Code Complete (5 chapters)"
git push origin v0.2

# View all tags
git tag -l

# View tag details
git show v0.2
```

## Branch Strategy (When Needed)

### Experimental Work
If you want to try something experimental:

```bash
# Create experimental branch
git checkout -b experiment/new-chapter-structure

# Work on experiment
git add .
git commit -m "experiment: Try new chapter format"

# If it works, merge back
git checkout main
git merge experiment/new-chapter-structure

# If it doesn't work, delete
git branch -D experiment/new-chapter-structure
```

### Hotfix for Published Version
If you need to fix something urgent:

```bash
# Create hotfix branch from tag
git checkout -b hotfix/chapter-1-typo v0.1

# Fix issue
git add .
git commit -m "fix: Correct typo in Chapter 1"

# Merge back to main
git checkout main
git merge hotfix/chapter-1-typo

# Create patch tag
git tag -a v0.1.1 -m "Fix typos in Part I"
git push origin main --tags

# Delete hotfix branch
git branch -d hotfix/chapter-1-typo
```

## GitHub Pages Deployment

### Auto-Deploy
- Every push to `main` triggers GitHub Actions
- Builds mdBook
- Deploys to GitHub Pages
- Available at: https://bahatanvir.github.io/devops-guide-book/

### Manual Build Check
```bash
# Test build locally before pushing
mdbook build

# Serve locally to preview
mdbook serve
```

## Rollback Strategy

### Undo Last Commit (Not Pushed)
```bash
# Undo commit but keep changes
git reset --soft HEAD~1

# Undo commit and discard changes
git reset --hard HEAD~1
```

### Revert Pushed Commit
```bash
# Create new commit that undoes previous commit
git revert <commit-hash>
git push origin main
```

### Rollback to Previous Tag
```bash
# View tags
git tag -l

# Rollback to specific tag
git reset --hard v0.1
git push origin main --force  # Use with caution!
```

## Collaboration (Future)

If others contribute:

### Pull Request Workflow
```bash
# Contributor creates fork and branch
git checkout -b feature/chapter-6-improvements

# Makes changes and pushes
git push origin feature/chapter-6-improvements

# Creates Pull Request on GitHub
# You review and merge
```

## Best Practices

### DO
✅ Commit frequently with clear messages
✅ Tag major milestones
✅ Push to GitHub regularly (backup)
✅ Test mdbook build before pushing
✅ Keep PROGRESS.md updated
✅ Write descriptive commit messages

### DON'T
❌ Force push to main (unless necessary)
❌ Commit incomplete chapters
❌ Leave uncommitted changes for days
❌ Skip testing the build
❌ Use vague commit messages ("update", "fix")

## Current Status

- **Branch:** `main`
- **Latest Tag:** None yet
- **Next Tag:** `v0.1` (Part I Complete)

## Recommended First Actions

```bash
# 1. Commit current work
git add .
git commit -m "content: Complete Part I - Foundations (5 chapters, 115 pages)"

# 2. Tag Part I completion
git tag -a v0.1 -m "Part I: Foundations Complete

- Chapter 1: The Incident That Changed Everything
- Chapter 2: The Mystery of the Disappearing Logs  
- Chapter 3: It Works on My Machine
- Chapter 4: The Resource Crunch
- Chapter 5: The Slow Release Nightmare

Total: 5,073 lines, 59 examples, ~115 pages"

# 3. Push everything
git push origin main
git push origin v0.1

# 4. Verify GitHub Pages deployed
# Visit: https://bahatanvir.github.io/devops-guide-book/
```

## Future Releases

- `v0.2` - Part II: Infrastructure as Code
- `v0.3` - Part III: Container Orchestration
- `v0.4` - Part IV: Observability and Reliability
- `v0.5` - Part V: Security and Compliance
- `v0.6` - Part VI: CI/CD Mastery
- `v0.7` - Part VII: Collaboration and Culture
- `v1.0` - Complete Book Release! 🎉
