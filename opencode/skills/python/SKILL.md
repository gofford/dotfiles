---
name: python
description: Production Python coding standards with strong typing, maintainable APIs, and robust error handling. Use when user asks to "review Python code", "improve type hints", "refactor for readability", "fix exception handling", or mentions "Python best practices", "typing", "pathlib", "module design", or "API design".
metadata:
  source: https://github.com/dagster-io/skills
  adapted_for: opencode
---

# Dignified Python

Use this skill for Python quality and maintainability guidance. This is general Python guidance and is not Dagster-specific.

## Use This Skill When

- Improving readability, type safety, or module design.
- Reviewing exception handling and choosing safe, explicit patterns.
- Updating code toward modern Python features and conventions.
- Standardizing CLI code and filesystem handling patterns.

## Baseline Standards

- Prefer explicit types and clear function contracts.
- Keep interfaces small and composable.
- Use `pathlib` for path operations.
- Raise specific exceptions and preserve context.
- Keep module-level side effects minimal.

## Version Awareness

Determine minimum Python version from project config before using version-specific syntax:

1. `pyproject.toml` `requires-python`
2. `setup.py` or `setup.cfg` `python_requires`
3. `.python-version`
4. Fallback to Python 3.12 when unspecified

## Reference Guides

This skill includes detailed reference guides. Read the relevant guide when needed:

| Guide | Use When |
|-------|----------|
| [references/README.md](references/README.md) | Overview of all Python standards and navigation tips |
| [references/module-design.md](references/module-design.md) | Organizing modules, packages, and imports |
| [references/checklists.md](references/checklists.md) | Quick review checklists for code quality |
| [references/advanced/exception-handling.md](references/advanced/exception-handling.md) | LBYL patterns, error boundaries, exception chaining, custom exceptions |
| [references/advanced/interfaces.md](references/advanced/interfaces.md) | ABC patterns, Protocol types, gateway layers, type narrowing |
| [references/advanced/typing-advanced.md](references/advanced/typing-advanced.md) | Generics, type narrowing, Literal types, TypedDict, dataclasses |
| [references/advanced/api-design.md](references/advanced/api-design.md) | Function signatures, parameter complexity, code organization |

## References

- Python typing docs: https://docs.python.org/3/library/typing.html
- Python pathlib docs: https://docs.python.org/3/library/pathlib.html
