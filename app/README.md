# Sequence

Flutter client for Sequence, a cycle tracker. Everything runs on the device:
there is no server, no account, and nothing is uploaded. Logs live in local
storage and the cycle model is computed on device.

The Dart package is still named `period_app` and the local storage keys still
use the `period.` prefix — renaming either would orphan existing users' data.

## Running

```
flutter run     # debug build
flutter test    # widget + store tests
```

## Tracker catalog

`assets/catalog/` is generated from the Python registry by
`scripts/export_catalog.py`. Regenerate it after changing the registry rather
than editing the JSON by hand.
