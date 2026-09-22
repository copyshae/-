const CACHE = "cursor-learn-v12";
const ASSETS = [
  "./",
  "./index.html",
  "./share.html",
  "./manifest.json",
  "./catalog.json",
  "./captions/bundle.json",
  "./icon-180.png",
  "./icon-192.png",
  "./icon-512.png"
];
self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(ASSETS)).then(() => self.skipWaiting()));
});
self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k.startsWith("cursor-learn-") && k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim())
  );
});
self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;
  const path = new URL(req.url).pathname;
  if (/catalog\.json$/i.test(path) || /captions\/bundle\.json$/i.test(path) || /index\.html$/i.test(path) || /cursor-learn\/?$/i.test(path)) {
    e.respondWith(fetch(req).then((res) => { const c = res.clone(); caches.open(CACHE).then((x) => x.put(req, c)); return res; }).catch(() => caches.match(req)));
    return;
  }
  e.respondWith(caches.match(req).then((cached) => cached || fetch(req)));
});
