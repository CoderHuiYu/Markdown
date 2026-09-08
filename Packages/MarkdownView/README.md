# MarkdownView (iOS 15 compatibility package)

This package vendors MarkdownView 2.1.0 from commit
`e076836c247dc18a84a368eb36fb513017e7a519`.

The only compatibility change is the Swift Package platform declaration:

- Upstream: iOS 16
- This package: iOS 15

Keep the package pinned to the recorded upstream commit when merging updates,
and re-run the iOS 15 availability build before adopting a newer version.
