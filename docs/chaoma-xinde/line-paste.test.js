#!/usr/bin/env node
"use strict";

var assert = require("assert");
var api = require("./line-paste.js");

function wDoc(bodyInner) {
  return (
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" ' +
    'xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006">' +
    "<w:body>" + bodyInner + "</w:body></w:document>"
  );
}

function p(text) {
  return "<w:p><w:r><w:t>" + text + "</w:t></w:r></w:p>";
}

function textBox(text) {
  return (
    "<w:p><w:r>" +
    '<mc:AlternateContent><mc:Choice Requires="wps">' +
    "<w:drawing><w:txbxContent>" + p(text) + "</w:txbxContent></w:drawing>" +
    "</mc:Choice><mc:Fallback><w:pict><w:txbxContent>" +
    p("FALLBACK重複" + text) +
    "</w:txbxContent></w:pict></mc:Fallback></mc:AlternateContent>" +
    "</w:r></w:p>"
  );
}

var xml = wDoc(
  p("婚姻中的幸福，難以有所感動吧。") +
    textBox("所以協調完美演出，才能如跳恰恰般。") +
    "<w:p><w:del><w:r><w:delText>這段已刪不該出現</w:delText></w:r></w:del></w:p>" +
    p("感恩宇宙，感恩天地")
);

var text = api.extractWordXmlText(xml);
assert.ok(text.indexOf("難以有所感動吧") >= 0, "應含開頭");
assert.ok(text.indexOf("跳恰恰") >= 0, "文字方塊中段應被抽出");
assert.ok(text.indexOf("感恩宇宙") >= 0, "應含結尾");
assert.ok(text.indexOf("已刪不該出現") < 0, "修訂刪除不應出現");
assert.ok(text.indexOf("FALLBACK") < 0, "AlternateContent 後援不應重複");

var mapped = api.extractDocxXmlMap({
  "word/document.xml": xml,
  "word/comments.xml": wDoc(p("註解裡的中段補充"))
});
assert.ok(mapped.combined.indexOf("註解裡的中段補充") >= 0, "註解應附在全文");
assert.ok(mapped.extraCount >= 1, "應標示有額外區塊");

var html = "<html><body><p>頭段</p><v:textbox><p>中間文字方塊</p></v:textbox><p>尾段</p></body></html>";
var picked = api.pickRicherText("頭段\n尾段", html);
assert.ok(picked.indexOf("中間文字方塊") >= 0, "Word HTML 應救回中段");

var longBody = Array(30).fill("這是一段用來測試切則的正文，內容要夠長才會超過上限。").join("");
var chunks = api.splitLineChunks(longBody, 200);
assert.ok(chunks.length >= 2, "超長文應切成多則");
assert.ok(/^（1\//.test(chunks[0]), "第一則應有則數標籤");
chunks.forEach(function (c) {
  assert.ok(c.length <= 230, "切則後單則不可再爆量：" + c.length);
});

var shortChunks = api.splitLineChunks("短文即可", 4800);
assert.strictEqual(shortChunks.length, 1);
assert.strictEqual(shortChunks[0], "短文即可");

console.log("line-paste tests ok");
