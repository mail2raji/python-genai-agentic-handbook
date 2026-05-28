# Contributing

Thanks for your interest! Contributions of any size are welcome — fixing a typo, improving a lesson,
adding an exercise, or suggesting a new chapter.

## Quick start

1. Fork the repo.
2. Create a branch: `git checkout -b fix/short-description`.
3. Make your change.
4. Run any affected lessons in `MOCK_MODE=1` to confirm they still work.
5. Open a Pull Request.

## Style guide

- Each Python lesson opens with a docstring: concept → analogy → run hint.
- Each lesson ends with a "Takeaway box".
- Code targets Python 3.10+.
- No external API call is mandatory — every lesson must run in `MOCK_MODE=1`.
- Keep examples short. If a file grows past ~250 lines, split it.

## Adding a new lab

1. Put the file in the matching `PhaseN_*/` folder.
2. Add a row to [`LAB_MENU.md`](LAB_MENU.md).
3. Add the link to [`HANDBOOK.md`](index.md) under the right Part.
4. Add an entry to [`SUMMARY.md`](index.md) if it's a markdown chapter.

## Issues

Found a bug or have a question? Open an Issue — describe what you ran and what you expected.

