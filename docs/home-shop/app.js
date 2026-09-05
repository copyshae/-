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
  var MODELS = ["gemini-2.5-flash", "gemini-2.5-flash-lite", "gemini-flash-latest"];

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

  function normalizeCat(c) {
    return FROM[c] || FROM[String(c || "").trim()] || "other";
  }

  function lineTotal(it) {
    var q = Number(it.qty);
    if (!q || q < 1) q = 1;
    return (Number(it.amount) || 0) * q;
  }

  function load() {
    try {
      var raw = localStorage.getItem(STORE);
      var data = raw ? JSON.parse(raw) : null;
      items = data && Array.isArray(data.items) ? data.items : [];
    } catch (e) {
      items = [];
    }
    try {
      var k = localStorage.getItem(KEY_GEMINI);
      if (k) $("geminiKey").value = k;
    } catch (e2) {}
  }

  function persist() {
    localStorage.setItem(STORE, JSON.stringify({
      version: 1,
      updatedAt: new Date().toISOString(),
      items: items
    }));
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
      var blob = [it.name, it.store, it.note, it.receiptNo, LABEL[normalizeCat(it.category)], it.date].join(" ").toLowerCase();
      return blob.indexOf(q) !== -1;
    }).slice().sort(function (a, b) {
      if (a.date === b.date) return (b.createdAt || "").localeCompare(a.createdAt || "");
      return (b.date || "").localeCompare(a.date || "");
    });

    if (!list.length) {
      $("itemList").innerHTML = '<p class="empty">沒有符合的項目。請到「登錄」拍照辨識或手動輸入。</p>';
      return;
    }

    $("itemList").innerHTML = list.map(function (it) {
      var qty = Number(it.qty) > 1 ? (" × " + it.qty) : "";
      var thumb = it.photo ? '<img class="thumb" src="' + it.photo + '" alt="" />' : "";
      var meta = '<span class="badge">' + LABEL[normalizeCat(it.category)] + "</span> " + esc(it.date || "") +
        (it.store ? (" · " + esc(it.store)) : "") +
        (it.receiptNo ? (" · #" + esc(it.receiptNo)) : "") +
        (Number(it.qty) > 1 ? (" · 單價 " + money(it.amount)) : "");
      return (
        '<article class="item" data-id="' + it.id + '">' +
          '<div class="name">' + esc(it.name || "（未命名）") + qty + "</div>" +
          '<div class="amt">' + money(lineTotal(it)) + "</div>" +
          thumb +
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
    $("fAmt").value = "";
    $("fQty").value = "1";
    $("fStore").value = "";
    $("fNo").value = "";
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
    $("fAmt").value = it.amount != null ? it.amount : "";
    $("fQty").value = it.qty || 1;
    $("fStore").value = it.store || "";
    $("fNo").value = it.receiptNo || "";
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

  function compressImage(file, maxSide, quality) {
    return new Promise(function (resolve, reject) {
      var reader = new FileReader();
      reader.onerror = function () { reject(new Error("讀取失敗")); };
      reader.onload = function () {
        var img = new Image();
        img.onload = function () {
          var scale = Math.min(1, maxSide / Math.max(img.width, img.height));
          var canvas = document.createElement("canvas");
          canvas.width = Math.max(1, Math.round(img.width * scale));
          canvas.height = Math.max(1, Math.round(img.height * scale));
          canvas.getContext("2d").drawImage(img, 0, 0, canvas.width, canvas.height);
          resolve(canvas.toDataURL("image/jpeg", quality));
        };
        img.onerror = function () { reject(new Error("圖片無法開啟")); };
        img.src = reader.result;
      };
      reader.readAsDataURL(file);
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
    var amount = Number($("fAmt").value);
    var qty = Number($("fQty").value);
    var date = $("fDate").value;
    if (!name) { setStatus($("formStatus"), "請填品名／項目", "err"); return; }
    if (!date) { setStatus($("formStatus"), "請填日期", "err"); return; }
    if (!(amount >= 0) || isNaN(amount)) { setStatus($("formStatus"), "請填正確金額", "err"); return; }
    if (!qty || qty < 1) qty = 1;

    var id = $("editId").value;
    var now = new Date().toISOString();
    var rec = {
      id: id || uid(),
      date: date,
      category: $("fCat").value || "appliance",
      name: name,
      amount: amount,
      qty: qty,
      store: ($("fStore").value || "").trim(),
      receiptNo: ($("fNo").value || "").trim(),
      note: ($("fNote").value || "").trim(),
      photo: photoUrl || "",
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
    compressImage(file, 960, 0.72).then(function (url) {
      photoUrl = url;
      $("photoPreview").src = url;
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
      amount: partial.amount != null ? Number(partial.amount) : "",
      qty: partial.qty > 0 ? Number(partial.qty) : 1,
      store: partial.store || "",
      receiptNo: partial.receiptNo || "",
      note: partial.note || "",
      photo: partial.photo || scanUrl || ""
    };
  }

  function renderDrafts() {
    $("draftCard").hidden = !drafts.length;
    if (!drafts.length) {
      $("draftList").innerHTML = "";
      return;
    }
    $("draftList").innerHTML = drafts.map(function (d, i) {
      return (
        '<div class="draft-card" data-key="' + d._key + '">' +
          "<h3>第 " + (i + 1) + " 筆（可直接改）</h3>" +
          '<div class="row">' +
            '<div><label>日期</label><input type="date" data-f="date" value="' + esc(d.date) + '" /></div>' +
            '<div><label>分類</label><select data-f="category">' +
              '<option value="appliance"' + (d.category === "appliance" ? " selected" : "") + ">家電</option>" +
              '<option value="furniture"' + (d.category === "furniture" ? " selected" : "") + ">家具</option>" +
              '<option value="other"' + (d.category === "other" ? " selected" : "") + ">其他</option>" +
            "</select></div>" +
          "</div>" +
          '<label>品名</label><input type="text" data-f="name" value="' + esc(d.name) + '" />' +
          '<div class="row">' +
            '<div><label>金額</label><input type="number" data-f="amount" min="0" step="1" value="' + esc(d.amount) + '" /></div>' +
            '<div><label>數量</label><input type="number" data-f="qty" min="1" step="1" value="' + esc(d.qty) + '" /></div>' +
          "</div>" +
          '<label>店家</label><input type="text" data-f="store" value="' + esc(d.store) + '" />' +
          '<label>收據編號</label><input type="text" data-f="receiptNo" value="' + esc(d.receiptNo) + '" />' +
          '<label>備註</label><textarea data-f="note">' + esc(d.note) + "</textarea>" +
          '<div class="acts">' +
            '<button type="button" data-a="manual">改到手動表單</button>' +
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

  function callGemini(file) {
    var apiKey = ($("geminiKey").value || "").trim() || localStorage.getItem(KEY_GEMINI) || "";
    if (!apiKey) return Promise.reject(new Error("請先填 Gemini 金鑰，或改用手動輸入"));

    return fileToBase64(file).then(function (packed) {
      var mime = packed.mime;
      if (!mime || mime === "application/octet-stream") {
        mime = /\.pdf$/i.test(file.name) ? "application/pdf" : "image/jpeg";
      }
      var prompt =
        "這是家電／家具相關收據、發票、訂單或費用明細（繁體中文）。請擷取費用項目。只回 JSON，不要 markdown：" +
        '{"store":"店家","date":"YYYY-MM-DD或空","receiptNo":"編號","items":[{"name":"品名","amount":單價數字,"qty":數量,"category":"appliance|furniture|other","note":"備註"}],"total":總額}。' +
        "家電 appliance、家具 furniture、運費安裝保固等 other。金額為新台幣數字。看不清可留空。若只有總額，items 放一筆「收據合計」。";
      var parts = [{ text: prompt }, { inline_data: { mime_type: mime, data: packed.b64 } }];
      var lastErr = null;
      var idx = 0;

      function tryNext() {
        if (idx >= MODELS.length) return Promise.reject(lastErr || new Error("Gemini 無回應"));
        var model = MODELS[idx++];
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
              lastErr = new Error((data.error && data.error.message) || ("HTTP " + res.status));
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

  function draftsFromParsed(parsed, dataUrl) {
    var store = String(parsed.store || "").trim();
    var date = String(parsed.date || "").trim();
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) date = today();
    var receiptNo = String(parsed.receiptNo || "").trim();
    var list = Array.isArray(parsed.items) ? parsed.items : [];
    if (!list.length && Number(parsed.total) > 0) {
      list = [{ name: "收據合計", amount: Number(parsed.total), qty: 1, category: "other", note: "" }];
    }
    return list.map(function (raw) {
      var name = String(raw.name || "").trim() || "（未命名）";
      return blankDraft({
        date: date,
        category: guessCategory(name, raw.category),
        name: name,
        amount: Number(raw.amount) || 0,
        qty: Number(raw.qty) > 0 ? Number(raw.qty) : 1,
        store: store,
        receiptNo: receiptNo,
        note: String(raw.note || "").trim(),
        photo: /^image\//i.test((scanFile && scanFile.type) || "") ? (dataUrl || "") : ""
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
      setStatus($("scanStatus"), (err && err.message) || "辨識失敗", "err");
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
    if (/^image\//i.test(file.type) || /\.(jpe?g|png|webp|gif)$/i.test(file.name)) {
      fileToBase64(file).then(function (p) {
        scanUrl = p.dataUrl;
        img.hidden = false;
        img.src = p.dataUrl;
      });
    } else {
      scanUrl = "";
      img.hidden = true;
      img.src = "";
    }
    setStatus($("scanStatus"), "檔案已就緒，可按「辨識並帶入費用」", "");
  }

  function clearScan() {
    scanFile = null;
    scanUrl = "";
    $("scanCamera").value = "";
    $("scanFile").value = "";
    $("scanPreviewImg").src = "";
    $("scanPreviewImg").hidden = true;
    $("scanPreviewBox").classList.remove("on");
    $("scanFileName").textContent = "";
    setStatus($("scanStatus"), "", "");
  }

  function confirmDrafts() {
    document.querySelectorAll(".draft-card").forEach(syncDraft);
    if (!drafts.length) {
      setStatus($("draftStatus"), "沒有可登錄的項目", "warn");
      return;
    }
    var now = new Date().toISOString();
    var added = 0;
    for (var i = 0; i < drafts.length; i++) {
      var d = drafts[i];
      var name = String(d.name || "").trim();
      var amount = Number(d.amount);
      if (!name) {
        setStatus($("draftStatus"), "第 " + (i + 1) + " 筆缺少品名", "err");
        return;
      }
      if (!(amount >= 0) || isNaN(amount)) {
        setStatus($("draftStatus"), "第 " + (i + 1) + " 筆金額有誤", "err");
        return;
      }
      items.push({
        id: uid(),
        date: d.date || today(),
        category: normalizeCat(d.category),
        name: name,
        amount: amount,
        qty: Number(d.qty) > 0 ? Number(d.qty) : 1,
        store: String(d.store || "").trim(),
        receiptNo: String(d.receiptNo || "").trim(),
        note: String(d.note || "").trim(),
        photo: d.photo || "",
        createdAt: now,
        updatedAt: now
      });
      added++;
    }
    try {
      persist();
    } catch (e) {
      setStatus($("draftStatus"), "儲存失敗，空間可能不足", "err");
      return;
    }
    drafts = [];
    renderDrafts();
    renderStats();
    renderList();
    clearScan();
    setStatus($("draftStatus"), "", "");
    setStatus($("scanStatus"), "已登錄 " + added + " 筆 · 總花費 " + money(calcStats().total), "");
    switchTab("home");
  }

  function rowsForExport() {
    return items.slice().sort(function (a, b) {
      return (b.date || "").localeCompare(a.date || "");
    }).map(function (it) {
      return {
        "日期": it.date || "",
        "分類": LABEL[normalizeCat(it.category)] || "其他",
        "品名": it.name || "",
        "單價": Number(it.amount) || 0,
        "數量": Number(it.qty) > 0 ? Number(it.qty) : 1,
        "小計": lineTotal(it),
        "店家": it.store || "",
        "收據編號": it.receiptNo || "",
        "備註": it.note || "",
        "有照片": it.photo ? "是" : "否",
        id: it.id || ""
      };
    });
  }

  function downloadBlob(blob, filename) {
    var a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = filename;
    a.click();
    setTimeout(function () { URL.revokeObjectURL(a.href); }, 1500);
  }

  function csvCell(v) {
    var s = String(v == null ? "" : v);
    return /[",\n\r]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
  }

  function exportExcel() {
    var rows = rowsForExport();
    var withPhoto = $("exportWithPhoto").checked;
    var headers = ["日期", "分類", "品名", "單價", "數量", "小計", "店家", "收據編號", "備註"];
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
    setStatus($("exportStatus"), "已匯出 Excel／CSV（" + rows.length + " 筆）", "");
  }

  function exportPdf() {
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
      "<table><thead><tr><th>日期</th><th>分類</th><th>品名</th><th class=\"r\">單價</th><th class=\"r\">數量</th><th class=\"r\">小計</th>" +
      "<th>店家</th><th>收據編號</th><th>備註</th>" + (withPhoto ? "<th>照片</th>" : "") + "</tr></thead><tbody>";

    rows.forEach(function (r) {
      html += "<tr><td>" + esc(r["日期"]) + "</td><td>" + esc(r["分類"]) + "</td><td>" + esc(r["品名"]) +
        "</td><td class=\"r\">" + Number(r["單價"]).toLocaleString("zh-TW") +
        "</td><td class=\"r\">" + r["數量"] +
        "</td><td class=\"r\">" + Number(r["小計"]).toLocaleString("zh-TW") +
        "</td><td>" + esc(r["店家"]) + "</td><td>" + esc(r["收據編號"]) +
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
    var payload = {
      app: "home-shop",
      version: 1,
      exportedAt: new Date().toISOString(),
      items: items
    };
    downloadBlob(new Blob([JSON.stringify(payload, null, 2)], { type: "application/json" }), today() + "_家電家具購物帳.json");
    setStatus($("exportStatus"), "已匯出 JSON（" + items.length + " 筆）", "");
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
        amount: Number(raw.amount != null ? raw.amount : (raw["單價"] != null ? raw["單價"] : raw["小計"])) || 0,
        qty: Number(raw.qty != null ? raw.qty : raw["數量"]) > 0 ? Number(raw.qty != null ? raw.qty : raw["數量"]) : 1,
        store: String(raw.store || raw["店家"] || "").trim(),
        receiptNo: String(raw.receiptNo || raw["收據編號"] || "").trim(),
        note: String(raw.note || raw["備註"] || "").trim(),
        photo: typeof raw.photo === "string" ? raw.photo : "",
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
    document.querySelectorAll(".tabs button").forEach(function (b) {
      b.addEventListener("click", function () { switchTab(b.getAttribute("data-tab")); });
    });
    document.querySelectorAll(".paths button").forEach(function (b) {
      b.addEventListener("click", function () { switchPath(b.getAttribute("data-path")); });
    });

    $("filters").addEventListener("click", function (e) {
      var b = e.target.closest("button[data-filter]");
      if (!b) return;
      filterCat = b.getAttribute("data-filter");
      $("filters").querySelectorAll("button").forEach(function (x) {
        x.classList.toggle("on", x === b);
      });
      renderList();
    });

    $("searchQ").addEventListener("input", renderList);

    $("itemList").addEventListener("click", function (e) {
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

    $("btnSave").addEventListener("click", saveItem);
    $("btnResetForm").addEventListener("click", function () { resetForm(false); });
    $("btnCancelEdit").addEventListener("click", function () { resetForm(false); });
    $("pCam").addEventListener("change", function () { attachPhoto($("pCam").files && $("pCam").files[0]); });
    $("pFile").addEventListener("change", function () { attachPhoto($("pFile").files && $("pFile").files[0]); });
    $("btnClearPhoto").addEventListener("click", function () {
      photoUrl = "";
      $("pCam").value = "";
      $("pFile").value = "";
      $("photoPreview").src = "";
      $("photoPreview").classList.remove("on");
    });

    $("scanCamera").addEventListener("change", function () { setScanFile($("scanCamera").files && $("scanCamera").files[0]); });
    $("scanFile").addEventListener("change", function () { setScanFile($("scanFile").files && $("scanFile").files[0]); });
    $("btnScan").addEventListener("click", runScan);
    $("btnClearScan").addEventListener("click", clearScan);
    $("btnAddDraft").addEventListener("click", function () {
      drafts.push(blankDraft({ photo: scanUrl || "" }));
      renderDrafts();
    });
    $("btnConfirmDrafts").addEventListener("click", confirmDrafts);

    $("draftList").addEventListener("input", function (e) {
      var c = e.target.closest(".draft-card");
      if (c) syncDraft(c);
    });
    $("draftList").addEventListener("change", function (e) {
      var c = e.target.closest(".draft-card");
      if (c) syncDraft(c);
    });
    $("draftList").addEventListener("click", function (e) {
      var b = e.target.closest("button[data-a]");
      if (!b) return;
      var card = b.closest(".draft-card");
      if (!card) return;
      var d = syncDraft(card);
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
          amount: d.amount,
          qty: d.qty,
          store: d.store,
          receiptNo: d.receiptNo,
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

    $("btnSaveKey").addEventListener("click", function () {
      var k = ($("geminiKey").value || "").trim();
      if (!k) { setStatus($("scanStatus"), "請先貼上金鑰", "warn"); return; }
      try { localStorage.setItem(KEY_GEMINI, k); } catch (e) {}
      setStatus($("scanStatus"), "已記住金鑰（僅本機）", "");
    });
    $("btnClearKey").addEventListener("click", function () {
      try { localStorage.removeItem(KEY_GEMINI); } catch (e) {}
      $("geminiKey").value = "";
      setStatus($("scanStatus"), "已清除金鑰", "");
    });

    $("btnExportExcel").addEventListener("click", exportExcel);
    $("btnExportPdf").addEventListener("click", exportPdf);
    $("btnExportJson").addEventListener("click", exportJson);

    $("importFile").addEventListener("change", function () {
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

    $("btnImportMerge").addEventListener("click", function () { applyImport("merge"); });
    $("btnImportReplace").addEventListener("click", function () { applyImport("replace"); });
    $("btnClearAll").addEventListener("click", function () {
      if (!items.length) { setStatus($("dataStatus"), "目前沒有資料", "warn"); return; }
      if (!confirm("確定清除全部 " + items.length + " 筆？請確認已匯出備份。")) return;
      if (!confirm("再次確認：無法復原。")) return;
      items = [];
      persist();
      renderStats();
      renderList();
      setStatus($("dataStatus"), "已清除全部資料", "");
    });
  }

  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.register("./sw.js").catch(function () {});
  }

  load();
  bindEvents();
  resetForm(false);
  renderStats();
  renderList();
})();
