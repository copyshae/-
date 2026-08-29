/* Google 新聞虛擬主播｜離線快取 */
const CACHE = "news-anchor-v12";
const ASSETS = [
  "./",
  "./index.html",
  "./share.html",
  "./tts-voices.js",
  "./news-cache.json",
  "./manifest.json",
  "./icon-180.png",
  "./icon-192.png",
  "./icon-512.png",
  "./portraits/anchor-yating.jpg",
  "./portraits/anchor-zihao.jpg",
  "./portraits/anchor-xiaoguang.jpg",
  "./portraits/anchor-ajie.jpg",
  "./portraits/anchor-xiaoxin.jpg",
  "./portraits/anchor-nova.jpg"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(ASSETS)).then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (event) => {
  const req = event.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;
  event.respondWith(
    caches.match(req).then((cached) => {
      const live = fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE).then((cache) => cache.put(req, copy));
          return res;
        })
        .catch(() => cached);
      return cached || live;
    })
  );
});
