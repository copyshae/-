/* 家電家具購物帳 */
(function () {
  "use strict";

  var STORE = "home-shop-v1";
  var KEY_GEMINI = "home-shop-gemini-key";
  var LABEL = { appliance: "家電", furniture: "家具", other: "其他" };
  var FROM = {
    "家電": "appliance",
    "家具": "furniture",
    "其他": "other",
    appliance: "appliance",
    furniture: "furniture",
    other: "other"
  };
  var MODELS = ["gemini-2.5-flash-lite", "gemini-2.5-flash", "gemini-flash-latest"];

  var items = [];
  var filterCat = "all";
  var pendingImport = null;
  var photoUrl = "";
  var scanFile = null;
  var scanUrl = "";
  var drafts = [];

  function $(id) { return document.getElementById(id); }

  function today() {
    var d = new Date();
    return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
  }

  function uid() {
    return "hs_" + Date.now().toString(36) + "_" + Math.random().toString(36).slice(2, 8);
  }

  function money(n) {
    return "$" + Math.round(Number(n) || 0).toLocaleString("zh-TW");
  }

  function esc(s) {
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function setStatus(el, msg, kind) {
    if (!el) return;
    el.textContent = msg || "";
    el.className = "status" + (kind ? " " + kind : "");
  }

  function flash(msg, kind) {
    var el = $("appFlash");
    if (!el) return;
    el.textContent = msg || "";
    el.className = "flash" + (msg ? " on" : "") + (kind ? " " + kind : "");
    if (msg) {
      try { el.scrollIntoView({ behavior: "smooth", block: "nearest" }); } catch (e) {
        try { el.scrollIntoView(true); } catch (e2) {}
      }
    }
  }

  function tellUser(msg, kind, alsoEl, useAlert) {
    flash(msg, kind);
    if (alsoEl) setStatus(alsoEl, msg, kind);
    if (alsoEl && msg) {
      try { alsoEl.scrollIntoView({ behavior: "smooth", block: "nearest" }); } catch (e) {}
    }
    // iPhone 上錯誤若只寫在長清單下方會像「按了沒反應」；關鍵結果再用系統對話框確保看得到
    if (useAlert && msg) {
      try { window.alert(msg); } catch (eAlert) {}
    }
  }

  function normalizeCat(c) {
    return FROM[c] || FROM[String(c || "").trim()] || "other";
  }

  function lineTotal(it) {
    var q = Number(it.qty);
    if (!q || q < 1) q = 1;
    return (Number(it.amount) || 0) * q;
  }

  var PHOTO_MAX = 90000; // data URL 上限（縮小，避免多筆登錄撐爆本機空間）

  function trimPhoto(p) {
    if (typeof p !== "string" || !p) return "";
    if (p.length > PHOTO_MAX) return "";
    if (p.indexOf("data:image/") !== 0 && p.indexOf("blob:") !== 0) return "";
    return p;
  }

  function sanitizeItems(list) {
    if (!Array.isArray(list)) return [];
    return list.slice(0, 3000).map(function (raw) {
      return {
        id: String((raw && raw.id) || uid()).slice(0, 64),
        date: String((raw && raw.date) || today()).slice(0, 32),
        category: normalizeCat(raw && raw.category),
        name: String((raw && raw.name) || "（未命名）").slice(0, 200),
        model: String((raw && raw.model) || "").slice(0, 80),
        amount: Math.max(0, Number(raw && raw.amount) || 0),
        qty: Number(raw && raw.qty) > 0 ? Number(raw.qty) : 1,
        store: String((raw && raw.store) || "").slice(0, 120),
        receiptNo: String((raw && raw.receiptNo) || "").slice(0, 80),
        payment: String((raw && raw.payment) || "").slice(0, 80),
        note: String((raw && raw.note) || "").slice(0, 500),
        photo: trimPhoto(raw && raw.photo),
        createdAt: String((raw && raw.createdAt) || new Date().toISOString()).slice(0, 40),
        updatedAt: String((raw && raw.updatedAt) || new Date().toISOString()).slice(0, 40)
      };
    }).filter(function (it) {
      return it.name && Number.isFinite(it.amount);
    });
  }

  function load() {
    try {
      var raw = localStorage.getItem(STORE);
      if (raw && raw.length > 2500000) {
        // 過大狀態會讓 Safari 反覆當掉／存失敗：先去掉照片再救回
        try {
          var huge = JSON.parse(raw);
          items = sanitizeItems(huge && huge.items).map(function (it) {
            it.photo = "";
            return it;
          });
          persist();
        } catch (eHuge) {
          localStorage.removeItem(STORE);
          items = [];
        }
      } else {
        var data = raw ? JSON.parse(raw) : null;
        items = sanitizeItems(data && data.items);
        // 若本機已接近額度，主動清掉照片，避免「辨識成功卻登錄失敗」
        try {
          if (raw && raw.length > 1200000) {
            var hadPhoto = items.some(function (it) { return !!(it.photo && it.photo.length > 100); });
            if (hadPhoto) {
              items = items.map(function (it) {
                var copy = Object.assign({}, it);
                copy.photo = "";
                return copy;
              });
              persist();
            }
          }
        } catch (eTrim) {}
      }
    } catch (e) {
      try { localStorage.removeItem(STORE); } catch (eDel) {}
      items = [];
    }
    try {
      var k = localStorage.getItem(KEY_GEMINI);
      if (k) $("geminiKey").value = String(k).slice(0, 200);
    } catch (e2) {}
  }

  function persist() {
    function build(stripPhotos, truncate) {
      return {
        version: 1,
        updatedAt: new Date().toISOString(),
        items: items.map(function (it) {
          var copy = Object.assign({}, it);
          var photo = stripPhotos ? "" : trimPhoto(copy.photo);
          if (photo && photo.indexOf("blob:") === 0) photo = "";
          copy.photo = photo;
          if (truncate) {
            copy.note = String(copy.note || "").slice(0, 120);
            copy.model = String(copy.model || "").slice(0, 40);
            copy.store = String(copy.store || "").slice(0, 60);
            copy.receiptNo = String(copy.receiptNo || "").slice(0, 40);
            copy.payment = String(copy.payment || "").slice(0, 40);
          }
          return copy;
        })
      };
    }
    var payload = build(false, false);
    try {
      localStorage.setItem(STORE, JSON.stringify(payload));
      return { ok: true, stripped: false };
    } catch (e1) {
      payload = build(true, false);
      items = payload.items;
      try {
        localStorage.setItem(STORE, JSON.stringify(payload));
        return { ok: true, stripped: true };
      } catch (e2) {
        try {
          payload = build(true, true);
          items = payload.items;
          localStorage.setItem(STORE, JSON.stringify(payload));
          return { ok: true, stripped: true, truncated: true };
        } catch (e3) {
          throw e3;
        }
      }
    }
  }

  function calcStats() {
    var s = { total: 0, count: 0, appliance: 0, furniture: 0, other: 0, aN: 0, fN: 0, oN: 0 };
    items.forEach(function (it) {
      var t = lineTotal(it);
      s.total += t;
      s.count += 1;
      var c = normalizeCat(it.category);
      if (c === "furniture") { s.furniture += t; s.fN += 1; }
      else if (c === "other") { s.other += t; s.oN += 1; }
      else { s.appliance += t; s.aN += 1; }
    });
    return s;
  }

  function renderStats() {
    var s = calcStats();
    $("totalSpend").textContent = money(s.total);
    $("totalMeta").textContent = s.count
      ? ("共 " + s.count + " 筆 · 平均每筆 " + money(s.total / s.count))
      : "尚未登錄任何項目";
    $("sumA").textContent = money(s.appliance);
    $("sumF").textContent = money(s.furniture);
    $("sumO").textContent = money(s.other);
    $("cntA").textContent = s.aN + " 筆";
    $("cntF").textContent = s.fN + " 筆";
    $("cntO").textContent = s.oN + " 筆";
  }

  function renderList() {
    var q = ($("searchQ").value || "").trim().toLowerCase();
    var list = items.filter(function (it) {
      if (filterCat !== "all" && normalizeCat(it.category) !== filterCat) return false;
      if (!q) return true;
      var blob = [it.name, it.model, it.store, it.note, it.receiptNo, it.payment, LABEL[normalizeCat(it.category)], it.date].join(" ").toLowerCase();
      return blob.indexOf(q) !== -1;
    }).slice().sort(function (a, b) {
      if (a.date === b.date) return (b.createdAt || "").localeCompare(a.createdAt || "");
      return (b.date || "").localeCompare(a.date || "");
    });

    if (!list.length) {
      $("itemList").innerHTML = '<p class="empty">沒有符合的項目。請到「登錄」拍照辨識或手動輸入。</p>';
      return;
    }

    // 清單不嵌入 data URL 縮圖，避免 iOS Safari 一次解碼大量圖片而當掉
    $("itemList").innerHTML = list.map(function (it) {
      var qty = Number(it.qty) > 1 ? (" × " + it.qty) : "";
      var hasPhoto = !!(it.photo && String(it.photo).indexOf("data:image/") === 0);
      var meta = '<span class="badge">' + LABEL[normalizeCat(it.category)] + "</span> " + esc(it.date || "") +
        (it.model ? (" · " + esc(it.model)) : "") +
        (it.store ? (" · " + esc(it.store)) : "") +
        (it.receiptNo ? (" · #" + esc(it.receiptNo)) : "") +
        (it.payment ? (" · " + esc(it.payment)) : "") +
        (Number(it.qty) > 1 ? (" · 單價 " + money(it.amount)) : "") +
        (hasPhoto ? " · 有照片" : "");
      return (
        '<article class="item" data-id="' + it.id + '">' +
          '<div class="name">' + esc(it.name || "（未命名）") + qty + "</div>" +
          '<div class="amt">' + money(lineTotal(it)) + "</div>" +
          '<div class="meta">' + meta + "</div>" +
          (it.note ? ('<div class="meta">' + esc(it.note) + "</div>") : "") +
          '<div class="acts">' +
            '<button type="button" data-act="edit">編輯修改</button>' +
            '<button type="button" class="danger" data-act="del">刪除</button>' +
          "</div>" +
        "</article>"
      );
    }).join("");
  }

  function switchTab(name) {
    document.querySelectorAll(".tabs button").forEach(function (b) {
      b.classList.toggle("on", b.getAttribute("data-tab") === name);
    });
    document.querySelectorAll(".panel").forEach(function (p) {
      p.classList.toggle("on", p.id === "panel-" + name);
    });
  }

  function switchPath(name) {
    document.querySelectorAll(".paths button").forEach(function (b) {
      b.classList.toggle("on", b.getAttribute("data-path") === name);
    });
    document.querySelectorAll(".path").forEach(function (p) {
      p.classList.toggle("on", p.id === "path-" + name);
    });
  }

  function resetForm(keepDate) {
    $("editId").value = "";
    $("formTitle").textContent = "手動輸入收據／項目";
    if (!keepDate) $("fDate").value = today();
    $("fCat").value = "appliance";
    $("fName").value = "";
    if ($("fModel")) $("fModel").value = "";
    $("fAmt").value = "";
    $("fQty").value = "1";
    $("fStore").value = "";
    $("fNo").value = "";
    if ($("fPay")) $("fPay").value = "";
    $("fNote").value = "";
    photoUrl = "";
    $("pCam").value = "";
    $("pFile").value = "";
    $("photoPreview").src = "";
    $("photoPreview").classList.remove("on");
    $("btnCancelEdit").hidden = true;
    setStatus($("formStatus"), "", "");
  }

  function fillForm(it) {
    $("editId").value = it.id || "";
    $("formTitle").textContent = it.id ? "編輯修改項目" : "手動調整辨識結果";
    $("fDate").value = it.date || today();
    $("fCat").value = normalizeCat(it.category);
    $("fName").value = it.name || "";
    if ($("fModel")) $("fModel").value = it.model || "";
    $("fAmt").value = it.amount != null ? it.amount : "";
    $("fQty").value = it.qty || 1;
    $("fStore").value = it.store || "";
    $("fNo").value = it.receiptNo || "";
    if ($("fPay")) $("fPay").value = it.payment || "";
    $("fNote").value = it.note || "";
    photoUrl = it.photo || "";
    if (photoUrl) {
      $("photoPreview").src = photoUrl;
      $("photoPreview").classList.add("on");
    } else {
      $("photoPreview").src = "";
      $("photoPreview").classList.remove("on");
    }
    $("btnCancelEdit").hidden = !it.id;
    setStatus($("formStatus"), it.id ? ("正在修改：「" + (it.name || "") + "」") : "請修改後按儲存", "warn");
  }

  function loadImageElement(file) {
    return new Promise(function (resolve, reject) {
      function fromObjectUrl() {
        var url = URL.createObjectURL(file);
        var img = new Image();
        img.onload = function () {
          URL.revokeObjectURL(url);
          resolve(img);
        };
        img.onerror = function () {
          URL.revokeObjectURL(url);
          reject(new Error("圖片無法開啟（若為 HEIC，請先用「檔案」轉成 JPG，或改用相簿選取）"));
        };
        img.src = url;
      }
      if (typeof createImageBitmap === "function") {
        createImageBitmap(file).then(function (bmp) {
          resolve(bmp);
        }).catch(function () {
          fromObjectUrl();
        });
      } else {
        fromObjectUrl();
      }
    });
  }

  function compressImage(file, maxSide, quality) {
    return loadImageElement(file).then(function (img) {
      var w = img.width || img.videoWidth || 1;
      var h = img.height || img.videoHeight || 1;
      var scale = Math.min(1, maxSide / Math.max(w, h));
      var canvas = document.createElement("canvas");
      canvas.width = Math.max(1, Math.round(w * scale));
      canvas.height = Math.max(1, Math.round(h * scale));
      canvas.getContext("2d").drawImage(img, 0, 0, canvas.width, canvas.height);
      if (typeof img.close === "function") {
        try { img.close(); } catch (e) {}
      }
      return canvas.toDataURL("image/jpeg", quality);
    });
  }

  function fileToBase64(file) {
    return new Promise(function (resolve, reject) {
      var reader = new FileReader();
      reader.onload = function () {
        var res = String(reader.result || "");
        var idx = res.indexOf(",");
        resolve({
          dataUrl: res,
          b64: idx >= 0 ? res.slice(idx + 1) : res,
          mime: file.type || "application/octet-stream"
        });
      };
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  }

  function saveItem() {
    var name = ($("fName").value || "").trim();
    var amtRaw = ($("fAmt").value || "").trim();
    var amount = Number(amtRaw);
    var qty = Number($("fQty").value);
    var date = $("fDate").value;
    if (!name) { setStatus($("formStatus"), "請填品名／品項（至少要有品項與金額）", "err"); return; }
    if (amtRaw === "" || isNaN(amount) || amount < 0) {
      setStatus($("formStatus"), "請填金額（至少要有品項與金額；贈品可填 0）", "err");
      return;
    }
    if (!date) date = today();
    if (!qty || qty < 1) qty = 1;

    var id = $("editId").value;
    var now = new Date().toISOString();
    var rec = {
      id: id || uid(),
      date: date,
      category: $("fCat").value || "appliance",
      name: name,
      model: ($("fModel") && $("fModel").value || "").trim(),
      amount: amount,
      qty: qty,
      store: ($("fStore").value || "").trim(),
      receiptNo: ($("fNo").value || "").trim(),
      payment: ($("fPay") && $("fPay").value || "").trim(),
      note: ($("fNote").value || "").trim(),
      photo: trimPhoto(photoUrl),
      updatedAt: now
    };

    if (id) {
      var idx = items.findIndex(function (x) { return x.id === id; });
      if (idx >= 0) {
        rec.createdAt = items[idx].createdAt || now;
        items[idx] = rec;
      } else {
        rec.createdAt = now;
        items.push(rec);
      }
    } else {
      rec.createdAt = now;
      items.push(rec);
    }

    try {
      persist();
    } catch (e) {
      setStatus($("formStatus"), "儲存失敗（空間可能不足）", "err");
      return;
    }

    renderStats();
    renderList();
    setStatus($("formStatus"), "已儲存：「" + name + "」· 總花費 " + money(calcStats().total), "");
    resetForm(true);
    switchTab("home");
  }

  function attachPhoto(file) {
    if (!file) return;
    setStatus($("formStatus"), "壓縮照片中…", "warn");
    compressImage(file, 720, 0.62).then(function (url) {
      photoUrl = trimPhoto(url);
      if (!photoUrl) {
        setStatus($("formStatus"), "照片太大，已略過附圖（費用仍可登錄）", "warn");
        return;
      }
      $("photoPreview").src = photoUrl;
      $("photoPreview").classList.add("on");
      setStatus($("formStatus"), "照片已就緒", "");
    }).catch(function () {
      setStatus($("formStatus"), "照片讀取失敗", "err");
    });
  }

  function blankDraft(partial) {
    partial = partial || {};
    return {
      _key: uid(),
      date: partial.date || today(),
      category: normalizeCat(partial.category || "other"),
      name: partial.name || "",
      model: partial.model || "",
      amount: partial.amount != null && partial.amount !== "" ? Number(partial.amount) : "",
      qty: partial.qty > 0 ? Number(partial.qty) : 1,
      store: partial.store || "",
      receiptNo: partial.receiptNo || "",
      payment: partial.payment || "",
      note: partial.note || "",
      // 多筆收據列不要各存一張大圖，否則確認登錄會撐爆本機空間
      photo: ""
    };
  }

  function renderDrafts() {
    $("draftCard").hidden = !drafts.length;
    if (!drafts.length) {
      $("draftList").innerHTML = "";
      return;
    }
    var draftSum = 0;
    drafts.forEach(function (d) {
      var a = Number(d.amount);
      var q = Number(d.qty) > 0 ? Number(d.qty) : 1;
      if (!isNaN(a) && a >= 0) draftSum += a * q;
    });
    $("draftList").innerHTML =
      '<p class="hint">本批草稿加總：<strong>' + money(draftSum) + "</strong>（登錄後會併入上方總花費）· 每筆可改可刪；品名與金額必填；贈品金額填 0；確認登錄只存品項金額，不重複存收據大圖以免失敗</p>" +
      drafts.map(function (d, i) {
        return (
          '<div class="draft-card" data-key="' + d._key + '">' +
            "<h3>第 " + (i + 1) + " 筆</h3>" +
            '<div class="row">' +
              '<div><label>日期</label><input type="date" data-f="date" value="' + esc(d.date) + '" /></div>' +
              '<div><label>分類</label><select data-f="category">' +
                '<option value="appliance"' + (d.category === "appliance" ? " selected" : "") + ">家電</option>" +
                '<option value="furniture"' + (d.category === "furniture" ? " selected" : "") + ">家具</option>" +
                '<option value="other"' + (d.category === "other" ? " selected" : "") + ">其他</option>" +
              "</select></div>" +
            "</div>" +
            '<label>品名（必填）</label><input type="text" data-f="name" value="' + esc(d.name) + '" />' +
            '<label>型號（選填）</label><input type="text" data-f="model" value="' + esc(d.model || "") + '" placeholder="沒有可留空" />' +
            '<div class="row">' +
              '<div><label>金額（必填；贈品填 0）</label><input type="number" data-f="amount" min="0" step="1" value="' + esc(d.amount) + '" /></div>' +
              '<div><label>數量</label><input type="number" data-f="qty" min="1" step="1" value="' + esc(d.qty) + '" /></div>' +
            "</div>" +
            '<label>店家（選填）</label><input type="text" data-f="store" value="' + esc(d.store) + '" />' +
            '<label>收據編號（選填）</label><input type="text" data-f="receiptNo" value="' + esc(d.receiptNo) + '" />' +
            '<label>付款方式（選填）</label><input type="text" data-f="payment" value="' + esc(d.payment || "") + '" placeholder="沒有可留空" />' +
            '<label>備註（選填）</label><textarea data-f="note">' + esc(d.note) + "</textarea>" +
            '<div class="acts">' +
              '<button type="button" data-a="manual">修改（手動表單）</button>' +
              '<button type="button" class="danger" data-a="rm">刪除此列</button>' +
            "</div>" +
          "</div>"
        );
      }).join("");
  }

  function syncDraft(card) {
    var key = card.getAttribute("data-key");
    var d = drafts.find(function (x) { return x._key === key; });
    if (!d) return null;
    card.querySelectorAll("[data-f]").forEach(function (el) {
      d[el.getAttribute("data-f")] = el.value;
    });
    d.category = normalizeCat(d.category);
    d.amount = d.amount === "" ? "" : Number(d.amount);
    d.qty = Number(d.qty) > 0 ? Number(d.qty) : 1;
    return d;
  }

  function extractJson(text) {
    var t = String(text || "").trim().replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/i, "");
    try {
      return JSON.parse(t);
    } catch (e) {
      var i = t.indexOf("{");
      var j = t.lastIndexOf("}");
      if (i >= 0 && j > i) {
        try { return JSON.parse(t.slice(i, j + 1)); } catch (e2) {}
      }
    }
    return null;
  }

  function guessCategory(name, hint) {
    if (hint) return normalizeCat(hint);
    var n = String(name || "");
    if (/床|沙發|櫃|桌|椅|架|墊|窗帘|窗簾|地毯|收納/.test(n)) return "furniture";
    if (/冰箱|洗衣機|冷氣|空調|電視|微波|烤箱|風扇|清淨|除濕|熱水|電器|家電|爐|排油煙/.test(n)) return "appliance";
    return "other";
  }

  function friendlyError(err) {
    var msg = String((err && err.message) || err || "");
    if (/high demand|temporarily|try again later|Resource exhausted|429|quota|overloaded/i.test(msg)) {
      return "辨識服務目前忙線（需求較高），請等 1～2 分鐘再按一次「辨識並帶入費用」。急用可改「手動輸入」。";
    }
    if (/API key|invalid|PERMISSION|401|403|API_KEY/i.test(msg)) {
      return "Gemini 金鑰無效或無權限，請到 Google AI Studio 重新建立金鑰後再貼上。";
    }
    if (/Failed to fetch|NetworkError|network|Load failed/i.test(msg)) {
      return "網路連線失敗，請確認有上網後再試。";
    }
    if (/無法解析辨識結果/.test(msg)) {
      return "有回應但無法讀出費用項目，請換張清楚一點的照片，或改手動輸入。";
    }
    // 英文原文太長時，給簡短中文＋原文摘要
    if (/[A-Za-z]{20,}/.test(msg) && !/[\u4e00-\u9fff]/.test(msg)) {
      return "辨識暫時失敗：" + msg.slice(0, 120) + "。請稍後再試，或改手動輸入。";
    }
    return msg || "辨識失敗";
  }

  function callGemini(file) {
    var apiKey = ($("geminiKey").value || "").trim() || localStorage.getItem(KEY_GEMINI) || "";
    if (!apiKey) return Promise.reject(new Error("請先填 Gemini 金鑰，或改用手動輸入"));

    var prepare = /^image\//i.test(file.type || "")
      ? compressImage(file, 1280, 0.7).then(function (dataUrl) {
          var idx = dataUrl.indexOf(",");
          return {
            dataUrl: dataUrl,
            b64: idx >= 0 ? dataUrl.slice(idx + 1) : dataUrl,
            mime: "image/jpeg"
          };
        })
      : fileToBase64(file);

    return prepare.then(function (packed) {
      var mime = packed.mime;
      if (!mime || mime === "application/octet-stream") {
        mime = /\.pdf$/i.test(file.name) ? "application/pdf" : "image/jpeg";
      }
      var prompt =
        "這是台灣家電／家具收據（繁體中文，可能含燦坤等）。只回 JSON，不要 markdown：" +
        '{"store":"店家或空","date":"YYYY-MM-DD或空","receiptNo":"單號或空","payment":"付款方式或空","items":[{"name":"品名","model":"型號或空","amount":單價數字,"qty":數量,"category":"appliance|furniture|other","note":"備註或空"}],"total":總額}。' +
        "品名與金額必填；沒有的欄位填空字串勿捏造。贈品／贈送 amount 必須為 0，note 可寫贈品。延保安裝也要逐筆。民國年改西元（+1911）。total 為收據總計。不要擷取姓名電話。";
      var parts = [{ text: prompt }, { inline_data: { mime_type: mime, data: packed.b64 } }];
      var lastErr = null;
      var idx = 0;
      // 忙線時先試較輕量的模型
      var models = MODELS.slice();

      function delay(ms) {
        return new Promise(function (resolve) { setTimeout(resolve, ms); });
      }

      function tryNext() {
        if (idx >= models.length) {
          return Promise.reject(new Error(friendlyError(lastErr || new Error("Gemini 無回應"))));
        }
        var model = models[idx++];
        var url = "https://generativelanguage.googleapis.com/v1beta/models/" +
          encodeURIComponent(model) + ":generateContent?key=" + encodeURIComponent(apiKey);
        return fetch(url, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            contents: [{ role: "user", parts: parts }],
            generationConfig: { temperature: 0.1, maxOutputTokens: 4096 }
          })
        }).then(function (res) {
          return res.json().then(function (data) {
            if (!res.ok) {
              var rawMsg = (data.error && data.error.message) || ("HTTP " + res.status);
              lastErr = new Error(rawMsg);
              var busy = /high demand|try again later|Resource exhausted|429|overloaded/i.test(rawMsg);
              if (busy && idx < models.length) {
                return delay(800).then(tryNext);
              }
              return tryNext();
            }
            var text = (((data.candidates || [])[0] || {}).content || {}).parts
              ? data.candidates[0].content.parts.map(function (p) { return p.text || ""; }).join("")
              : "";
            var parsed = extractJson(text);
            if (parsed) return { parsed: parsed, model: model, dataUrl: packed.dataUrl };
            lastErr = new Error("無法解析辨識結果");
            return tryNext();
          });
        }).catch(function (e) {
          lastErr = e;
          return tryNext();
        });
      }

      return tryNext();
    });
  }

  function toIsoDate(raw) {
    var s = String(raw || "").trim();
    if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;
    // 民國年：115/04/17 或 115-04-17
    var m = s.match(/^(\d{2,3})[\/\-.](\d{1,2})[\/\-.](\d{1,2})/);
    if (m) {
      var y = Number(m[1]);
      if (y < 1911) y += 1911;
      return y + "-" + String(m[2]).padStart(2, "0") + "-" + String(m[3]).padStart(2, "0");
    }
    return today();
  }

  function draftsFromParsed(parsed, dataUrl) {
    var store = String(parsed.store || "").trim();
    var date = toIsoDate(parsed.date);
    var receiptNo = String(parsed.receiptNo || "").trim();
    var payment = String(parsed.payment || "").trim();
    var list = Array.isArray(parsed.items) ? parsed.items : [];
    if (!list.length && Number(parsed.total) > 0) {
      list = [{ name: "收據合計", model: "", amount: Number(parsed.total), qty: 1, category: "other", note: "" }];
    }
    return list.map(function (raw) {
      var name = String(raw.name || "").trim() || "（未命名）";
      var note = String(raw.note || "").trim();
      var amount = Number(raw.amount);
      if (isNaN(amount) || amount < 0) amount = 0;
      var giftLike = /贈品|贈送|免費/.test(name + " " + note) || Number(raw.amount) === 0 && /贈/.test(name);
      if (giftLike || Number(raw.amount) === 0 && /贈品|贈送|免費/.test(name + note)) {
        amount = 0;
        if (note.indexOf("贈品") === -1) note = note ? (note + "；贈品") : "贈品";
      }
      if (Number(raw.amount) === 0) amount = 0;
      return blankDraft({
        date: date,
        category: guessCategory(name, raw.category),
        name: name,
        model: String(raw.model || "").trim(),
        amount: amount,
        qty: Number(raw.qty) > 0 ? Number(raw.qty) : 1,
        store: store,
        receiptNo: receiptNo,
        payment: payment,
        note: note,
        photo: ""
      });
    });
  }

  function runScan() {
    if (!scanFile) {
      setStatus($("scanStatus"), "請先拍照或上傳檔案", "warn");
      return;
    }
    $("btnScan").disabled = true;
    setStatus($("scanStatus"), "辨識中，請稍候…", "warn");
    callGemini(scanFile).then(function (result) {
      drafts = draftsFromParsed(result.parsed, result.dataUrl);
      if (!drafts.length) throw new Error("沒有辨識到費用項目");
      renderDrafts();
      setStatus($("scanStatus"), "已用 " + result.model + " 抓到 " + drafts.length + " 筆，請核對修改後確認登錄", "");
      setStatus($("draftStatus"), "有錯可直接改欄位，或轉到手動表單", "warn");
    }).catch(function (err) {
      setStatus($("scanStatus"), friendlyError(err), "err");
    }).then(function () {
      $("btnScan").disabled = false;
    });
  }

  function setScanFile(file) {
    if (!file) return;
    scanFile = file;
    $("scanFileName").textContent = file.name + "（" + Math.round(file.size / 1024) + " KB）";
    $("scanPreviewBox").classList.add("on");
    var img = $("scanPreviewImg");
    if (/^image\//i.test(file.type) || /\.(jpe?g|png|webp|gif|heic|heif)$/i.test(file.name)) {
      // 預覽優先用物件網址，避免大圖 data URL 塞爆記憶體；辨識時再壓縮
      try {
        if (scanUrl && scanUrl.indexOf("blob:") === 0) URL.revokeObjectURL(scanUrl);
      } catch (e) {}
      scanUrl = URL.createObjectURL(file);
      img.hidden = false;
      img.src = scanUrl;
      img.onerror = function () {
        img.hidden = true;
        setStatus($("scanStatus"), "預覽失敗，仍可嘗試辨識；若失敗請改選 JPG／PNG", "warn");
      };
    } else {
      scanUrl = "";
      img.hidden = true;
      img.src = "";
    }
    setStatus($("scanStatus"), "檔案已就緒，可按「辨識並帶入費用」", "");
  }

  function clearScan() {
    scanFile = null;
    try {
      if (scanUrl && scanUrl.indexOf("blob:") === 0) URL.revokeObjectURL(scanUrl);
    } catch (e) {}
    scanUrl = "";
    $("scanCamera").value = "";
    if ($("scanAlbum")) $("scanAlbum").value = "";
    $("scanFile").value = "";
    $("scanPreviewImg").src = "";
    $("scanPreviewImg").hidden = true;
    $("scanPreviewBox").classList.remove("on");
    $("scanFileName").textContent = "";
    setStatus($("scanStatus"), "", "");
  }

  function confirmDrafts() {
    var btn = $("btnConfirmDrafts");
    if (btn && btn.getAttribute("data-busy") === "1") return;
    var prevLabel = btn ? btn.textContent : "確認登錄全部";
    if (btn) {
      btn.setAttribute("data-busy", "1");
      btn.disabled = true;
      btn.textContent = "登錄中…";
    }
    flash("正在登錄…", "warn");
    try {
      document.querySelectorAll(".draft-card").forEach(syncDraft);
      if (!drafts.length) {
        tellUser("沒有可登錄的項目，請先辨識或按「＋ 新增一列」", "warn", $("draftStatus"), true);
        return;
      }
      var now = new Date().toISOString();
      var added = 0;
      var startLen = items.length;
      for (var i = 0; i < drafts.length; i++) {
        var d = drafts[i];
        var name = String(d.name || "").trim();
        var amtRaw = d.amount;
        var amount = Number(amtRaw);
        if (!name) {
          tellUser("第 " + (i + 1) + " 筆缺少品名（至少要有品項與金額）", "err", $("draftStatus"), true);
          return;
        }
        if (amtRaw === "" || amtRaw == null || isNaN(amount) || amount < 0) {
          tellUser("第 " + (i + 1) + " 筆缺少金額（贈品請填 0）", "err", $("draftStatus"), true);
          return;
        }
        items.push({
          id: uid(),
          date: d.date || today(),
          category: normalizeCat(d.category),
          name: name,
          model: String(d.model || "").trim(),
          amount: amount,
          qty: Number(d.qty) > 0 ? Number(d.qty) : 1,
          store: String(d.store || "").trim(),
          receiptNo: String(d.receiptNo || "").trim(),
          payment: String(d.payment || "").trim(),
          note: String(d.note || "").trim(),
          // 批次登錄不帶收據大圖，避免辨識成功卻因空間不足存失敗
          photo: "",
          createdAt: now,
          updatedAt: now
        });
        added++;
      }
      var result;
      try {
        result = persist();
      } catch (e) {
        items = items.slice(0, startLen);
        tellUser("儲存失敗。請先到「匯出匯入」匯出備份，再按「清除全部收據照片」後重試", "err", $("draftStatus"), true);
        return;
      }
      drafts = [];
      renderDrafts();
      renderStats();
      renderList();
      clearScan();
      setStatus($("draftStatus"), "", "");
      var msg = "已登錄 " + added + " 筆 · 目前總花費 " + money(calcStats().total);
      if (result && result.stripped) msg += "（已自動省略照片以完成儲存）";
      setStatus($("scanStatus"), msg, "");
      flash(msg, "");
      try { window.alert(msg); } catch (eOk) {}
      switchTab("home");
      try {
        var hero = document.querySelector(".hero");
        if (hero) hero.scrollIntoView({ behavior: "smooth", block: "nearest" });
      } catch (eScroll) {}
    } catch (err) {
      tellUser("確認登錄失敗：" + ((err && err.message) || err), "err", $("draftStatus"), true);
    } finally {
      if (btn) {
        btn.removeAttribute("data-busy");
        btn.disabled = false;
        btn.textContent = prevLabel || "確認登錄全部";
      }
    }
  }

  function rowsForExport() {
    return items.slice().sort(function (a, b) {
      return (b.date || "").localeCompare(a.date || "");
    }).map(function (it) {
      return {
        "日期": it.date || "",
        "分類": LABEL[normalizeCat(it.category)] || "其他",
        "品名": it.name || "",
        "型號": it.model || "",
        "單價": Number(it.amount) || 0,
        "數量": Number(it.qty) > 0 ? Number(it.qty) : 1,
        "小計": lineTotal(it),
        "店家": it.store || "",
        "收據編號": it.receiptNo || "",
        "付款方式": it.payment || "",
        "備註": it.note || "",
        "有照片": it.photo ? "是" : "否",
        id: it.id || ""
      };
    });
  }

  function isIosLike() {
    var ua = navigator.userAgent || "";
    return /iPad|iPhone|iPod/.test(ua) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
  }

  function downloadBlob(blob, filename) {
    // iOS Safari 常忽略 <a download>；優先用系統分享，其次開新分頁讓使用者儲存
    if (isIosLike() && typeof navigator.share === "function") {
      try {
        var file = new File([blob], filename, { type: blob.type || "application/octet-stream" });
        if (!navigator.canShare || navigator.canShare({ files: [file] })) {
          return navigator.share({ files: [file], title: filename }).catch(function () {
            openBlobFallback(blob, filename);
          });
        }
      } catch (e) { /* fall through */ }
    }
    if (isIosLike()) {
      openBlobFallback(blob, filename);
      return;
    }
    var url = URL.createObjectURL(blob);
    var a = document.createElement("a");
    a.href = url;
    a.download = filename;
    a.rel = "noopener";
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(function () { URL.revokeObjectURL(url); }, 2000);
  }

  function openBlobFallback(blob, filename) {
    var url = URL.createObjectURL(blob);
    var w = window.open(url, "_blank");
    if (!w) {
      var a = document.createElement("a");
      a.href = url;
      a.target = "_blank";
      a.rel = "noopener";
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      a.remove();
    }
    setTimeout(function () { URL.revokeObjectURL(url); }, 60000);
  }

  function csvCell(v) {
    var s = String(v == null ? "" : v);
    return /[",\n\r]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
  }

  function exportExcel() {
    if (!items.length) {
      setStatus($("exportStatus"), "目前沒有資料可匯出", "warn");
      return;
    }
    var rows = rowsForExport();
    var withPhoto = $("exportWithPhoto").checked;
    var headers = ["日期", "分類", "品名", "型號", "單價", "數量", "小計", "店家", "收據編號", "付款方式", "備註"];
    if (withPhoto) headers.push("有照片");
    headers.push("id");
    var lines = ["\uFEFF" + headers.join(",")];
    rows.forEach(function (r) {
      lines.push(headers.map(function (h) { return csvCell(r[h]); }).join(","));
    });
    var s = calcStats();
    lines.push("");
    lines.push(csvCell("總花費") + "," + csvCell(s.total));
    lines.push(csvCell("家電") + "," + csvCell(s.appliance));
    lines.push(csvCell("家具") + "," + csvCell(s.furniture));
    lines.push(csvCell("其他") + "," + csvCell(s.other));
    downloadBlob(new Blob([lines.join("\r\n")], { type: "text/csv;charset=utf-8" }), today() + "_家電家具購物帳.csv");
    setStatus($("exportStatus"), isIosLike()
      ? "已準備 Excel／CSV（" + rows.length + " 筆）。iPhone 請在分享選單選「儲存到檔案」，或從新分頁分享儲存。"
      : "已匯出 Excel／CSV（" + rows.length + " 筆）", "");
  }

  function exportPdf() {
    if (!items.length) {
      setStatus($("exportStatus"), "目前沒有資料可匯出", "warn");
      return;
    }
    var rows = rowsForExport();
    var s = calcStats();
    var withPhoto = $("exportWithPhoto").checked;
    var html = "<!DOCTYPE html><html lang=\"zh-Hant\"><head><meta charset=\"UTF-8\" /><title>家電家具購物帳</title><style>" +
      "body{font-family:'Noto Sans TC','Microsoft JhengHei',sans-serif;color:#1c303a;padding:1.2rem;}" +
      "h1{color:#1e5a6e;font-size:1.4rem;} .t{font-size:1.25rem;font-weight:700;margin:.6rem 0 1rem;}" +
      "table{width:100%;border-collapse:collapse;font-size:.82rem;} th,td{border:1px solid #9bb;padding:.35rem .4rem;}" +
      "th{background:#e8f4f8;} .r{text-align:right;} .m{color:#5a7380;font-size:.8rem;}</style></head><body>" +
      "<h1>家電家具購物帳</h1>" +
      "<div class=\"t\">總花費：" + money(s.total) + "（共 " + s.count + " 筆）</div>" +
      "<p class=\"m\">家電 " + money(s.appliance) + " · 家具 " + money(s.furniture) + " · 其他 " + money(s.other) +
      " · " + new Date().toLocaleString("zh-TW") + "</p>" +
      "<table><thead><tr><th>日期</th><th>分類</th><th>品名</th><th>型號</th><th class=\"r\">單價</th><th class=\"r\">數量</th><th class=\"r\">小計</th>" +
      "<th>店家</th><th>收據編號</th><th>付款方式</th><th>備註</th>" + (withPhoto ? "<th>照片</th>" : "") + "</tr></thead><tbody>";

    rows.forEach(function (r) {
      html += "<tr><td>" + esc(r["日期"]) + "</td><td>" + esc(r["分類"]) + "</td><td>" + esc(r["品名"]) +
        "</td><td>" + esc(r["型號"]) +
        "</td><td class=\"r\">" + Number(r["單價"]).toLocaleString("zh-TW") +
        "</td><td class=\"r\">" + r["數量"] +
        "</td><td class=\"r\">" + Number(r["小計"]).toLocaleString("zh-TW") +
        "</td><td>" + esc(r["店家"]) + "</td><td>" + esc(r["收據編號"]) +
        "</td><td>" + esc(r["付款方式"]) +
        "</td><td>" + esc(r["備註"]) + "</td>" +
        (withPhoto ? ("<td>" + esc(r["有照片"]) + "</td>") : "") + "</tr>";
    });
    html += "</tbody></table><script>window.onload=function(){setTimeout(function(){window.print();},250);};<\/script></body></html>";

    var w = window.open("", "_blank");
    if (!w) {
      setStatus($("exportStatus"), "請允許彈出視窗；列印時選「另存 PDF」", "err");
      return;
    }
    w.document.open();
    w.document.write(html);
    w.document.close();
    setStatus($("exportStatus"), "已開啟列印視窗，請選「另存為 PDF」", "");
  }

  function exportJson() {
    if (!items.length) {
      setStatus($("exportStatus"), "目前沒有資料可匯出", "warn");
      return;
    }
    var payload = {
      app: "home-shop",
      version: 1,
      exportedAt: new Date().toISOString(),
      items: items
    };
    downloadBlob(new Blob([JSON.stringify(payload, null, 2)], { type: "application/json" }), today() + "_家電家具購物帳.json");
    setStatus($("exportStatus"), isIosLike()
      ? "已準備 JSON（" + items.length + " 筆）。若出現分享選單請選「儲存到檔案」；若開新分頁請用分享／儲存。"
      : "已匯出 JSON（" + items.length + " 筆）", "");
  }

  function parseCsv(text) {
    var raw = String(text || "").replace(/^\uFEFF/, "");
    var out = [];
    var i = 0;
    var field = "";
    var row = [];
    var inQ = false;
    while (i < raw.length) {
      var ch = raw[i];
      if (inQ) {
        if (ch === '"') {
          if (raw[i + 1] === '"') { field += '"'; i += 2; continue; }
          inQ = false; i++; continue;
        }
        field += ch; i++; continue;
      }
      if (ch === '"') { inQ = true; i++; continue; }
      if (ch === ",") { row.push(field); field = ""; i++; continue; }
      if (ch === "\n") { row.push(field); out.push(row); row = []; field = ""; i++; continue; }
      if (ch === "\r") { i++; continue; }
      field += ch; i++;
    }
    if (field.length || row.length) { row.push(field); out.push(row); }
    return out;
  }

  function normalizeList(list) {
    return list.map(function (raw) {
      return {
        id: raw.id || uid(),
        date: raw.date || raw["日期"] || today(),
        category: normalizeCat(raw.category || raw["分類"] || "other"),
        name: String(raw.name || raw["品名"] || "").trim() || "（未命名）",
        model: String(raw.model || raw["型號"] || "").trim(),
        amount: Number(raw.amount != null ? raw.amount : (raw["單價"] != null ? raw["單價"] : raw["小計"])) || 0,
        qty: Number(raw.qty != null ? raw.qty : raw["數量"]) > 0 ? Number(raw.qty != null ? raw.qty : raw["數量"]) : 1,
        store: String(raw.store || raw["店家"] || "").trim(),
        receiptNo: String(raw.receiptNo || raw["收據編號"] || "").trim(),
        payment: String(raw.payment || raw["付款方式"] || "").trim(),
        note: String(raw.note || raw["備註"] || "").trim(),
        photo: trimPhoto(typeof raw.photo === "string" ? raw.photo : ""),
        createdAt: raw.createdAt || new Date().toISOString(),
        updatedAt: raw.updatedAt || new Date().toISOString()
      };
    }).filter(function (it) {
      return it.name && it.name !== "總花費" && it.name !== "家電" && it.name !== "家具" && it.name !== "其他";
    });
  }

  function normalizeImport(data) {
    if (Array.isArray(data)) return normalizeList(data);
    if (data && Array.isArray(data.items)) return normalizeList(data.items);
    throw new Error("格式不正確");
  }

  function csvToItems(text) {
    var table = parseCsv(text);
    if (!table.length) return [];
    var headers = table[0].map(function (h) { return String(h || "").trim(); });
    var out = [];
    for (var r = 1; r < table.length; r++) {
      var obj = {};
      headers.forEach(function (h, idx) { obj[h] = table[r][idx]; });
      if (!obj["品名"] && !obj.name && !obj["日期"] && !obj.date) continue;
      if (obj["日期"] === "總花費" || obj["品名"] === "總花費") continue;
      out.push(obj);
    }
    return normalizeList(out);
  }

  function applyImport(mode) {
    if (!pendingImport) {
      setStatus($("dataStatus"), "請先選擇檔案", "warn");
      return;
    }
    if (mode === "replace") {
      if (!confirm("確定要以匯入檔「整批取代」目前全部資料？")) return;
      items = pendingImport.slice();
    } else {
      var map = {};
      items.forEach(function (it) { map[it.id] = it; });
      pendingImport.forEach(function (it) {
        if (map[it.id]) {
          map[it.id] = it;
        } else {
          if (items.some(function (x) { return x.id === it.id; })) it.id = uid();
          map[it.id] = it;
        }
      });
      items = Object.keys(map).map(function (k) { return map[k]; });
    }
    try {
      persist();
    } catch (e) {
      setStatus($("dataStatus"), "寫入失敗，空間可能不足", "err");
      return;
    }
    pendingImport = null;
    $("btnImportMerge").disabled = true;
    $("btnImportReplace").disabled = true;
    $("importFile").value = "";
    $("importHint").textContent = "";
    renderStats();
    renderList();
    setStatus($("dataStatus"), "匯入完成 · 目前共 " + items.length + " 筆 · 總花費 " + money(calcStats().total) + "。有錯請在總覽按「編輯修改」。", "");
    switchTab("home");
  }

  function bindEvents() {
    function on(id, ev, fn) {
      var el = $(id);
      if (!el) {
        console.warn("[購物帳] 找不到元素 #" + id);
        return;
      }
      el.addEventListener(ev, fn);
    }

    document.querySelectorAll(".tabs button").forEach(function (b) {
      b.addEventListener("click", function () { switchTab(b.getAttribute("data-tab")); });
    });
    document.querySelectorAll(".paths button").forEach(function (b) {
      b.addEventListener("click", function () { switchPath(b.getAttribute("data-path")); });
    });

    on("filters", "click", function (e) {
      var b = e.target.closest("button[data-filter]");
      if (!b) return;
      filterCat = b.getAttribute("data-filter");
      $("filters").querySelectorAll("button").forEach(function (x) {
        x.classList.toggle("on", x === b);
      });
      renderList();
    });

    on("searchQ", "input", renderList);

    on("itemList", "click", function (e) {
      var b = e.target.closest("button[data-act]");
      if (!b) return;
      var art = b.closest(".item");
      if (!art) return;
      var it = items.find(function (x) { return x.id === art.getAttribute("data-id"); });
      if (!it) return;
      if (b.getAttribute("data-act") === "edit") {
        fillForm(it);
        switchTab("add");
        switchPath("manual");
      } else if (b.getAttribute("data-act") === "del") {
        if (!confirm("確定刪除「" + it.name + "」？")) return;
        items = items.filter(function (x) { return x.id !== it.id; });
        persist();
        renderStats();
        renderList();
      }
    });

    on("btnSave", "click", saveItem);
    on("btnResetForm", "click", function () { resetForm(false); });
    on("btnCancelEdit", "click", function () { resetForm(false); });

    function openPicker(inputId) {
      var el = $(inputId);
      if (!el) return;
      try { el.value = ""; } catch (e) {}
      el.click();
    }
    on("btnPCam", "click", function () { openPicker("pCam"); });
    on("btnPFile", "click", function () { openPicker("pFile"); });
    on("pCam", "change", function () { attachPhoto($("pCam").files && $("pCam").files[0]); });
    on("pFile", "change", function () { attachPhoto($("pFile").files && $("pFile").files[0]); });
    on("btnClearPhoto", "click", function () {
      photoUrl = "";
      if ($("pCam")) $("pCam").value = "";
      if ($("pFile")) $("pFile").value = "";
      if ($("photoPreview")) {
        $("photoPreview").src = "";
        $("photoPreview").classList.remove("on");
      }
    });

    on("btnScanCamera", "click", function () { openPicker("scanCamera"); });
    on("btnScanAlbum", "click", function () { openPicker("scanAlbum"); });
    on("btnScanFile", "click", function () { openPicker("scanFile"); });
    on("scanCamera", "change", function () { setScanFile($("scanCamera").files && $("scanCamera").files[0]); });
    on("scanAlbum", "change", function () { setScanFile($("scanAlbum").files && $("scanAlbum").files[0]); });
    on("scanFile", "change", function () { setScanFile($("scanFile").files && $("scanFile").files[0]); });
    on("btnScan", "click", runScan);
    on("btnClearScan", "click", clearScan);
    on("btnAddDraft", "click", function () {
      drafts.push(blankDraft({}));
      renderDrafts();
    });
    // 確認登錄：按鈕文案會變「登錄中…」，並在頂部橫幅顯示結果（避免長清單下方訊息看不到）
    on("btnConfirmDrafts", "click", function (e) {
      e.preventDefault();
      confirmDrafts();
    });

    on("draftList", "input", function (e) {
      var c = e.target.closest(".draft-card");
      if (c) syncDraft(c);
      // 即時更新草稿加總，方便知道這批多少錢
      var hint = $("draftList").querySelector(".hint strong");
      if (hint) {
        var sum = 0;
        drafts.forEach(function (d) {
          var a = Number(d.amount);
          var q = Number(d.qty) > 0 ? Number(d.qty) : 1;
          if (!isNaN(a) && a >= 0) sum += a * q;
        });
        hint.textContent = money(sum);
      }
    });
    on("draftList", "change", function (e) {
      var c = e.target.closest(".draft-card");
      if (c) syncDraft(c);
    });
    on("draftList", "click", function (e) {
      var b = e.target.closest("button[data-a]");
      if (!b) return;
      var card = b.closest(".draft-card");
      if (!card) return;
      var d = syncDraft(card);
      if (!d) return;
      var act = b.getAttribute("data-a");
      if (act === "rm") {
        drafts = drafts.filter(function (x) { return x._key !== d._key; });
        renderDrafts();
        setStatus($("draftStatus"), "已刪除一列", "");
      } else if (act === "manual") {
        fillForm({
          id: "",
          date: d.date,
          category: d.category,
          name: d.name,
          model: d.model || "",
          amount: d.amount,
          qty: d.qty,
          store: d.store,
          receiptNo: d.receiptNo,
          payment: d.payment || "",
          note: d.note,
          photo: d.photo || ""
        });
        $("editId").value = "";
        $("btnCancelEdit").hidden = true;
        drafts = drafts.filter(function (x) { return x._key !== d._key; });
        renderDrafts();
        switchPath("manual");
      }
    });

    on("btnSaveKey", "click", function () {
      var k = ($("geminiKey").value || "").trim();
      if (!k) { setStatus($("scanStatus"), "請先貼上金鑰", "warn"); return; }
      try { localStorage.setItem(KEY_GEMINI, k); } catch (e) {}
      setStatus($("scanStatus"), "已記住金鑰（僅本機）", "");
    });
    on("btnClearKey", "click", function () {
      try { localStorage.removeItem(KEY_GEMINI); } catch (e) {}
      if ($("geminiKey")) $("geminiKey").value = "";
      setStatus($("scanStatus"), "已清除金鑰", "");
    });

    on("btnExportExcel", "click", exportExcel);
    on("btnExportPdf", "click", exportPdf);
    on("btnExportJson", "click", exportJson);

    on("btnImportFile", "click", function () { openPicker("importFile"); });
    on("importFile", "change", function () {
      var file = $("importFile").files && $("importFile").files[0];
      if (!file) return;
      var name = file.name || "";
      var reader = new FileReader();
      reader.onload = function () {
        try {
          var text = String(reader.result || "");
          if (/\.json$/i.test(name) || /^\s*[\{\[]/.test(text)) {
            pendingImport = normalizeImport(JSON.parse(text));
          } else if (/\.xlsx?$/i.test(name)) {
            setStatus($("dataStatus"), "請先將 Excel 另存為 CSV（UTF-8）再匯入；或匯出本 App 的 CSV／JSON。", "warn");
            pendingImport = null;
            $("btnImportMerge").disabled = true;
            $("btnImportReplace").disabled = true;
            return;
          } else {
            pendingImport = csvToItems(text);
          }
          if (!pendingImport.length) throw new Error("沒有可匯入的資料列");
          $("btnImportMerge").disabled = false;
          $("btnImportReplace").disabled = false;
          $("importHint").textContent = "已讀取 " + pendingImport.length + " 筆，請選合併或整批取代。匯入後可在總覽即時修改。";
          setStatus($("dataStatus"), "檔案已就緒", "");
        } catch (err) {
          pendingImport = null;
          $("btnImportMerge").disabled = true;
          $("btnImportReplace").disabled = true;
          $("importHint").textContent = "";
          setStatus($("dataStatus"), (err && err.message) || "無法解析檔案", "err");
        }
      };
      reader.readAsText(file, "utf-8");
    });

    on("btnImportMerge", "click", function () { applyImport("merge"); });
    on("btnImportReplace", "click", function () { applyImport("replace"); });
    on("btnClearPhotos", "click", function () {
      var n = 0;
      items = items.map(function (it) {
        if (it.photo) n++;
        var copy = Object.assign({}, it);
        copy.photo = "";
        return copy;
      });
      try {
        persist();
        setStatus($("dataStatus"), n ? ("已清除 " + n + " 筆照片，品名與金額仍保留。請回「登錄」再按確認登錄。") : "目前沒有照片可清", "");
        flash(n ? ("已清除 " + n + " 筆照片，可回「登錄」再確認") : "目前沒有照片可清", "");
      } catch (e) {
        tellUser("清除後仍無法寫入，請先匯出 JSON 備份後再清除全部資料", "err", $("dataStatus"));
      }
      renderList();
    });
    on("btnClearAll", "click", function () {
      if (!items.length) { setStatus($("dataStatus"), "目前沒有資料", "warn"); return; }
      if (!confirm("確定清除全部 " + items.length + " 筆？請確認已匯出備份。")) return;
      if (!confirm("再次確認：無法復原。")) return;
      items = [];
      persist();
      renderStats();
      renderList();
      setStatus($("dataStatus"), "已清除全部資料", "");
      flash("已清除全部資料", "warn");
    });
  }

  function boot() {
    try {
      load();
      bindEvents();
      resetForm(false);
      renderStats();
      renderList();
    } catch (err) {
      var msg = (err && err.message) ? err.message : String(err);
      try {
        var el = document.getElementById("totalMeta");
        if (el) el.textContent = "啟動失敗：" + msg;
      } catch (e2) {}
      console.error(err);
    }
  }

  function registerSw() {
    if (!("serviceWorker" in navigator)) return;
    // 清掉舊版快取，避免 iOS Safari 反覆當掉
    caches.keys().then(function (keys) {
      return Promise.all(keys.filter(function (k) {
        return /^home-shop-v(1|2|3)$/.test(k);
      }).map(function (k) { return caches.delete(k); }));
    }).catch(function () {}).then(function () {
      return navigator.serviceWorker.register("./sw.js", { updateViaCache: "none" });
    }).then(function (reg) {
      if (reg && reg.update) reg.update().catch(function () {});
    }).catch(function () {});
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
  window.addEventListener("load", function () {
    setTimeout(registerSw, 300);
  });
})();
