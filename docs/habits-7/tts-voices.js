/* 語音讀誦：男聲／女聲多選（habits-7／daily-14／life-desk 共用偏好） */
(function (global) {
  const TTS_PREF_KEY = "tts-voice-pref-v1";
  const FEMALE_HINT = /female|woman|girl|女|mei[-\s]?jia|ting[-\s]?ting|hsiaochen|hsiaoyu|xiaoxiao|xiaoyi|xiaoyan|xiaochen|hanhan|yaoyao|huihui|tracy|susan|linda|karen|zira|jenny|aria|sonia|nanami|kyoko|yuna|heami|meijia|tingting|zhiyu|xiaomeng|xiaoqiu|hannah|catherine|yaoyao|hui ting|sin[-\s]?ji/i;
  const MALE_HINT = /male|man|boy|男|yunjhe|yunyang|yunjian|yunjie|kangkang|david|mark|danny|guy|ryan|jason|zhiwei|kang|yunxi|yunhao|yunye|yuncheng|andrew|tony|arthur|brian|li[-\s]?mu/i;
  const NICE_FEMALE = [/hsiaochen/i, /mei[-\s]?jia/i, /ting[-\s]?ting/i, /hsiaoyu/i, /xiaoxiao/i, /google/i];
  const NICE_MALE = [/yunjhe/i, /yunyang/i, /yunjian/i, /yunjie/i, /kangkang/i, /google/i];

  function loadTtsPref() {
    try {
      const raw = localStorage.getItem(TTS_PREF_KEY);
      if (!raw) return { gender: "F", voiceURI: "", voiceName: "" };
      const p = JSON.parse(raw);
      const gender = (p.gender === "M" || p.gender === "all") ? p.gender : "F";
      return { gender: gender, voiceURI: p.voiceURI || "", voiceName: p.voiceName || "" };
    } catch (e) {
      return { gender: "F", voiceURI: "", voiceName: "" };
    }
  }

  function saveTtsPref(pref) {
    try { localStorage.setItem(TTS_PREF_KEY, JSON.stringify(pref)); } catch (e) {}
  }

  function guessGender(voice) {
    const s = (voice.name || "") + " " + (voice.lang || "") + " " + (voice.voiceURI || "");
    if (FEMALE_HINT.test(s)) return "F";
    if (MALE_HINT.test(s)) return "M";
    return "U";
  }

  function regionLabel(voice) {
    const s = (voice.lang || "") + " " + (voice.name || "");
    if (/zh-TW|zh_TW|Taiwan|臺灣|台灣|國語.*臺/i.test(s)) return "台灣";
    if (/zh-HK|yue|Cantonese|香港|粵/i.test(s)) return "香港";
    if (/zh-CN|zh_CN|China|普通話|大陆|大陸/i.test(s)) return "大陸";
    return voice.lang || "";
  }

  function listZhVoices() {
    try {
      const voices = (global.speechSynthesis && global.speechSynthesis.getVoices()) || [];
      return voices.filter(function (v) {
        return /zh|cmn|yue|chinese|中文|國語|普通话|粤/i.test((v.lang || "") + " " + (v.name || ""));
      });
    } catch (e) {
      return [];
    }
  }

  function voiceScore(voice, preferGender) {
    let score = 0;
    const g = guessGender(voice);
    const s = (voice.name || "") + " " + (voice.lang || "");
    if (/zh-TW|Taiwan|臺灣|台灣/i.test(s)) score += 50;
    else if (/zh-HK|香港/i.test(s)) score += 20;
    else if (/zh-CN|CN/i.test(s)) score += 10;
    if (preferGender === "F" && g === "F") score += 40;
    if (preferGender === "M" && g === "M") score += 40;
    if (preferGender === "F") {
      NICE_FEMALE.forEach(function (re, i) { if (re.test(s)) score += 30 - i; });
    }
    if (preferGender === "M") {
      NICE_MALE.forEach(function (re, i) { if (re.test(s)) score += 30 - i; });
    }
    if (/Natural|Online|Premium|Neural/i.test(s)) score += 8;
    return score;
  }

  function voiceLabel(voice) {
    const g = guessGender(voice);
    const gText = g === "F" ? "女聲" : g === "M" ? "男聲" : "語音";
    const reg = regionLabel(voice);
    return gText + (reg ? "・" + reg : "") + "｜" + voice.name;
  }

  function filteredVoices(gender) {
    const all = listZhVoices();
    let list = all;
    if (gender === "F") list = all.filter(function (v) { return guessGender(v) !== "M"; });
    if (gender === "M") list = all.filter(function (v) { return guessGender(v) !== "F"; });
    if (!list.length) list = all;
    const prefer = gender === "all" ? "F" : gender;
    return list.slice().sort(function (a, b) {
      return voiceScore(b, prefer) - voiceScore(a, prefer);
    });
  }

  function resolveSelectedVoice() {
    const pref = loadTtsPref();
    const list = filteredVoices(pref.gender);
    if (!list.length) return null;
    if (pref.voiceURI) {
      const byUri = list.find(function (v) { return v.voiceURI === pref.voiceURI; });
      if (byUri) return byUri;
    }
    if (pref.voiceName) {
      const byName = list.find(function (v) { return v.name === pref.voiceName; });
      if (byName) return byName;
    }
    return list[0];
  }

  function fillVoiceSelectors() {
    const genderEl = document.getElementById("ttsGender");
    const voiceEl = document.getElementById("ttsVoice");
    if (!genderEl || !voiceEl) return;
    const pref = loadTtsPref();
    genderEl.value = pref.gender || "F";
    const list = filteredVoices(genderEl.value);
    voiceEl.innerHTML = "";
    if (!list.length) {
      const opt = document.createElement("option");
      opt.value = "";
      opt.textContent = "（此裝置暫無中文語音，將用系統預設）";
      voiceEl.appendChild(opt);
      return;
    }
    list.forEach(function (v) {
      const opt = document.createElement("option");
      opt.value = v.voiceURI || v.name;
      opt.textContent = voiceLabel(v);
      voiceEl.appendChild(opt);
    });
    const sel = resolveSelectedVoice();
    if (sel) voiceEl.value = sel.voiceURI || sel.name;
  }

  function applyFromUI() {
    const genderEl = document.getElementById("ttsGender");
    const voiceEl = document.getElementById("ttsVoice");
    if (!genderEl || !voiceEl) return;
    const list = filteredVoices(genderEl.value);
    const chosen = list.find(function (v) {
      return (v.voiceURI || v.name) === voiceEl.value;
    }) || list[0] || null;
    saveTtsPref({
      gender: genderEl.value,
      voiceURI: chosen ? (chosen.voiceURI || "") : "",
      voiceName: chosen ? chosen.name : ""
    });
  }

  function bindVoicePicker(options) {
    const genderEl = document.getElementById("ttsGender");
    const voiceEl = document.getElementById("ttsVoice");
    const previewBtn = document.getElementById("ttsPreview");
    if (!genderEl || !voiceEl) return;

    genderEl.addEventListener("change", function () {
      const pref = loadTtsPref();
      pref.gender = genderEl.value;
      pref.voiceURI = "";
      pref.voiceName = "";
      saveTtsPref(pref);
      fillVoiceSelectors();
      applyFromUI();
    });
    voiceEl.addEventListener("change", applyFromUI);

    if (previewBtn) {
      previewBtn.addEventListener("click", function () {
        applyFromUI();
        const text = "您好，這是目前選擇的讀誦聲音。以身心靈提升、靈命持續成長為首要。";
        if (options && typeof options.speak === "function") options.speak(text);
        else if (typeof global.speakText === "function") global.speakText(text);
      });
    }

    fillVoiceSelectors();
    if (global.speechSynthesis) {
      global.speechSynthesis.addEventListener("voiceschanged", function () {
        fillVoiceSelectors();
      });
      // 部分瀏覽器第一次 getVoices 為空，延遲再填一次
      setTimeout(fillVoiceSelectors, 250);
      setTimeout(fillVoiceSelectors, 1000);
    }
  }

  global.TtsVoices = {
    loadTtsPref: loadTtsPref,
    saveTtsPref: saveTtsPref,
    pickZhVoice: resolveSelectedVoice,
    resolveSelectedVoice: resolveSelectedVoice,
    fillVoiceSelectors: fillVoiceSelectors,
    bindVoicePicker: bindVoicePicker,
    listZhVoices: listZhVoices,
    voiceLabel: voiceLabel
  };
})(typeof window !== "undefined" ? window : this);
