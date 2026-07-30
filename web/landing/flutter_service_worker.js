// Kill switch for the service worker the app registered when it was served
// from the site root.
//
// Until 2026-07-30 the Flutter build lived at /, so every visitor registered a
// service worker with scope / that caches the app shell and answers the root
// navigation from that cache. The app has moved to /app/ and the root is now a
// static landing page, but that old worker keeps serving its cached shell —
// which no longer has its assets at those paths, so returning visitors got a
// black screen. A reload does not fix it; a service worker outlives one.
//
// The file name must stay exactly this: the browser only ever re-fetches the
// script it originally registered. Deleting it instead of replacing it is not
// enough — a 404 unregisters the worker in Chrome but not reliably elsewhere,
// and only after the stale page has already been served once.
//
// There is deliberately no fetch handler: while this worker is alive, every
// request goes straight to the network.
//
// Safe to delete once nobody has the old worker left — which is unknowable, so
// in practice it stays.

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    await self.clients.claim();
    const keys = await caches.keys();
    await Promise.all(keys.map((k) => caches.delete(k)));
    await self.registration.unregister();
    // Reload anything currently open so it picks up the real page rather than
    // sitting on whatever the dead worker last handed it.
    const windows = await self.clients.matchAll({ type: 'window' });
    for (const client of windows) {
      client.navigate(client.url);
    }
  })());
});
