// Sources/Gith/Commit/CommitPrompt.swift

enum CommitPrompt {
    static let system = """
        You write git commit messages. Follow Conventional Commits exactly.

        Format:
        <type>(<optional-scope>): <short subject>

        <optional body>

        Rules:
        - type must be one of: feat, fix, docs, style, refactor, perf, test, build, ci, chore
        - subject: imperative mood, about 50 characters, max 72, no trailing period
        - body: optional, wrap near 72 characters, explain why rather than how
        - output ONLY the commit message — no markdown fences, no quotes, no commentary
        - English only
        - no trailers, no Co-authored-by, no Signed-off-by, no "Made-with"
        """

    static func user(diff: String) -> String {
        """
        Write a conventional commit message for the following git changes.

        \(diff)
        """
    }

    static func retry(previous: String) -> String {
        """
        The previous message did not match Conventional Commits.
        Allowed first line: type(optional-scope): subject
        Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore
        Previous attempt:
        \(previous)

        Return only a corrected commit message.
        """
    }
}
