// Xscout Service Worker v1.0
const CACHE_NAME = 'xscout-v1';
const TILE_CACHE = 'xscout-tiles-v1';
const ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icon-192.png',
  '/icon-512.png',
  '/favicon.png'
];

// Install: cache core assets
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      return cache.addAll(ASSETS);
    }).then(() => self.skipWaiting())
  );
});

// Activate: clean old caches
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys => {
      return Promise.all(
        keys.filter(k => k !== CACHE_NAME && k !== TILE_CACHE)
          .map(k => caches.delete(k))
      );
    }).then(() => self.clients.claim())
  );
});

// Helper: is this a map tile URL?
function isTileRequest(url) {
  const u = new URL(url);
  // OSM/Leaftlet tile patterns
  return /\.tile\.(openstreetmap|opentopomap|arcgis)\./.test(u.hostname) ||
         /tile/i.test(u.pathname) ||
         /tiles/i.test(u.pathname) ||
         /\d+\/\d+\/\d+\.png/.test(u.pathname);
}

// Helper: is this an API request for offline data
function isOfflineDataRequest(url) {
  const u = new URL(url);
  return u.pathname.includes('/offline-tiles') || 
         u.searchParams.has('offline');
}

// Fetch: serve cached or network-first with fallback
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  
  // Map tiles — cache-first with background refresh
  if (isTileRequest(event.request.url)) {
    event.respondWith(
      caches.open(TILE_CACHE).then(cache => {
        return cache.match(event.request).then(cached => {
          const fetchPromise = fetch(event.request).then(network => {
            if (network.ok) cache.put(event.request, network.clone());
            return network;
          }).catch(() => cached);
          return cached || fetchPromise;
        });
      })
    );
    return;
  }
  
  // App shell — cache-first (fast install load)
  if (event.request.mode === 'navigate' || ASSETS.includes(url.pathname)) {
    event.respondWith(
      caches.match(event.request).then(cached => {
        return cached || fetch(event.request).then(network => {
          const copy = network.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, copy));
          return network;
        }).catch(() => {
          // Offline fallback page
          if (event.request.mode === 'navigate') {
            return caches.match('/');
          }
          return new Response('Offline', { status: 503 });
        });
      })
    );
    return;
  }
  
  // Everything else — network-first
  event.respondWith(
    fetch(event.request).then(network => {
      const copy = network.clone();
      if (copy.ok && copy.type === 'basic') {
        caches.open(CACHE_NAME).then(cache => cache.put(event.request, copy));
      }
      return network;
    }).catch(() => caches.match(event.request))
  );
});

// Listen for offline map save messages
self.addEventListener('message', event => {
  if (event.data && event.data.type === 'SAVE_OFFLINE_TILES') {
    const { urls, areaId } = event.data;
    const cache = caches.open(TILE_CACHE);
    // Queue tiles for background caching
    event.waitUntil(
      cache.then(c => {
        return Promise.allSettled(
          urls.map(url => 
            fetch(url).then(r => {
              if (r.ok) c.put(url, r);
            }).catch(() => {})
          )
        );
      }).then(() => {
        // Notify all clients
        self.clients.matchAll().then(clients => {
          clients.forEach(client => {
            client.postMessage({ type: 'TILES_CACHED', areaId });
          });
        });
      })
    );
  }
});
