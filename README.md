# MR4GH Automations
Contains GitHub Actions and Workflows needed to enable automations in a Mediumroast for GitHub repository. Installation and management of these actions is managed by Mediumroast for GitHub users using either CLI or API/SDK.

## Environmental Variables
Workflows and Actions optionally can make use of an `MR4GH` environment set in the Mediumroast for GitHub repository.  This environment can be created manually, but for consistency, it is better managed and updated through the CLI and API/SDK.

- MAX_BRANCHES - Defaults to 15, picked up by the `prune-branches` workflow, and used in the `prune-branches` action.

## Available Workflows
The following Workflows are available to operate the custom Actions.

### prune-branches.yml
Automatically manages the number of branches in your repository by pruning older timestamp-based branches. This workflow runs daily at midnight and can also be triggered manually. It uses the MAX_BRANCHES environment variable (defaults to 15) to determine how many numeric-named branches to keep, deleting the oldest ones when the limit is exceeded. Branches with non-numeric names (like 'main' or 'master') are preserved.

### basic-reporting.yml
Generates basic reports for companies and studies in your Mediumroast for GitHub repository. This workflow runs daily at midnight and can also be triggered manually. It checks out your repository, sets up a Node.js environment, and executes the basic-reporting action to create and update standardized reports. The workflow requires write access to repository contents to commit the generated reports.

## Available Actions
The following custom actions help to improve the user experience and better manage the Mediumroast for GitHub repository.

### prune-branches

A GitHub Action that automatically manages the number of numeric timestamp-based branches in your repository. This action is designed to prevent branch proliferation while maintaining a configurable history of recent branches.

#### Purpose

When workflows or automated processes create timestamp-named branches (e.g., `1706153906529`), repositories can quickly accumulate hundreds of branches. This action keeps your repository clean by:
- Preserving a specific number of the most recent timestamp branches
- Automatically removing older timestamp branches that exceed the limit
- Never touching non-numeric branches (like `main`, `master`, `develop`, etc.)

#### How It Works

1. Lists all branches in the repository
2. Identifies branches with purely numeric names (assumed to be timestamp-based)
3. Counts non-numeric branches (these are always preserved)
4. If the count of numeric branches exceeds the configured limit, removes the oldest ones until the limit is satisfied

#### Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `github-token` | GitHub token with permissions to delete branches | N/A | Yes |
| `MAX_BRANCHES` | Maximum number of numeric branches to keep | 15 | No |

The `MAX_BRANCHES` value can be set as an environment variable in your workflow or in the `MR4GH` environment.

#### Usage Example

This action is typically used through the `prune-branches.yml` workflow, which runs it on a daily schedule. However, you can also invoke it directly in your own workflows:

```yaml
- name: Prune timestamp branches
  uses: ./.github/actions/prune-branches
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
  env:
    MAX_BRANCHES: 20  # Optional: customize branch limit
```

#### Considerations
- Only operates on branches with purely numeric names
- Requires write permissions to repository contents
- Uses timestamps to determine branch age (oldest branches are removed first)
- Logs each branch deletion for audit purposes


### basic-reporting

A GitHub Action that automatically generates standardized reports for companies and studies in your Mediumroast for GitHub repository. This action creates and updates markdown files that provide comprehensive information about the repository's contents.

#### Purpose

The basic-reporting action simplifies the process of maintaining up-to-date documentation by:
- Creating/updating individual markdown files for each company and study
- Generating README.md files with tables of contents and overviews
- Producing interactive maps of company locations
- Highlighting relationships between companies and interactions
- Summarizing repository workflow status and branch information

#### How It Works

1. Reads company, interaction, and study data from JSON files in the repository
2. Retrieves current workflow and branch information from the repository
3. Generates standardized markdown reports for each company and study
4. Creates directory README.md files with tables and overviews
5. Updates the main repository README.md with overall statistics
6. Reconciles the repository by removing markdown files for companies that no longer exist

#### Report Content

The action generates several types of markdown files:

**Company Profiles:**
- Company details (name, description, industry, role, region)
- Interactive location map
- Web links to external resources
- Related interactions
- Similar companies and insights

**Study Reports:**
- Study overview and description
- Top insights derived from interactions
- Company relationships

**Directory README.md Files:**
- Tables of companies/studies with key attributes
- Interactive maps of company locations
- Navigation links between reports

**Main README.md:**
- Repository overview and statistics
- Workflow status and runtime information
- Branch information and last commit details

#### Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `github-token` | GitHub token with permissions to read/write repository contents | N/A | Yes |

#### Usage Example

This action is typically used through the `basic-reporting.yml` workflow, which runs it on a daily schedule. However, you can also invoke it directly in your own workflows:

```yaml
- name: Generate reports
  uses: ./.github/actions/basic-reporting
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

#### Considerations
- Requires read/write access to repository contents
- Designed specifically for Mediumroast for GitHub repositories
- Automatically reconciles reports when companies are removed
- Overwrites existing reports - manual edits to generated files will be lost
- Uses node.js and the mr_markdown_builder library for consistent formatting

## Installation, Updates, Deletes
The following types of software lifecycle management operations are possible. The recommended approach is to use either the npm package called `mediumroast_api` or the command line interface, also available on npm, called `mediumroast_js`.

### Using git or Using the latest published release
You can install, update, or delete these automations directly using git commands or a published release.

#### Installation 

##### Option 1: Using Git

1. Clone the MR4GH automations repository to a temporary location:
    
```bash
cd /tmp
git clone https://github.com/mediumroast/mr4gh-automations.git /tmp/mr4gh-automations
```

2. Create necessary directories in your repository:
```bash
mkdir -p .github/workflows
mkdir -p .github/actions/prune-branches
mkdir -p .github/actions/basic-reporting
```

3. Copy the workflows and actions to your repository:
```bash
# Copy workflows
cp /tmp/mr4gh-automations/workflows/*.yml .github/workflows/

# Copy actions
cp -r /tmp/mr4gh-automations/actions/prune-branches/* .github/actions/prune-branches/
cp -r /tmp/mr4gh-automations/actions/basic-reporting/* .github/actions/basic-reporting/
```

##### Option 2: Using the latest GitHub release

1. Download the latest release from the GitHub repository:

```bash
# Create a temporary directory
mkdir -p /tmp/mr4gh-release
cd /tmp/mr4gh-release

# Download the latest release archive
curl -L https://github.com/mediumroast/mr4gh-automations/archive/refs/tags/latest.zip -o mr4gh-automations.zip

# Extract the archive
unzip mr4gh-automations.zip
cd mr4gh-automations-latest
```

2. Create necessary directories in your repository:
```bash
mkdir -p .github/workflows
mkdir -p .github/actions/prune-branches
mkdir -p .github/actions/basic-reporting
```

3. Copy the workflows and actions to your repository:

```bash
# Copy workflows
cp workflows/*.yml .github/workflows/

# Copy actions
cp -r actions/prune-branches/* .github/actions/prune-branches/
cp -r actions/basic-reporting/* .github/actions/basic-reporting/
```

4. Commit and push the changes:
```bash
git add .github
git commit -m "Add MR4GH automations"
git push
```

5. Set up the MR4GH environment in your GitHub repository settings with any required environment variables.

#### Updating

##### Option 1: Using Git

1. Clone the latest version of the MR4GH automations:
```bash
cd /tmp
git clone https://github.com/mediumroast/mr4gh-automations.git /tmp/mr4gh-automations
```

2. Update the workflows and actions:
```bash
# Update workflows
cp /tmp/mr4gh-automations/workflows/*.yml .github/workflows/

# Update actions
cp -r /tmp/mr4gh-automations/actions/prune-branches/* .github/actions/prune-branches/
cp -r /tmp/mr4gh-automations/actions/basic-reporting/* .github/actions/basic-reporting/
```

##### Option 2: Using the latest GitHub release

1. Download the latest release from the GitHub repository:

```bash
# Create a temporary directory
mkdir -p /tmp/mr4gh-release
cd /tmp/mr4gh-release

# Download the latest release archive
curl -L https://github.com/mediumroast/mr4gh-automations/archive/refs/tags/latest.zip -o mr4gh-automations.zip

# Extract the archive
unzip mr4gh-automations.zip
cd mr4gh-automations-latest
```

2. Update the workflows and actions in your repository:

```bash
# Update workflows
cp workflows/*.yml .github/workflows/

# Update actions
cp -r actions/prune-branches/* .github/actions/prune-branches/
cp -r actions/basic-reporting/* .github/actions/basic-reporting/
```

3. Commit and push the changes:
```bash
git add .github
git commit -m "Update MR4GH automations"
git push
```

#### Deletion
1. Delete the workflow files:
```bash
rm .github/workflows/prune-branches.yml
rm .github/workflows/basic-reporting.yml
```

2. Delete the action directories:
```bash
rm -rf .github/actions/prune-branches
rm -rf .github/actions/basic-reporting
```

3. Commit and push the changes:
```bash
git add .github
git commit -m "Remove MR4GH automations"
git push
```

4. Remove the MR4GH environment in your GitHub repository settings.

### Using the latest published release

### Using `mediumroast_api`
To be authored

### Using `mediumroast_js`
To be authored
