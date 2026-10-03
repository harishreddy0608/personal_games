// Service worker for the Retro Arcade PWA.
// Caches the app shell + both games so everything works offline after the
// first visit. Bump CACHE_VERSION whenever a cached file changes to force an
// update on clients.
const CACHE_VERSION = "arcade-v3";

const ASSETS = [
  "index.html",
  "snake.html",
  "2048.html",
  "snakes-and-ladders.html",
  "blackjack.html",
  "manifest.webmanifest",
  "icon-192.png",
  "icon-512.png",
  "icon-maskable.png",
];

// Pre-cache the shell on install.
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_VERSION).then((cache) => cache.addAll(ASSETS))
  );
  self.skipWaiting();
});

// Clean up old caches on activate.
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_VERSION).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// Cache-first for same-origin GET requests, falling back to the network.
// A successful network response is cached for next time.
self.addEventListener("fetch", (event) => {
  const req = event.request;
  if (req.method !== "GET" || new URL(req.url).origin !== self.location.origin) {
    return; // let non-GET / cross-origin requests go straight to the network
  }
  event.respondWith(
    caches.match(req).then((cached) => {
      if (cached) return cached;
      return fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE_VERSION).then((cache) => cache.put(req, copy));
          return res;
        })
        .catch(() => {
          // Offline and not cached: for navigations, fall back to the home page.
          if (req.mode === "navigate") return caches.match("index.html");
        });
    })
  );
});
