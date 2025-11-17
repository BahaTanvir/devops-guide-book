# About Sarah

Before we dive into the technical journey, let's get to know Sarah — the junior DevOps engineer you'll be following throughout this book.

## Sarah's Background

**Sarah Martinez** is 27 years old and has been working as a DevOps engineer for about 8 months at **TechFlow**, a mid-sized SaaS company with approximately 150 employees. TechFlow provides a B2B project management platform used by thousands of companies worldwide.

### Her Journey to DevOps

Sarah didn't start in DevOps. Like many in the field, she took a winding path:

- **Computer Science degree** from a state university (graduated 3 years ago)
- **First job**: Junior software developer at a small consultancy, building web applications
- **Transition**: After 2 years of development, she became curious about how applications get deployed, monitored, and scaled
- **Current role**: Joined TechFlow's platform team 8 months ago as their second DevOps engineer

### What She Knows

Sarah has solid foundations in:
- **Programming**: Comfortable with Python and JavaScript; can write Bash scripts
- **Linux**: Daily user, knows common commands, can SSH and navigate servers
- **Docker**: Has containerized several applications, understands images and containers
- **AWS basics**: Can launch EC2 instances, create S3 buckets, and navigate the console
- **Git**: Proficient with branches, commits, pull requests, and merge conflicts
- **CI/CD**: Has set up basic GitHub Actions workflows

### What She's Learning

Sarah is still getting comfortable with:
- **Kubernetes**: Deployed a few services but doesn't fully understand the networking model
- **Terraform**: Can modify existing code but struggles with state management and modules
- **Monitoring**: Knows she should monitor things, but unsure what metrics matter
- **Incident response**: Has been paged once and it was stressful
- **Making decisions**: Often second-guesses herself when choosing between approaches

### Her Challenges

Like most junior engineers, Sarah faces common challenges:

1. **Imposter syndrome**: Surrounded by senior engineers who seem to know everything
2. **Information overload**: Every solution seems to require learning three new tools
3. **Production anxiety**: Fears breaking things in production
4. **Unknown unknowns**: Doesn't know what she doesn't know
5. **Time pressure**: Balancing learning with delivering on sprint commitments

## The TechFlow Environment

To understand Sarah's scenarios, it helps to know her company's technical landscape:

### The Application

TechFlow runs a microservices architecture with:
- **12 core services** (user management, projects, tasks, notifications, etc.)
- **3 frontend applications** (web app, mobile API, admin panel)
- **PostgreSQL databases** (RDS on AWS)
- **Redis** for caching and session management
- **RabbitMQ** for async messaging

### The Infrastructure

- **Cloud Provider**: AWS
- **Orchestration**: Kubernetes (EKS) with 3 clusters (dev, staging, production)
- **IaC**: Terraform for infrastructure, Helm for Kubernetes deployments
- **CI/CD**: GitHub for code, GitHub Actions for CI/CD pipelines
- **Monitoring**: Prometheus and Grafana (recently adopted)
- **Logging**: CloudWatch Logs (migrating to ELK stack)

### The Team

Sarah works on the **Platform Team**:
- **Marcus** (Engineering Manager) — Former DevOps lead, now managing the team
- **James** (Senior DevOps Engineer) — 7 years experience, Sarah's mentor, very patient
- **Sarah** (DevOps Engineer) — That's our protagonist!
- **Priya** (DevOps Engineer) — Joined 3 months after Sarah, also learning

The team also collaborates closely with:
- **Development teams** (3 teams, ~15 developers total)
- **Product team** (defining features and priorities)
- **On-call rotation** (all engineers participate)

## Why Sarah?

Sarah represents the reality of junior DevOps engineers:

- **She's capable** but not yet confident
- **She knows the basics** but lacks production experience
- **She's eager to learn** but sometimes overwhelmed
- **She makes mistakes** and learns from them
- **She asks questions** even when she feels she should "already know"
- **She's relatable** — her challenges are probably your challenges too

## Sarah's Goals

Throughout this book, Sarah aims to:

1. ✅ Build confidence in making production decisions
2. ✅ Develop systematic approaches to debugging and problem-solving
3. ✅ Understand the "why" behind best practices, not just the "what"
4. ✅ Learn to balance quick fixes with proper solutions
5. ✅ Communicate technical concepts effectively
6. ✅ Eventually mentor other junior engineers

## Following Sarah's Journey

Each chapter presents a real scenario Sarah encounters at TechFlow. You'll see:

- Her initial reaction and uncertainty
- How she approaches the problem
- Guidance from James (the senior engineer)
- The solution and its reasoning
- Lessons she takes away

Sarah's journey isn't linear — she'll make mistakes, circle back to concepts, and gradually build competence. Just like real professional growth.

## Your Journey Alongside Sarah

As you read Sarah's story:

- **Reflect on your own experiences** — Have you faced similar challenges?
- **Notice the thought processes** — How does Sarah's thinking evolve?
- **Try the examples** — All the code and configurations are real and runnable
- **Ask "what if"** — How would you handle different constraints or contexts?

Remember: Sarah is learning, and so are you. It's okay to not understand everything immediately. The goal is progress, not perfection.

---

Now that you know Sarah, let's talk about how to get the most out of this book.

[Continue to How to Use This Book →](./how-to-use.md)
