/* Google 新聞虛擬主播｜離線快取 */
const CACHE = "news-anchor-v21";
const ASSETS = [
  "./",
  "./index.html",
  "./share.html",
  "./tts-voices.js",
  "./tts-azure.js",
  "./news-cache.json",
  "./manifest.json",
  "./icon-180.png",
  "./icon-192.png",
  "./icon-512.png",
  "./portraits/anchor-yating.jpg",
  "./portraits/anchor-yating-idle.webm",
  "./portraits/anchor-yating-talk.webm",
  "./portraits/anchor-zihao.jpg",
  "./portraits/anchor-zihao-idle.webm",
  "./portraits/anchor-zihao-talk.webm",
  "./portraits/anchor-xiaoguang.jpg",
  "./portraits/anchor-xiaoguang-idle.webm",
  "./portraits/anchor-xiaoguang-talk.webm",
  "./portraits/anchor-ajie.jpg",
  "./portraits/anchor-ajie-idle.webm",
  "./portraits/anchor-ajie-talk.webm",
  "./portraits/anchor-xiaoxin.jpg",
  "./portraits/anchor-xiaoxin-idle.webm",
  "./portraits/anchor-xiaoxin-talk.webm",
  "./portraits/anchor-nova.jpg",
  "./portraits/anchor-nova-idle.webm",
  "./portraits/anchor-nova-talk.webm"
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
