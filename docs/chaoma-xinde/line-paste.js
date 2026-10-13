/**
 * Word／長文貼 LINE 救援：抽出完整純文字，避免 LINE 只吃到頭尾。
 * 瀏覽器與 Node 測試共用。
 */
(function (root) {
  var LINE_SAFE = 4800;

  function decodeXmlEntities(s) {
    return String(s || "")
      .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
      .replace(/&#x([0-9a-fA-F]+);/g, function (_, h) {
        return String.fromCharCode(parseInt(h, 16));
      })
      .replace(/&#(\d+);/g, function (_, d) {
        return String.fromCharCode(parseInt(d, 10));
      })
      .replace(/&amp;/g, "&")
      .replace(/&lt;/g, "<")
      .replace(/&gt;/g, ">")
      .replace(/&quot;/g, '"')
      .replace(/&apos;/g, "'");
  }

  function stripXmlBlocks(xml, tag) {
    var re = new RegExp("<" + tag + "\\b[^>]*>[\\s\\S]*?<\\/" + tag + ">", "g");
    var prev;
    var out = String(xml || "");
    do {
      prev = out;
      out = out.replace(re, "");
    } while (out !== prev);
    return out;
  }

  function normalizeBlank(text) {
    return String(text || "")
      .replace(/\r\n/g, "\n")
      .replace(/\u00a0/g, " ")
      .replace(/[ \t]+\n/g, "\n")
      .replace(/\n{3,}/g, "\n\n")
      .trim();
  }

  function extractWordXmlText(xml) {
    var src = String(xml || "");
    src = stripXmlBlocks(src, "w:del");
    src = stripXmlBlocks(src, "w:moveFrom");
    src = stripXmlBlocks(src, "mc:Fallback");
    src = src.replace(/<w:delText\b[^>]*>[\s\S]*?<\/w:delText>/g, "");

    var paras = src.split(/<\/w:p>/);
    var out = [];
    for (var i = 0; i < paras.length; i++) {
      var p = paras[i];
      if (!/<w:p(\s|>)/.test(p)) continue;
      var parts = [];
      p.replace(
        /<w:tab\b[^>]*\/?>|<w:br\b[^>]*\/?>|<w:cr\b[^>]*\/?>|<w:t\b[^>]*>([\s\S]*?)<\/w:t>/g,
        function (m, t) {
          if (t != null) parts.push(decodeXmlEntities(t));
          else if (/w:tab/.test(m)) parts.push("\t");
          else parts.push("\n");
          return m;
        }
      );
      var line = parts.join("").replace(/\n{3,}/g, "\n\n").trim();
      if (line) out.push(line);
    }
    return normalizeBlank(out.join("\n\n"));
  }

  function htmlToPlain(html) {
    if (!html) return "";
    var s = String(html);
    s = s.replace(/<!--\[if[\s\S]*?<!\[endif\]-->/gi, "");
    s = s.replace(/<!--[\s\S]*?-->/g, "");
    s = s.replace(/<style\b[\s\S]*?<\/style>/gi, "");
    s = s.replace(/<script\b[\s\S]*?<\/script>/gi, "");
    s = s.replace(/<br\s*\/?>/gi, "\n");
    s = s.replace(/<\/p>/gi, "\n\n");
    s = s.replace(/<\/div>/gi, "\n");
    s = s.replace(/<\/h[1-6]>/gi, "\n\n");
    s = s.replace(/<\/tr>/gi, "\n");
    s = s.replace(/<\/(li|blockquote)>/gi, "\n");
    s = s.replace(/<[^>]+>/g, "");
    s = decodeXmlEntities(s);
    return normalizeBlank(s);
  }

  function pickRicherText(plain, html) {
    var a = normalizeBlank(plain);
    var b = htmlToPlain(html);
    if (!a) return b;
    if (!b) return a;
    return b.length > a.length + 8 ? b : a;
  }

  function splitLineChunks(text, maxLen) {
    maxLen = maxLen || LINE_SAFE;
    var room = Math.max(80, maxLen - 24);
    var src = normalizeBlank(text);
    if (!src) return [];
    if (src.length <= maxLen) return [src];

    var paras = src.split(/\n{2,}/);
    var raw = [];
    var cur = "";
    function flush() {
      if (cur) {
        raw.push(cur);
        cur = "";
      }
    }
    for (var i = 0; i < paras.length; i++) {
      var p = paras[i];
      var nextLen = cur ? cur.length + 2 + p.length : p.length;
      if (nextLen <= room) {
        cur = cur ? cur + "\n\n" + p : p;
        continue;
      }
      flush();
      if (p.length <= room) {
        cur = p;
        continue;
      }
      for (var j = 0; j < p.length; j += room) {
        raw.push(p.slice(j, j + room));
      }
    }
    flush();
    if (raw.length <= 1) return raw;
    var total = raw.length;
    return raw.map(function (c, idx) {
      return "（" + (idx + 1) + "/" + total + "）\n" + c;
    });
  }

  function looksCjkHeavy(s) {
    var t = String(s || "");
    var m = t.match(/[\u3400-\u9fff]/g);
    return m && m.length >= 8;
  }

  function extractDocxXmlMap(files) {
    files = files || {};
    var body = extractWordXmlText(files["word/document.xml"] || "");
    var comments = extractWordXmlText(files["word/comments.xml"] || "");
    var notes = [
      extractWordXmlText(files["word/footnotes.xml"] || ""),
      extractWordXmlText(files["word/endnotes.xml"] || "")
    ].filter(Boolean).join("\n\n");

    var headers = [];
    var footers = [];
    Object.keys(files).forEach(function (name) {
      if (/^word\/header\d*\.xml$/i.test(name)) {
        var h = extractWordXmlText(files[name]);
        if (looksCjkHeavy(h)) headers.push(h);
      } else if (/^word\/footer\d*\.xml$/i.test(name)) {
        var f = extractWordXmlText(files[name]);
        if (looksCjkHeavy(f)) footers.push(f);
      }
    });

    var extras = [];
    if (comments) extras.push("【文件註解（直接複製常會漏）】\n" + comments);
    if (notes) extras.push("【註腳／章節附註】\n" + notes);
    if (headers.length) extras.push("【頁首】\n" + headers.join("\n\n"));
    if (footers.length) extras.push("【頁尾】\n" + footers.join("\n\n"));

    var combined = body;
    if (extras.length) combined = [body].concat(extras).filter(Boolean).join("\n\n");

    return {
      body: body,
      comments: comments,
      notes: notes,
      combined: normalizeBlank(combined),
      extraCount: extras.length,
      charCount: normalizeBlank(combined).length
    };
  }

  var api = {
    LINE_SAFE: LINE_SAFE,
    decodeXmlEntities: decodeXmlEntities,
    extractWordXmlText: extractWordXmlText,
    extractDocxXmlMap: extractDocxXmlMap,
    htmlToPlain: htmlToPlain,
    pickRicherText: pickRicherText,
    splitLineChunks: splitLineChunks,
    normalizeBlank: normalizeBlank
  };

  if (typeof module !== "undefined" && module.exports) module.exports = api;
  root.LinePasteRescue = api;
})(typeof globalThis !== "undefined" ? globalThis : this);
