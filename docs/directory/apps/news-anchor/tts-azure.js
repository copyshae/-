/* Azure Speech：viseme 對嘴 + Web Audio 播放（金鑰仅存本機） */
(function (global) {
  var PREF_KEY = "news-anchor-azure-v1";
  var speakSession = 0;
  var speakActive = false;
  var speakPaused = false;
  var speakChunks = [];
  var speakIndex = 0;
  var speakOptsActive = null;
  var statusListeners = [];
  var currentAudio = null;
  var audioCtx = null;
  var analyser = null;
  var ampRaf = null;
  var sdkPromise = null;

  var VISEME_OPEN = {
    0: 0.06, 1: 0.78, 2: 0.88, 3: 0.82, 4: 0.72, 5: 0.58,
    6: 0.48, 7: 0.52, 8: 0.76, 9: 0.86, 10: 0.8, 11: 0.84,
    12: 0.34, 13: 0.38, 14: 0.36, 15: 0.22, 16: 0.28, 17: 0.24,
    18: 0.18, 19: 0.14, 20: 0.18, 21: 0.1
  };

  var VOICES = {
    F: "zh-TW-HsiaoChenNeural",
    M: "zh-TW-YunJheNeural"
  };

  function loadPref() {
    try {
      var raw = localStorage.getItem(PREF_KEY);
      if (!raw) return { key: "", region: "eastasia", voiceF: VOICES.F, voiceM: VOICES.M };
      var p = JSON.parse(raw);
      return {
        key: p.key || "",
        region: p.region || "eastasia",
        voiceF: p.voiceF || VOICES.F,
        voiceM: p.voiceM || VOICES.M
      };
    } catch (e) {
      return { key: "", region: "eastasia", voiceF: VOICES.F, voiceM: VOICES.M };
    }
  }

  function savePref(pref) {
    try { localStorage.setItem(PREF_KEY, JSON.stringify(pref)); } catch (e) {}
  }

  function hasKey() {
    return !!loadPref().key;
  }

  function onSpeakStatus(fn) {
    if (typeof fn === "function") statusListeners.push(fn);
  }

  function notify(ev) {
    statusListeners.forEach(function (fn) {
      try { fn(ev); } catch (e) {}
    });
  }

  function visemeToOpen(id) {
    var n = VISEME_OPEN[id];
    return typeof n === "number" ? n : 0.35;
  }

  function loadSdk() {
    if (global.SpeechSDK) return Promise.resolve(global.SpeechSDK);
    if (sdkPromise) return sdkPromise;
    sdkPromise = new Promise(function (resolve, reject) {
      var s = document.createElement("script");
      s.src = "https://aka.ms/csspeech/jsbrowserpackageraw";
      s.async = true;
      s.onload = function () {
        if (global.SpeechSDK) resolve(global.SpeechSDK);
        else reject(new Error("Speech SDK 載入失敗"));
      };
      s.onerror = function () { reject(new Error("無法載入 Azure Speech SDK")); };
      document.head.appendChild(s);
    });
    return sdkPromise;
  }

  function splitChunks(text, maxLen) {
    if (global.TtsVoices && global.TtsVoices.splitSpeechChunks) {
      return global.TtsVoices.splitSpeechChunks(text, maxLen);
    }
    var t = String(text || "").trim();
    return t ? [t] : [];
  }

  function pickVoice(opts) {
    var pref = loadPref();
    var gender = (opts && opts.gender) || "F";
    return gender === "M" ? pref.voiceM : pref.voiceF;
  }

  function stopAmpLoop() {
    if (ampRaf) {
      cancelAnimationFrame(ampRaf);
      ampRaf = null;
    }
  }

  function startAmpLoop(sessionId) {
    stopAmpLoop();
    if (!analyser) return;
    var data = new Uint8Array(analyser.frequencyBinCount);
    function tick() {
      if (sessionId !== speakSession || !speakActive || speakPaused) return;
      analyser.getByteFrequencyData(data);
      var sum = 0;
      for (var i = 0; i < data.length; i++) sum += data[i];
      var avg = sum / (data.length * 255);
      notify({ reason: "amplitude", level: Math.min(1, avg * 2.8) });
      ampRaf = requestAnimationFrame(tick);
    }
    ampRaf = requestAnimationFrame(tick);
  }

  function stopAudio() {
    stopAmpLoop();
    if (currentAudio) {
      try {
        currentAudio.pause();
        currentAudio.removeAttribute("src");
        currentAudio.load();
      } catch (e) {}
      currentAudio = null;
    }
    if (audioCtx) {
      try { audioCtx.close(); } catch (e) {}
      audioCtx = null;
      analyser = null;
    }
  }

  function unlockAudio() {
    try {
      if (!audioCtx || audioCtx.state === "closed") {
        audioCtx = new (global.AudioContext || global.webkitAudioContext)();
      }
      if (audioCtx.state === "suspended") {
        audioCtx.resume().catch(function () {});
      }
      var buf = audioCtx.createBuffer(1, 1, 22050);
      var src = audioCtx.createBufferSource();
      src.buffer = buf;
      src.connect(audioCtx.destination);
      src.start(0);
    } catch (e) {}
  }

  function synthesizeChunk(text, voiceName, styleOpts) {
    return loadSdk().then(function (SDK) {
      var pref = loadPref();
      var config = SDK.SpeechConfig.fromSubscription(pref.key, pref.region);
      config.speechSynthesisVoiceName = voiceName;
      config.speechSynthesisOutputFormat = SDK.SpeechSynthesisOutputFormat.Audio24Khz96KBitRateMonoMp3;

      return new Promise(function (resolve, reject) {
        var synthesizer = new SDK.SpeechSynthesizer(config, null);
        var visemes = [];
        synthesizer.visemeReceived = function (_s, e) {
          var ms = e.audioOffset / 10000;
          visemes.push({ id: e.visemeId, ms: ms, open: visemeToOpen(e.visemeId) });
        };
        var rate = (styleOpts && styleOpts.rate) || 0.9;
        var pitch = (styleOpts && styleOpts.pitch) || 1;
        var ssml = "<speak version='1.0' xml:lang='zh-TW'>"
          + "<voice name='" + voiceName + "'>"
          + "<prosody rate='" + rate + "' pitch='" + (pitch >= 1 ? "+" : "") + Math.round((pitch - 1) * 100) + "%'>"
          + escapeXml(text)
          + "</prosody></voice></speak>";

        synthesizer.speakSsmlAsync(
          ssml,
          function (result) {
            synthesizer.close();
            if (result.reason === SDK.ResultReason.SynthesizingAudioCompleted) {
              resolve({ audio: result.audioData, visemes: visemes });
            } else {
              reject(new Error("Azure 語音合成失敗（" + result.reason + "）"));
            }
          },
          function (err) {
            synthesizer.close();
            reject(err);
          }
        );
      });
    });
  }

  function escapeXml(s) {
    return String(s || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function playChunk(audioData, visemes, sessionId) {
    return new Promise(function (resolve, reject) {
      if (sessionId !== speakSession) {
        resolve(false);
        return;
      }
      stopAudio();
      var blob = new Blob([audioData], { type: "audio/mpeg" });
      var url = URL.createObjectURL(blob);
      var audio = new Audio();
      currentAudio = audio;
      audio.preload = "auto";
      audio.src = url;

      var visemeTimers = [];
      function clearVisemeTimers() {
        visemeTimers.forEach(function (t) { clearTimeout(t); });
        visemeTimers = [];
      }

      audio.onended = function () {
        clearVisemeTimers();
        URL.revokeObjectURL(url);
        if (currentAudio === audio) currentAudio = null;
        resolve(true);
      };
      audio.onerror = function () {
        clearVisemeTimers();
        URL.revokeObjectURL(url);
        reject(new Error("音訊播放失敗"));
      };

      var useAnalyser = false;
      try {
        if (!audioCtx || audioCtx.state === "closed") {
          audioCtx = new (global.AudioContext || global.webkitAudioContext)();
        }
        analyser = audioCtx.createAnalyser();
        analyser.fftSize = 256;
        var source = audioCtx.createMediaElementSource(audio);
        source.connect(analyser);
        analyser.connect(audioCtx.destination);
        useAnalyser = true;
      } catch (e) {
        analyser = null;
      }

      visemes.forEach(function (v) {
        var timer = setTimeout(function () {
          if (sessionId !== speakSession || speakPaused) return;
          notify({ reason: "viseme", visemeId: v.id, openness: v.open, ms: v.ms });
        }, Math.max(0, v.ms));
        visemeTimers.push(timer);
      });

      function beginPlay() {
        var playPromise = audio.play();
        if (!playPromise || typeof playPromise.then !== "function") {
          if (useAnalyser) startAmpLoop(sessionId);
          return;
        }
        playPromise.then(function () {
          if (useAnalyser) startAmpLoop(sessionId);
        }).catch(reject);
      }

      if (audioCtx && audioCtx.state === "suspended") {
        audioCtx.resume().then(beginPlay).catch(beginPlay);
      } else {
        beginPlay();
      }
    });
  }

  function waitIfPaused(sessionId) {
    return new Promise(function (resolve) {
      function check() {
        if (sessionId !== speakSession) { resolve(false); return; }
        if (!speakPaused) { resolve(true); return; }
        setTimeout(check, 80);
      }
      check();
    });
  }

  function speakQueueAsync(sessionId) {
    if (sessionId !== speakSession) return Promise.resolve();
    if (speakIndex >= speakChunks.length) {
      speakActive = false;
      speakPaused = false;
      stopAudio();
      notify({ reason: "done" });
      return Promise.resolve();
    }
    if (speakPaused) {
      return waitIfPaused(sessionId).then(function (ok) {
        if (!ok || sessionId !== speakSession) return;
        return speakQueueAsync(sessionId);
      });
    }

    var chunk = speakChunks[speakIndex];
    var voice = pickVoice(speakOptsActive || {});
    notify({ reason: "speaking", index: speakIndex });

    return synthesizeChunk(chunk, voice, speakOptsActive || {})
      .then(function (res) {
        if (sessionId !== speakSession) return;
        return playChunk(res.audio, res.visemes, sessionId);
      })
      .then(function (played) {
        if (!played || sessionId !== speakSession) return;
        speakIndex += 1;
        notify({ reason: "progress", index: speakIndex });
        return speakQueueAsync(sessionId);
      })
      .catch(function (err) {
        if (sessionId !== speakSession) return;
        var failedAt = speakIndex;
        speakIndex += 1;
        notify({
          reason: failedAt === 0 ? "fatal" : "error",
          message: err && err.message ? err.message : String(err)
        });
        if (failedAt === 0) {
          speakActive = false;
          stopAudio();
          return;
        }
        return speakQueueAsync(sessionId);
      });
  }

  function stopSpeakQueue() {
    speakSession += 1;
    speakActive = false;
    speakPaused = false;
    speakChunks = [];
    speakIndex = 0;
    speakOptsActive = null;
    stopAudio();
    notify({ reason: "stop" });
  }

  function pauseSpeakQueue() {
    if (!speakActive || speakPaused) return;
    speakPaused = true;
    stopAmpLoop();
    if (currentAudio) {
      try { currentAudio.pause(); } catch (e) {}
    }
    notify({ reason: "pause" });
  }

  function resumeSpeakQueue() {
    if (!speakActive || !speakPaused) return;
    speakPaused = false;
    notify({ reason: "resume" });
    if (currentAudio) {
      try {
        currentAudio.play().then(function () {
          startAmpLoop(speakSession);
        }).catch(function () {});
        return;
      } catch (e) {}
    }
    speakQueueAsync(speakSession);
  }

  function togglePauseSpeakQueue() {
    if (!speakActive) return;
    if (speakPaused) resumeSpeakQueue();
    else pauseSpeakQueue();
  }

  function speakQueued(text, opts) {
    var pref = loadPref();
    if (!pref.key) {
      alert("請先在「Azure Speech（viseme 對嘴）」填寫金鑰與區域。");
      return false;
    }
    stopSpeakQueue();
    speakOptsActive = Object.assign({ gender: "F" }, opts || {});
    var maxLen = (opts && opts.maxLen) || 100;
    var chunks = splitChunks(text, maxLen);
    if (!chunks.length) return false;
    speakSession += 1;
    var sessionId = speakSession;
    speakChunks = chunks;
    speakIndex = 0;
    speakPaused = false;
    speakActive = true;
    notify({ reason: "start" });
    speakQueueAsync(sessionId);
    return true;
  }

  function getSpeakState() {
    return {
      active: speakActive,
      paused: speakPaused,
      index: speakIndex,
      total: speakChunks.length
    };
  }

  global.TtsAzure = {
    loadPref: loadPref,
    savePref: savePref,
    hasKey: hasKey,
    speakQueued: speakQueued,
    stopSpeakQueue: stopSpeakQueue,
    pauseSpeakQueue: pauseSpeakQueue,
    resumeSpeakQueue: resumeSpeakQueue,
    togglePauseSpeakQueue: togglePauseSpeakQueue,
    getSpeakState: getSpeakState,
    onSpeakStatus: onSpeakStatus,
    visemeToOpen: visemeToOpen,
    unlockAudio: unlockAudio
  };
})(typeof window !== "undefined" ? window : this);
