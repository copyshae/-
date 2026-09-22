/* 基金評估台｜network-first 文件與腳本 */
var CACHE = "fund-eval-v5";
var ASSETS = [
  "./index.html",
  "./app.js?v=5",
  "./app.js",
  "./manifest.json",
  "./watchlist.json",
  "./icon-180.png",
  "./icon-192.png",
  "./icon-512.png",
  "./share.html"
];

function canCache(res) {
  return res && res.ok && res.type === "basic";
}

self.addEventListener("install", function (event) {
  event.waitUntil(
    caches.open(CACHE).then(function (cache) {
      return Promise.all(
        ASSETS.map(function (url) {
          return cache.add(url).catch(function () {});
        })
      );
    }).then(function () {
      return self.skipWaiting();
    })
  );
});

self.addEventListener("activate", function (event) {
  event.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(
        keys.filter(function (k) { return k !== CACHE; }).map(function (k) {
          return caches.delete(k);
        })
      );
    }).then(function () {
      return self.clients.claim();
    })
  );
});

self.addEventListener("fetch", function (event) {
  var req = event.request;
  if (req.method !== "GET") return;

  var url = new URL(req.url);
  if (url.origin !== self.location.origin) return;

  var isDoc =
    req.mode === "navigate" ||
    /index\.html$/i.test(url.pathname) ||
    /\/fund-eval\/?$/i.test(url.pathname) ||
    url.pathname.endsWith("/");

  if (isDoc || /app\.js$/i.test(url.pathname) || /sw\.js$/i.test(url.pathname)) {
    event.respondWith(
      fetch(req)
        .then(function (res) {
          if (canCache(res)) {
            var copy = res.clone();
            caches.open(CACHE).then(function (cache) {
              cache.put(req, copy);
            });
          }
          return res;
        })
        .catch(function () {
          return caches.match(req).then(function (hit) {
            return hit || caches.match("./index.html");
          });
        })
    );
    return;
  }

  event.respondWith(
    caches.match(req).then(function (hit) {
      if (hit) return hit;
      return fetch(req).then(function (res) {
        if (canCache(res)) {
          var copy = res.clone();
          caches.open(CACHE).then(function (cache) {
            cache.put(req, copy);
          });
        }
        return res;
      });
    })
  );
});
