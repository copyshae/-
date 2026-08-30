/** 太陽心語：朗讀文字（標題唸一次，正文不重複；原圖項目可 OCR） */
(function (global) {
  function cleanRead(s) {
    return (s || "")
      .replace(/\s*天圓文化\s*Richestlife\s*/gi, "")
      .replace(/\s*YouTube\s*太陽心語相關影音縮圖\s*/gi, "")
      .replace(/^太陽心語[：:]\s*/i, "")
      .replace(/\s+/g, " ")
      .trim();
  }

  function stripShortTitlePrefix(title, text) {
    title = cleanRead(title);
    text = cleanRead(text);
    if (!title || !text || text.indexOf(title) !== 0) return text;
    if (title.indexOf("，") >= 0 || title.indexOf("；") >= 0) return text;
    var rest = text.slice(title.length);
    if (rest.charAt(0) === "，" || rest.charAt(0) === ",") {
      var body = rest.replace(/^[，,、。 ]+/, "");
      return body || text;
    }
    return text;
  }

  function removeTitlePrefix(title, body) {
    title = cleanRead(title);
    body = cleanRead(body);
    if (!title || !body) return body;
    if (body.indexOf(title) === 0) {
      return body.slice(title.length).replace(/^[。，,、；;：:\s]+/, "") || body;
    }
    var core = title.replace(/[。，,、；;：:\s]+$/g, "");
    if (core && core !== title && body.indexOf(core) === 0) {
      return body.slice(core.length).replace(/^[。，,、；;：:\s]+/, "") || body;
    }
    return stripShortTitlePrefix(title, body);
  }

  function combineTitleAndBody(title, body) {
    title = cleanRead(title);
    body = cleanRead(body);
    if (!body) return title || "";
    if (!title) return body;
    if (body === title) return title;
    var rest = removeTitlePrefix(title, body);
    if (rest === body) return title + "。" + body;
    if (!rest) return title;
    return title + "。" + rest;
  }

  function speechText(it) {
    if (!it) return "";
    var title = cleanRead(it.title || "");
    if (it.readText && it.readTextSource === "manual") {
      return combineTitleAndBody(title, it.readText);
    }
    if (it.readText && (it.readTextSource === "seed" || it.source === "種子語錄")) {
      return combineTitleAndBody(title, it.readText);
    }
    if (it.readText) {
      return combineTitleAndBody(title, it.readText);
    }
    var text = stripShortTitlePrefix(it.title, it.text);
    var plain = cleanRead(it.plain);
    var parts = [];
    if (title) parts.push(title);
    if (text) {
      var rest = removeTitlePrefix(title, text);
      if (rest && rest !== title) parts.push(rest);
    }
    if (plain && plain.indexOf("YouTube") < 0) {
      var joined = parts.join("。");
      if (joined.indexOf(plain) < 0) parts.push(plain);
    }
    return parts.filter(Boolean).join("。");
  }

  function resolveSpeechText(it, imgEl) {
    if (!it) return Promise.resolve("");
    if (it.readTextSource === "manual" || it.readTextSource === "seed") {
      return Promise.resolve(speechText(it));
    }
    if (global.TaiyangOcrRead && global.TaiyangOcrRead.needsImageOcr(it) && imgEl) {
      return global.TaiyangOcrRead.getOcrText(it.id, imgEl).then(function (ocr) {
        if (ocr && ocr.length >= 8) return combineTitleAndBody(cleanRead(it.title || ""), ocr);
        return speechText(it);
      });
    }
    return Promise.resolve(speechText(it));
  }

  global.TaiyangReadText = { speechText: speechText, resolveSpeechText: resolveSpeechText };
})(typeof window !== "undefined" ? window : globalThis);
