# Swift Git Helper [swit]

CLI helper for Git v1: Suggests a conventional commit message using the local Ollama LLM and commits only after confirmation (optional editing).

## Requirements

- Swift 6.0+
```bash
swift --version
```

- `git` is installed and in the PATH
```bash
git --version
```

- Ollama is installed and running, and `qwen2.5-coder:7b` is set as the default
```bash
ollama serve
ollama pull qwen2.5-coder:7b
```

## General Information

### Build

```bash
// in the main path under `swit/`
swift build
```

### Release + Add to PATH

```bash
swift build -c release
cp .build/release/swit /usr/locale/bin/swit
```

## Version 1.0.0
- have AI generate a Git commit message

### Usage
```bash
swit commit <path>
swit commit . --dry-run
swit commit <path> --model <modelname> --host <url-to-ollama>

// or without adding it to the PATH
swift run swit commit <path>
```

- Example:
```bash
swift run swit commit --dry-run --staging tracked /vault-store
```

- Info:
  - if `<path>` is omitted, the current directory is used
  - `--dry-run` displays only the message, without running `git add` or `git commit`

### Commit workflow
- run from a Git repository:
```bash
swift run swit commit
```

- or provide a repository path:
```bash
swift run swit commit /path/to/repository
```
- select one staging mode when prompted:
  - `staged`: commit only already staged changes
  - `tracked`: stage modified and deleted tracked files with `git add -u`
  - `all`: stage all changes, including untracked files, with `git add -A`

- review the generated message:
- `y`: create the commit
- `e`: edit the message
- `n`: abort

## Options

```bash
swift run swit commit --model qwen2.5-coder:7b
swift run swit commit --host http://127.0.0.1:11434
```

## Testing

```bash
swift test
```

## Help

```bash
swift run swit --help
swift run swit commit --help
```

## Safety

- `swit` does not create a commit without explicit confirmation.
- `--dry-run` does not run `git add` or `git commit`.
- untracked binary files are excluded from the prompt.
- large file contents and diffs are truncated before being sent to Ollama.
