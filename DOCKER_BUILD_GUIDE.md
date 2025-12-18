# Docker Build & Publish Guide

## Automatic GitHub Actions Build

The repository is configured to automatically build and publish Docker images to GitHub Container Registry (ghcr.io) **without requiring any secrets**.

### How It Works

The workflow uses `GITHUB_TOKEN` which is **automatically provided** by GitHub Actions. No manual secret configuration needed!

### When Images Are Built

1. **On push to main branch**: Creates `latest` and `main` tags
2. **On version tags** (e.g., `v1.2.3`): Creates versioned tags (`1.2.3`, `1.2`, `1`)
3. **On pull requests**: Builds but doesn't push (for testing)
4. **Manual trigger**: Via Actions tab (creates `{branch}-manual` tag)

### Your Image Location

After pushing to main, your image will be available at:
```
ghcr.io/gspiliotis/mcp-atlassian:latest
```

### Setup (One-time)

1. **Enable GitHub Actions**:
   - Go to your repo → Settings → Actions → General
   - Ensure "Allow all actions and reusable workflows" is selected

2. **Enable GitHub Packages**:
   - Go to your repo → Settings → Actions → General → Workflow permissions
   - Select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"

3. **Make package public** (after first build):
   - Go to https://github.com/users/gspiliotis/packages
   - Find `mcp-atlassian`
   - Click → Package settings → Change visibility → Public

### Triggering a Build

**Method 1: Push to main**
```bash
git add .
git commit -m "Add Basic auth support"
git push origin main
```

**Method 2: Manual trigger**
- Go to Actions tab → "Docker Publish" → "Run workflow"

**Method 3: Create a version tag**
```bash
git tag v1.0.0
git push origin v1.0.0
```

### Using Your Custom Image

Update your `docker-compose.yml`:
```yaml
services:
  mcp-jira:
    image: ghcr.io/gspiliotis/mcp-atlassian:latest
    # ... rest of config
```

Or pull manually:
```bash
docker pull ghcr.io/gspiliotis/mcp-atlassian:latest
```

### Local Build (for testing)

```bash
# Build locally
docker build -t mcp-atlassian-test:latest .

# Test it
docker run -it --rm \
  -e JIRA_URL=https://jira.example.com \
  -e JIRA_USERNAME=test \
  -e JIRA_API_TOKEN=test \
  mcp-atlassian-test:latest
```

## Troubleshooting

**Build fails with permission error**:
- Check Settings → Actions → Workflow permissions
- Ensure "Read and write permissions" is enabled

**Can't pull image**:
- Make sure the package is public
- Or authenticate: `echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin`

**Want to see build progress**:
- Go to Actions tab → Click on the running workflow
