# Yegor256-Style Guidelines Applied

The app follows object-oriented constraints inspired by yegor256 principles:

- Small classes with single responsibility.
- Immutable domain objects (`domain/`) and explicit data flow.
- No static mutable global state for app data.
- Infrastructure side effects isolated in repositories/clients.
- UI does not call HTTP/DB directly; it depends on `application` providers.
- Error translation is centralized (`AppException`) for predictable UX messages.

These constraints are enforced via structure + lint configuration in `analysis_options.yaml`.
