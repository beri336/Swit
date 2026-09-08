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

- Ollama is installed, and `qwen2.5-coder:7b` is set as the default

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

- Info:
  - if `<path>` is omitted, the current directory is used
  - `--dry-run` displays only the message, without running `git add` or `git commit`

- Flow:
  - View status -> Select staging (staged/tracked/all only) -> Ollama suggestion
    => [y] commit
    => [e] edit
    => [n] abort

```bash
// Help
swit --help
swit commit --help
```
