# Contributing to llvm-toolchain

We want to make contributing to this project as easy and transparent as
possible.

## AI Usage Policy

AI-generated code is allowed. What is not allowed is submitting code you do not
understand. You are 100% responsible for every line, however it was produced,
and must explicitly disclose the manner in which AI was employed.

It is strictly prohibited to use AI to write your posts for you (bug reports,
feature requests, pull request descriptions, GitHub discussions, responding to
humans, ...).

## Pull Requests

- Search for existing pull requests first before creating one.
- Open an issue first for any change that adds a component or changes a pinned
  source version.
- Keep each pull request to one change.
- Source repositories and refs are pinned in `config.sh`; change a pin there,
  not in a step script.
- Shared logic belongs in `lib/common.sh`; step scripts contain only
  step-specific configuration.
- Comments describe code that is necessarily complex. They are not an excuse
  to write poorly written code.

## Issues

We use GitHub issues to track public bugs. Please ensure your description is
clear and has sufficient instructions to be able to reproduce the issue.

## License

By contributing to llvm-toolchain, you agree that your contributions will be
licensed under the LICENSE file in the root directory of this source tree.
