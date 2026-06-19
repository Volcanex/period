import 'package:flutter/widgets.dart';

import '../api/tracker_catalog.dart';

/// Inherited holder for app-wide API state. Screens read it via
/// [ApiScope.of] and rebuild when the catalog refreshes.
///
/// Tiny on purpose — this is the single source of truth for backend-derived
/// data on the client. Add new repositories (privacy manifest, contract
/// version, etc.) here as they come online.
class ApiScope extends InheritedNotifier<TrackerCatalogRepository> {
  const ApiScope({
    super.key,
    required TrackerCatalogRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static TrackerCatalogRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ApiScope>();
    assert(scope != null, 'ApiScope.of() called without an ApiScope ancestor');
    return scope!.notifier!;
  }

  /// Read without subscribing. Useful for one-shot calls (e.g. an action
  /// handler kicking off a refresh) where you don't want to rebuild on
  /// every catalog change.
  static TrackerCatalogRepository read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ApiScope>();
    assert(
      scope != null,
      'ApiScope.read() called without an ApiScope ancestor',
    );
    return scope!.notifier!;
  }
}
