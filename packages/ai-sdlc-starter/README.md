# ai-sdlc-starter

Scaffold a project that runs Anthropic's [AI-Native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook)
— Plan → Design → Build → Test → Deploy → Maintain — with the Claude Code agents,
skills and guardrail hooks that drive the loop, and a stack that builds, tests
and lints itself from the first commit.

```bash
npx ai-sdlc-starter@latest my-app -w node
```

Already have a project? `npx ai-sdlc-starter@latest --adopt` adds the kit without
overwriting anything (`--dry-run` previews it).

Runtimes: `-w node` · `python` · `go` · `java`, pinned with `@` (`-w python@3.11`),
comma separated. `-h` lists every option.

This package is a thin wrapper: it runs `init.sh` on macOS and Linux, `init.ps1`
on Windows, and both write the same files byte for byte — checked in CI on all
three operating systems.

**Guide:** <https://niseel.github.io/ai-sdlc-starter/> ·
**Source:** <https://github.com/Niseel/ai-sdlc-starter> · MIT
