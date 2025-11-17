# Contributing to A Guide to DevOps Engineering

Thank you for your interest in contributing to this open-source book! This guide is a community effort to help junior DevOps engineers bridge the gap to senior-level expertise.

## 🎯 Our Mission

To create the most practical, scenario-based DevOps guide that helps junior engineers:
- Learn from real-world experiences
- Understand the "why" behind best practices
- Gain confidence in production environments
- Accelerate their professional growth

## 🤝 How You Can Contribute

### 1. Report Issues

Found a problem? Please open an issue for:
- **Technical errors** in code examples
- **Broken links** or missing resources
- **Typos and grammar** mistakes
- **Outdated information** (tool versions, deprecated practices)
- **Unclear explanations** that need improvement

### 2. Suggest Improvements

Have ideas? We'd love to hear about:
- **Additional scenarios** Sarah should encounter
- **Missing topics** that should be covered
- **Better explanations** for complex concepts
- **Diagrams** that would help visualize concepts
- **Real-world examples** from your experience

### 3. Submit Content

Ready to write? You can contribute:
- **New chapters** on relevant DevOps topics
- **Case studies** from your own experience
- **Code examples** and configurations
- **Troubleshooting guides**
- **Diagrams and illustrations**

### 4. Improve Existing Content

Help make existing chapters better:
- Enhance code examples
- Add more detailed explanations
- Create better diagrams
- Add tips and warnings from experience
- Update content for new tool versions

### 5. Translate

Help make this book accessible globally:
- Translate chapters to other languages
- Review existing translations
- Maintain localized versions

## 📝 Contribution Guidelines

### Writing Style

When contributing content, please follow these guidelines:

#### Voice and Tone
- **Conversational** but professional
- **Empathetic** to junior engineer struggles
- **Practical** over theoretical
- **Encouraging** without being condescending

#### Technical Content
- **Accurate** — test all code examples
- **Production-ready** — no toy examples
- **Explained** — don't just show, explain why
- **Comprehensive** — cover edge cases and gotchas

#### Scenario Structure
If writing a new chapter, follow this structure:
1. **Sarah's Challenge** — The problem/scenario
2. **Understanding the Problem** — Concepts and context
3. **The Senior's Perspective** — Expert insights
4. **The Solution** — Step-by-step implementation
5. **Lessons Learned** — Key takeaways
6. **Reflection Questions** — Help readers apply concepts

### Code Standards

All code examples must:
- ✅ **Work** — be tested and functional
- ✅ **Follow best practices** — industry standards
- ✅ **Include comments** — explain non-obvious parts
- ✅ **Be secure** — no hardcoded secrets or vulnerabilities
- ✅ **Be formatted** — use consistent style

Example:
```yaml
# Good: Well-commented, explains the why
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app: frontend
spec:
  # Using ClusterIP since this service is internal-only
  # and accessed via Ingress controller
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: frontend
```

### Markdown Standards

- Use proper heading hierarchy (# → ## → ###)
- Include code fences with language specification
- Use **bold** for emphasis, *italic* for terms
- Add alt text to all images
- Keep line length reasonable (~100 characters)

### Diagram Guidelines

If adding diagrams:
- Use consistent styling and colors
- Include source files (draw.io, mermaid, etc.)
- Export as SVG when possible (scales better)
- Add descriptive captions
- Consider accessibility (color blind friendly)

## 🔄 Submission Process

### For Small Changes (typos, small fixes)

1. Fork the repository
2. Create a branch: `git checkout -b fix/typo-chapter-15`
3. Make your changes
4. Commit: `git commit -m "Fix typo in chapter 15"`
5. Push: `git push origin fix/typo-chapter-15`
6. Open a Pull Request

### For Larger Contributions (new content, major changes)

1. **Open an issue first** to discuss your idea
2. Get feedback from maintainers
3. Fork and create a branch
4. Write your content
5. Test all code examples
6. Submit a Pull Request with detailed description

### Pull Request Checklist

Before submitting, ensure:
- [ ] Content follows the writing guidelines
- [ ] Code examples are tested and work
- [ ] No sensitive information (API keys, passwords, etc.)
- [ ] Markdown is properly formatted
- [ ] Links are working
- [ ] Diagrams have source files included
- [ ] You've added yourself to contributors list (if first contribution)

## 👀 Review Process

### What to Expect

1. **Initial review** within 1 week
2. **Feedback** from maintainers and community
3. **Iterations** to refine the content
4. **Approval** from at least 2 maintainers
5. **Merge** and inclusion in next release

### Review Criteria

Contributions are evaluated on:
- **Accuracy** — Is the technical content correct?
- **Relevance** — Does it fit the book's scope?
- **Quality** — Is it well-written and clear?
- **Completeness** — Are examples and explanations sufficient?
- **Consistency** — Does it match the book's style?

## 🎨 Content Guidelines by Type

### Adding a New Chapter

Required elements:
- Fits within existing book structure
- Includes a realistic scenario for Sarah
- Has working code examples
- Follows chapter template structure
- Adds 15-25 pages of content
- Includes reflection questions

### Adding Code Examples

Requirements:
- Tested in a real environment
- Includes necessary context/setup
- Has inline comments explaining key points
- Shows best practices
- Includes error handling where appropriate

### Adding Diagrams

Guidelines:
- Use consistent color scheme (navy/blue theme)
- Include architecture context
- Label all components clearly
- Show data flow with arrows
- Include legend if needed

### Updating Existing Content

When updating:
- Preserve the original scenario/narrative
- Improve clarity without changing meaning
- Update tool versions in comments
- Add deprecation warnings if needed
- Link to additional resources

## 🛠️ Development Setup

### Prerequisites

```bash
# Install mdBook
cargo install mdbook

# Or using package manager
brew install mdbook  # macOS
```

### Local Development

```bash
# Clone the repository
git clone https://github.com/yourusername/devops-guide-book.git
cd devops-guide-book

# Serve the book locally
mdbook serve

# Open in browser: http://localhost:3000

# Build the book
mdbook build

# Test all code examples
./scripts/test-examples.sh
```

### Testing Your Changes

Before submitting:
```bash
# Check markdown formatting
mdbook test

# Verify all links
./scripts/check-links.sh

# Test code examples
./scripts/test-code.sh
```

## 📜 Licensing

By contributing, you agree that:
- Your contributions will be licensed under the same license as the project
- You have the right to submit the contribution
- You're not including proprietary or confidential information

## 🌟 Recognition

All contributors are:
- Added to the contributors list
- Credited in commit history
- Acknowledged in release notes
- Appreciated by the community! 🎉

## 💬 Getting Help

Need help with your contribution?

- **GitHub Issues** — Ask questions
- **Discussions** — Chat with the community
- **Email** — Reach out to maintainers (coming soon)
- **Discord** — Join our community (coming soon)

## 📋 Priority Areas

We especially need help with:

1. **Real-world scenarios** — Share your experiences
2. **Diagrams** — Visual learners need more graphics
3. **Code examples** — More working examples
4. **Troubleshooting sections** — Common issues and solutions
5. **Translations** — Make it accessible globally

## 🎯 Good First Issues

New to contributing? Look for issues labeled:
- `good-first-issue` — Great for beginners
- `help-wanted` — We need assistance
- `documentation` — Improve docs
- `typo` — Quick fixes

## 📚 Resources for Contributors

- [mdBook Documentation](https://rust-lang.github.io/mdBook/)
- [Markdown Guide](https://www.markdownguide.org/)
- [Writing Style Guide](./STYLE_GUIDE.md)
- [Code of Conduct](./CODE_OF_CONDUCT.md)

## ❓ Questions?

Don't hesitate to ask! Open an issue with the `question` label.

---

**Thank you for helping junior DevOps engineers learn and grow!** 🚀

Every contribution, no matter how small, makes a difference in someone's career journey.
