/* 語音讀誦：男聲／女聲多選（habits-7／daily-14／life-desk 共用偏好） */
(function (global) {
  const TTS_PREF_KEY = "tts-voice-pref-v2";
  const TTS_PREF_KEY_LEGACY = "tts-voice-pref-v1";

  // 常見中文／系統語音名稱線索
  const FEMALE_HINT = /female|woman|girl|\bf\b|女|mei[-\s]?jia|ting[-\s]?ting|hsiaochen|hsiaoyu|hsiao[-\s]?chen|hsiao[-\s]?yu|xiaoxiao|xiaoyi|xiaoyan|xiaochen|hanhan|yaoyao|huihui|tracy|susan|linda|karen|zira|jenny|aria|sonia|nanami|kyoko|yuna|heami|meijia|tingting|zhiyu|xiaomeng|xiaoqiu|hannah|catherine|sin[-\s]?ji|hiu[-\s]?maan|xiaomiao|xiaohan|xiaoqiu|晓晓|曉曉|曉雨|美佳|婷婷/i;
  const MALE_HINT = /male|man|boy|\bm\b|男|yunjhe|yun[-\s]?jhe|yunyang|yunjian|yunjie|yunxi|yunhao|yunye|yuncheng|yunfeng|kangkang|zhiwei|kang|david|mark|danny|guy|ryan|jason|andrew|tony|arthur|brian|li[-\s]?mu|wang|liang|chang|云哲|雲哲|云扬|雲揚|云健|康康|志伟|志偉|晓东|曉東/i;
  const NICE_FEMALE = [/hsiaochen/i, /mei[-\s]?jia/i, /ting[-\s]?ting/i, /hsiaoyu/i, /xiaoxiao/i, /google/i];
  const NICE_MALE = [/yunjhe/i, /yunyang/i, /yunjian/i, /yunjie/i, /zhiwei/i, /kangkang/i, /yunxi/i, /google/i];

  function loadTtsPref() {
    try {
      const raw = localStorage.getItem(TTS_PREF_KEY) || localStorage.getItem(TTS_PREF_KEY_LEGACY);
      if (!raw) return { gender: "F", choiceId: "", voiceURI: "", voiceName: "", pitch: 1 };
      const p = JSON.parse(raw);
      const gender = (p.gender === "M" || p.gender === "all") ? p.gender : "F";
      return {
        gender: gender,
        choiceId: p.choiceId || "",
        voiceURI: p.voiceURI || "",
        voiceName: p.voiceName || "",
        pitch: Number(p.pitch) > 0 ? Number(p.pitch) : 1
      };
    } catch (e) {
      return { gender: "F", choiceId: "", voiceURI: "", voiceName: "", pitch: 1 };
    }
  }

  function saveTtsPref(pref) {
    try { localStorage.setItem(TTS_PREF_KEY, JSON.stringify(pref)); } catch (e) {}
  }

  function guessGender(voice) {
    const s = (voice.name || "") + " " + (voice.lang || "") + " " + (voice.voiceURI || "");
    // 先判男再判女，避免把 Yun* 等誤判
    if (MALE_HINT.test(s)) return "M";
    if (FEMALE_HINT.test(s)) return "F";
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
        return /zh|cmn|yue|chinese|中文|國語|普通话|粤|華語|华语/i.test((v.lang || "") + " " + (v.name || ""));
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

  function sortZh(preferGender) {
    const prefer = preferGender === "all" ? "F" : preferGender;
    return listZhVoices().slice().sort(function (a, b) {
      return voiceScore(b, prefer) - voiceScore(a, prefer);
    });
  }

  function makeChoice(id, voice, pitch, gender, label, synthetic) {
    return {
      id: id,
      voice: voice,
      pitch: pitch,
      gender: gender,
      label: label,
      synthetic: !!synthetic
    };
  }

  function nativeLabel(voice) {
    const g = guessGender(voice);
    const gText = g === "F" ? "女聲" : g === "M" ? "男聲" : "未標示";
    const reg = regionLabel(voice);
    return gText + (reg ? "・" + reg : "") + "｜" + voice.name;
  }

  function listVoiceChoices(gender) {
    const zh = sortZh(gender === "all" ? "F" : gender);
    const choices = [];
    const seen = {};

    function pushChoice(c) {
      if (!c || !c.id || seen[c.id]) return;
      seen[c.id] = true;
      choices.push(c);
    }

    function addNative(v) {
      pushChoice(makeChoice(
        "native:" + (v.voiceURI || v.name),
        v,
        1,
        guessGender(v),
        nativeLabel(v),
        false
      ));
    }

    function addMaleEffects(bases) {
      bases.forEach(function (v) {
        const key = v.voiceURI || v.name;
        pushChoice(makeChoice(
          "effect-m:0.72:" + key,
          v,
          0.72,
          "M",
          "男聲效果・低沉｜" + v.name,
          true
        ));
        pushChoice(makeChoice(
          "effect-m:0.62:" + key,
          v,
          0.62,
          "M",
          "男聲效果・更低沉｜" + v.name,
          true
        ));
      });
    }

    function addFemaleEffects(bases) {
      bases.forEach(function (v) {
        const key = v.voiceURI || v.name;
        pushChoice(makeChoice(
          "effect-f:1.12:" + key,
          v,
          1.12,
          "F",
          "女聲效果・柔和｜" + v.name,
          true
        ));
      });
    }

    if (!zh.length) return choices;

    if (gender === "M") {
      zh.filter(function (v) { return guessGender(v) === "M"; }).forEach(addNative);
      zh.filter(function (v) { return guessGender(v) === "U"; }).forEach(addNative);
      // 多數手機／Safari 沒有真正中文男聲：一定提供男聲效果選項
      addMaleEffects(zh.slice(0, 10));
    } else if (gender === "F") {
      zh.filter(function (v) { return guessGender(v) === "F"; }).forEach(addNative);
      zh.filter(function (v) { return guessGender(v) === "U"; }).forEach(addNative);
      if (!choices.length) zh.forEach(addNative);
      addFemaleEffects(zh.slice(0, 4));
    } else {
      zh.forEach(addNative);
      addMaleEffects(zh.slice(0, 6));
      addFemaleEffects(zh.slice(0, 4));
    }

    return choices;
  }

  function resolveSelectedChoice() {
    const pref = loadTtsPref();
    const list = listVoiceChoices(pref.gender);
    if (!list.length) return null;
    if (pref.choiceId) {
      const byId = list.find(function (c) { return c.id === pref.choiceId; });
      if (byId) return byId;
    }
    if (pref.voiceURI || pref.voiceName) {
      const byVoice = list.find(function (c) {
        return (!c.synthetic) && (
          (pref.voiceURI && c.voice.voiceURI === pref.voiceURI) ||
          (pref.voiceName && c.voice.name === pref.voiceName)
        );
      });
      if (byVoice) return byVoice;
    }
    // 男聲偏好：優先真正男聲，否則第一個男聲效果
    if (pref.gender === "M") {
      return list.find(function (c) { return c.gender === "M" && !c.synthetic; })
        || list.find(function (c) { return c.synthetic && c.gender === "M"; })
        || list[0];
    }
    return list[0];
  }

  function resolveSelectedVoice() {
    const c = resolveSelectedChoice();
    return c ? c.voice : null;
  }

  function getSpeakSettings() {
    const c = resolveSelectedChoice();
    if (!c) {
      return { voice: null, pitch: 1, rate: 0.95, lang: "zh-TW" };
    }
    return {
      voice: c.voice,
      pitch: c.pitch || 1,
      rate: 0.95,
      lang: (c.voice && c.voice.lang) || "zh-TW",
      label: c.label,
      synthetic: c.synthetic
    };
  }

  function updateVoiceHint(gender, choices) {
    const hint = document.getElementById("ttsVoiceHint");
    if (!hint) return;
    const realMale = (choices || []).some(function (c) { return c.gender === "M" && !c.synthetic; });
    if (gender === "M" && !realMale) {
      hint.textContent = "此裝置沒有系統中文男聲，已提供「男聲效果・低沉」選項（以較低音調模擬）。可按試聽比較。";
    } else if (gender === "M") {
      hint.textContent = "已列出系統男聲；若想更低沉，也可選「男聲效果」。選擇會記在本機，與此站其他 App 共用。";
    } else {
      hint.textContent = "可選多種男聲／女聲；若裝置缺少某性別，會提供音調效果選項。選擇會記在本機共用。";
    }
  }

  function fillVoiceSelectors() {
    const genderEl = document.getElementById("ttsGender");
    const voiceEl = document.getElementById("ttsVoice");
    if (!genderEl || !voiceEl) return;
    const pref = loadTtsPref();
    genderEl.value = pref.gender || "F";
    const list = listVoiceChoices(genderEl.value);
    voiceEl.innerHTML = "";
    if (!list.length) {
      const opt = document.createElement("option");
      opt.value = "";
      opt.textContent = "（此裝置暫無中文語音，將用系統預設）";
      voiceEl.appendChild(opt);
      updateVoiceHint(genderEl.value, list);
      return;
    }
    list.forEach(function (c) {
      const opt = document.createElement("option");
      opt.value = c.id;
      opt.textContent = c.label;
      voiceEl.appendChild(opt);
    });
    const sel = resolveSelectedChoice();
    if (sel) voiceEl.value = sel.id;
    updateVoiceHint(genderEl.value, list);
  }

  function applyFromUI() {
    const genderEl = document.getElementById("ttsGender");
    const voiceEl = document.getElementById("ttsVoice");
    if (!genderEl || !voiceEl) return;
    const list = listVoiceChoices(genderEl.value);
    const chosen = list.find(function (c) { return c.id === voiceEl.value; }) || list[0] || null;
    saveTtsPref({
      gender: genderEl.value,
      choiceId: chosen ? chosen.id : "",
      voiceURI: chosen && chosen.voice ? (chosen.voice.voiceURI || "") : "",
      voiceName: chosen && chosen.voice ? chosen.voice.name : "",
      pitch: chosen ? chosen.pitch : 1
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
      pref.choiceId = "";
      pref.voiceURI = "";
      pref.voiceName = "";
      pref.pitch = 1;
      saveTtsPref(pref);
      fillVoiceSelectors();
      applyFromUI();
    });
    voiceEl.addEventListener("change", applyFromUI);

    if (previewBtn) {
      previewBtn.addEventListener("click", function () {
        applyFromUI();
        const settings = getSpeakSettings();
        const text = settings.synthetic
          ? "您好，這是男聲效果讀誦。以身心靈提升、靈命持續成長為首要。"
          : "您好，這是目前選擇的讀誦聲音。以身心靈提升、靈命持續成長為首要。";
        // 若選女聲效果，文案微調
        const say = (settings.synthetic && settings.pitch > 1)
          ? "您好，這是女聲效果讀誦。以身心靈提升、靈命持續成長為首要。"
          : text;
        if (options && typeof options.speak === "function") options.speak(say);
        else if (typeof global.speakText === "function") global.speakText(say);
      });
    }

    fillVoiceSelectors();
    if (global.speechSynthesis) {
      global.speechSynthesis.addEventListener("voiceschanged", function () {
        fillVoiceSelectors();
      });
      setTimeout(fillVoiceSelectors, 250);
      setTimeout(fillVoiceSelectors, 1000);
      setTimeout(fillVoiceSelectors, 2500);
    }
  }

  global.TtsVoices = {
    loadTtsPref: loadTtsPref,
    saveTtsPref: saveTtsPref,
    pickZhVoice: resolveSelectedVoice,
    resolveSelectedVoice: resolveSelectedVoice,
    resolveSelectedChoice: resolveSelectedChoice,
    getSpeakSettings: getSpeakSettings,
    fillVoiceSelectors: fillVoiceSelectors,
    bindVoicePicker: bindVoicePicker,
    listZhVoices: listZhVoices,
    listVoiceChoices: listVoiceChoices
  };
})(typeof window !== "undefined" ? window : this);
