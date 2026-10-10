<div align="center">

# Swift Git Helper (`swit`)

> A CLI helper for Git that suggests a [Conventional Commit](https://www.conventionalcommits.org/) message with a local Ollama LLM. It commits only after you confirm.

`swit` reads your repository's `git status` and `git diff`. It sends them to a local model and proposes a commit message. You then accept, edit or abort. Nothing leaves your machine and nothing is committed without your explicit approval.

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg?style=flat-square) ![Swift](https://img.shields.io/badge/Swift-6.0+-F05138.svg?style=flat-square&logo=swift&logoColor=white) ![Ollama](https://img.shields.io/badge/Ollama-local%20LLM-000000.svg?style=flat-square&logo=ollama&logoColor=white) ![Git](https://img.shields.io/badge/Git-required-F05032.svg?style=flat-square&logo=git&logoColor=white) ![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-fe5196.svg?style=flat-square&logo=conventionalcommits&logoColor=white) ![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg?style=flat-square)

## Table of Contents

[Quick Start](#quick-start) • [Features](#features) • [Requirements](#requirements) • [Installation](#installation) • [Usage](#usage) • [Commit Workflow](#commit-workflow) • [Configuration](#configuration) • [Command Reference](#command-reference) • [Safety](#safety) • [Testing](#testing) • [Help](#help) • [Author](#author) • [License](#license) • [Changelog](#changelog)

</div>

## Quick Start

```bash
cd /path/to/your/repo
swit commit
```

1. Pick a staging mode
2. Review the generated message
3. Press `y` to commit, `e` to edit or `n` to abort

Preview only, with nothing staged or committed:

```bash
swit commit . --dry-run
```

## Features

- **Local and private:** uses your own Ollama instance, so no cloud API is involved
- **Conventional Commits:** generated messages are validated and retried automatically if they don't conform
- **Flexible staging:** choose `staged`, `tracked` or `all`
- **Interactive review:** accept (`y`), edit (`e`) or abort (`n`)
- **Safe dry run:** preview a message without touching your index or history
- **Configurable:** set the model, host, temperature, context window, and keep-alive; settings can be global or per repository
- **Clear errors:** meaningful messages and exit codes

## Requirements

| Requirement | Check | Notes |
|---|---|---|
| Swift 6.0+ | `swift --version` | Needed to build from source |
| Git | `git --version` | Must be in your `PATH` |
| Ollama | `ollama serve` | Must be running |
| Model | `ollama pull qwen2.5-coder:7b` | Default model |

Start Ollama and pull the default model:

```bash
ollama serve
ollama pull qwen2.5-coder:7b
```

## Installation

Clone the repository and build it:

```bash
git clone https://github.com/beri336/Swit
cd swit
swift build
```

### Release build and install to PATH (optional)

```bash
swift build -c release
cp .build/release/swit /usr/local/bin/swit

# or if you don't want to install it on your system
# you have to add `swift run` before your command,
# for example: `swift run swit commit`
```

You may need `sudo` for the copy. Verify the install:

```bash
swit --version
```

## Usage

```bash
swit commit [path] [options]
```

If `path` is omitted, the current directory is used.

```bash
# Current directory
swit commit

# Specific repository
swit commit /path/to/repository

# Preview the message only
swit commit . --dry-run

# Custom model and host (this run only)
swit commit <path> --model <model> --host <url-to-ollama>

# Without installing to PATH
swift run swit commit <path>
```

Example: dry run on a git repo, staging tracked files:

```bash
swift run swit commit --dry-run --staging tracked /git-project
```

## Commit Workflow

1. Run `swit commit` inside a repository or pass its path.
2. Choose a staging mode when prompted:

| Mode | Behavior | Git command |
|---|---|---|
| `staged` | Commit only changes that are already staged | none |
| `tracked` | Stage modified and deleted tracked files | `git add -u` |
| `all` | Stage everything, including untracked files | `git add -A` |

3. `swit` analyzes the status and diff, then asks the model for a message
4. The message is validated against Conventional Commits. If it fails, `swit` retries
5. Review the result:

| Key | Action |
|---|---|
| `y` | Create the commit |
| `e` | Edit the message |
| `n` | Abort without committing |

## Configuration

Options passed on the command line apply to **one run only**. Use `swit config` to save defaults.

```bash
swit config show                  # show current configuration
swit config set model             # default model
swit config set host              # default Ollama host URL
swit config set temperature       # default temperature (0.0–2.0)
swit config set context-window    # default context size
swit config set keep-alive        # how long Ollama keeps the model loaded
```

Repository-specific settings live in `.git/swit/config.json`.

| Setting | Flag | Description |
|---|---|---|
| Model | `--model` | Ollama model name (default `qwen2.5-coder:7b`) |
| Host | `--host` | Ollama API URL, e.g. `http://127.0.0.1:11434` |
| Temperature | `--temperature` | value between 0.0 and 2.0 |
| Context window | `--context-window` | context size in tokens |
| Keep-alive | `--keep-alive` | how long Ollama keeps the model in memory |
| Staging | `--staging` | `staged`, `tracked`, or `all` |

## Command Reference

| Command | Description |
|---|---|
| `swit commit [path]` | generate a commit message (defaults to the current directory) |
| `swit commit [path] --model <model>` | set the model for this run |
| `swit commit [path] --host <host>` | set the Ollama host URL for this run |
| `swit commit [path] --temperature <value>` | set the temperature (0.0–2.0) for this run |
| `swit commit [path] --context-window <n>` | set the context size for this run |
| `swit commit [path] --keep-alive <duration>` | set the model keep-alive for this run |
| `swit commit [path] --staging <mode>` | choose `staged`, `tracked` or `all` |
| `swit commit [path] --dry-run` | show the message only |
| `swit commit --version` | show the version |
| `swit commit --help` / `-h` | help for `commit` |
| `swit config --help` | help for `config` |
| `swit config show` | show the current configuration |
| `swit config set [key]` | edit configuration values |

## Safety

- `swit` never commits without explicit confirmation
- `--dry-run` runs neither `git add` nor `git commit`
- Untracked binary files are excluded from the prompt
- Large file contents and diffs are truncated before being sent to Ollama

## Testing

```bash
swift test
```

## Help

```bash
swift run swit --help
swift run swit commit --help
swift run swit config --help
swift run swit --version
```

## Author

<div align="center">

[![GitHub](https://img.shields.io/badge/GitHub-beri336-24292e?style=for-the-badge&logo=github)](https://github.com/beri336) [![Bitbucket](https://img.shields.io/badge/Bitbucket-berkants-0052cc?style=for-the-badge&logo=bitbucket)](https://bitbucket.org/berkants/workspace/projects/DEV)

</div>

## License

Copyright © 2026 beri336. All rights reserved.

This repository is publicly available for personal use and personal
modification only. Copying, redistribution, publishing derivative
repositories and commercial use of this project are not permitted
without prior written permission. Attribution to the original author
and repository must be preserved in all copies and modified versions,
including private ones.

See [License](LICENSE) for the full terms.

## Changelog

### 1.0.0 (MVP)

- AI-generated commit messages via `swit commit [path]`
- git status and diff analysis
- staging modes: `staged`, `tracked`, `all`
- configurable model, host, temperature, context window and keep-alive
- repository-specific configuration in `.git/swit/config.json`
- conventional Commit validation with retry
- interactive confirmation, editing or cancellation
- safe `--dry-run`
- protection against unintended commits
- error handling and exit codes

<div align="center">

[⬆ Back to Top](#swift-git-helper-swit)

</div