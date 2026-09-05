/* 家電家具購物帳｜Safari 友善離線快取 */
var CACHE = "home-shop-v5";
var ASSETS = [
  "./index.html",
  "./app.js?v=11",
  "./app.js",
  "./manifest.json",
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
    /\/home-shop\/?$/i.test(url.pathname) ||
    url.pathname.endsWith("/");

  if (isDoc || /app\.js$/i.test(url.pathname) || /sw\.js$/i.test(url.pathname)) {
    event.respondWith(
      fetch(req)
        .then(function (res) {
          if (canCache(res) && !/sw\.js$/i.test(url.pathname)) {
            var copy = res.clone();
            caches.open(CACHE).then(function (cache) {
              cache.put(req, copy).catch(function () {});
            });
          }
          return res;
        })
        .catch(function () {
          return caches.match(req).then(function (cached) {
            return cached || caches.match("./index.html");
          });
        })
    );
    return;
  }

  event.respondWith(
    caches.match(req).then(function (cached) {
      var live = fetch(req)
        .then(function (res) {
          if (canCache(res)) {
            var copy = res.clone();
            caches.open(CACHE).then(function (cache) {
              cache.put(req, copy).catch(function () {});
            });
          }
          return res;
        })
        .catch(function () {
          return cached;
        });
      return cached || live;
    })
  );
});
