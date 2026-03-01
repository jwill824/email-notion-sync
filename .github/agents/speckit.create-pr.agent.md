---
description: Create a pull request for a feature branch using the repository's MCP GitHub proxy.
tools: [github/pull_request_review_write]
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. Validate required inputs: `repoOwner`, `repoName`, `headBranch`, `baseBranch`, `title`.
2. Build a PR body from provided `body` or derive from `specs/<feature>/spec.md` and `specs/<feature>/tasks.md` when available.
3. Call the MCP GitHub tool (`mcp_io_github_git_create_pull_request`) to create the pull request.
4. On success: update `specs/<feature>/tasks.md` to insert the PR URL under a "Pull Request" section and mark PR-related tasks (e.g., `T028`) as completed.
5. Return the PR metadata (number, url, html_url) as the agent result.

## Inputs

- `repoOwner` (string, required) — repository owner/org
- `repoName` (string, required) — repository name
- `headBranch` (string, required) — feature branch
- `baseBranch` (string, required) — target branch (e.g., `main`)
- `title` (string, required) — PR title
- `body` (string, optional) — PR description
- `featurePath` (string, optional) — path to specs directory (e.g., `specs/001-upgrade-dotnet10`) for task updates

## Behavior

- The agent MUST use the MCP tool listed in `tools` for PR creation; do not fallback to local CLIs.
- If the MCP call fails with an access error, surface a clear error explaining required MCP permissions.
- If `featurePath` is provided and `specs/.../tasks.md` exists, the agent will open that file, insert a Pull Request entry with URL, and mark related checklist items as completed.

## Security & Access

- The speckit runtime is expected to provide the MCP tool with appropriate credentials. Do not embed secrets or tokens in the repo.

## Outputs

- On success: return JSON with `number`, `url`, `html_url`, and the path of any updated task file.
- On failure: return an error object with `status` and `message` describing the cause.

## Example Invocation

Provide arguments (example):

```json
{
	"repoOwner": "jwill824",
	"repoName": "email-notion-sync",
	"headBranch": "001-upgrade-dotnet10",
	"baseBranch": "main",
	"title": "chore: upgrade projects to .NET 10 (001-upgrade-dotnet10)",
	"body": "Upgrades projects to net10.0 and updates CI workflows.",
	"featurePath": "specs/001-upgrade-dotnet10"
}
```

Notes:

- This agent is designed to run inside the speckit runtime with the MCP tool available as declared in `tools`.
```
