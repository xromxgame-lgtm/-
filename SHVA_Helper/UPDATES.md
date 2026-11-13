# SHVA_Helper test channel

2.9.0 is a test build; Windows/GTA validation is still pending. Original module authors are retained in source metadata.

Older single-file updaters (2.6.1, 2.7): click Update to install 2.8.9-bootstrap-test, fully restart the game, then click Update in the automatically opened settings to install the complete 2.9 bundle; restart again. No manual Lua copying required.

Bundle-aware 2.8/2.9 clients use bundleVersion and files directly. Legacy version/url/sha256 describe only the independent bootstrap. All bundle files are SHA-256 checked before replacement; personal configuration files are excluded.

Clients without a configured updater need the full installer once.
