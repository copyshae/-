/**
 * 基金評估台｜進出場訊號引擎 + 追蹤名單
 */
(function () {
  "use strict";

  var STORAGE_KEY = "fund-eval-v2";
  var SETTINGS_KEY = "fund-eval-settings-v1";
  var ALERT_LOG_KEY = "fund-eval-alert-log-v1";

  var DEFAULT_SETTINGS = {
    buyHMax: 20,
    buyMaDevMax: -8,
    sellMaDevMin: 12,
    sellPrincipalMin: 40,
    sellPrincipalRise: 5,
    hySpreadWide: 550,
    hySpreadTight: 300,
    alertEnabled: true,
    alertEmail: "shaejanben@gmail.com",
    alertCooldownHours: 12
  };

  var ASSET_OPTIONS = ["台股ETF","海外股票ETF","債券ETF","高收益債","投資級債","新興債","股票型","平衡型","黃金／貴金屬","REITs","貨幣市場","其他"];
  var MACRO_KIND = [
    { id: "hy_spread", label: "非投等債信用利差（bp）" },
    { id: "ig_spread", label: "投資級債信用利差（bp）" },
    { id: "gold", label: "金價／關鍵阻力" },
    { id: "equity_idx", label: "股票指數位階" },
    { id: "other", label: "其他指標" }
  ];

  var WATCHLIST = [{"id":"wl-B09463","bankCode":"B09463","name":"貝萊德世界黃金A10 美元總報酬穩定配息","currency":"USD","assetClass":"黃金／貴金屬","instrumentType":"fund","divPolicy":"總報酬穩定配息","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"gold","macroName":"現貨金價 XAUUSD","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、最新淨值、52週高低、250日均線、配息組成（本金比）、一年含息報酬、金價關鍵阻力","note":"","updatedAt":0},{"id":"wl-B09086","bankCode":"B09086","name":"貝萊德世界黃金A2歐元","currency":"EUR","assetClass":"黃金／貴金屬","instrumentType":"fund","divPolicy":"累積／成長級別（確認）","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"gold","macroName":"現貨金價 XAUUSD","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、歐元計價淨值、52週位階、年線乖離、與美元級別折溢價／匯率影響","note":"","updatedAt":0},{"id":"wl-B09460","bankCode":"B09460","name":"貝萊德世界科技A10 美元總報酬穩定配息","currency":"USD","assetClass":"股票型","instrumentType":"fund","divPolicy":"總報酬穩定配息","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"equity_idx","macroName":"Nasdaq-100 / MSCI World IT","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、淨值與52週、250MA、配息本金比、科技指數位階與本益比","note":"","updatedAt":0},{"id":"wl-B38075","bankCode":"B38075","name":"百達-機器人科技-R 美元","currency":"USD","assetClass":"股票型","instrumentType":"fund","divPolicy":"累積（確認）","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"equity_idx","macroName":"機器人／自動化主題指數","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、淨值歷史、52週位階、年線、主題評價（PE／成長）","note":"","updatedAt":0},{"id":"wl-B15343","bankCode":"B15343","name":"富蘭克林坦伯頓-全球氣候變遷美元避險A(acc)H1","currency":"USD","assetClass":"股票型","instrumentType":"fund","divPolicy":"累積 acc／美元避險 H1","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"equity_idx","macroName":"MSCI World / 氣候主題指數","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、避險級別淨值、52週、年線、避險成本影響","note":"","updatedAt":0},{"id":"wl-B03629","bankCode":"B03629","name":"聯博-全球多元收益基金AD月配美元","currency":"USD","assetClass":"平衡型","instrumentType":"fund","divPolicy":"AD 月配","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"ig_spread","macroName":"全球股債風險偏好／IG 利差","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、月配金額、本金配息比、一年含息報酬、股債配置比重","note":"","updatedAt":0},{"id":"wl-B09325","bankCode":"B09325","name":"貝萊德全球智慧數據股票入息A6 美元穩定配息","currency":"USD","assetClass":"股票型","instrumentType":"fund","divPolicy":"A6 穩定配息","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"equity_idx","macroName":"MSCI World High Dividend","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、穩定配息本金比、淨值位階、全球高股息指數","note":"","updatedAt":0},{"id":"wl-B20073","bankCode":"B20073","name":"安聯收益成長AM穩定月收美元","currency":"USD","assetClass":"平衡型","instrumentType":"fund","divPolicy":"AM 穩定月收","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"hy_spread","macroName":"美高收利差＋可轉債／股票波動","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、月配、本金比趨勢、HY OAS、基金可轉債比重","note":"","updatedAt":0},{"id":"wl-A03088","bankCode":"A03088","name":"第一金全球水電瓦斯及基礎建設收益基金-台幣配息","currency":"TWD","assetClass":"股票型","instrumentType":"fund","divPolicy":"台幣配息","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"equity_idx","macroName":"全球基礎建設／公用事業指數","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、台幣淨值、配息本金比、利率敏感度、一年含息報酬","note":"","updatedAt":0},{"id":"wl-B33197","bankCode":"B33197","name":"高盛III邊境市場債券基金X股對沖級別澳幣(月配息)","currency":"AUD","assetClass":"新興債","instrumentType":"fund","divPolicy":"X 股對沖澳幣月配","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"hy_spread","macroName":"邊境／EM 主權利差","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、澳幣避險淨值、月配本金比、EMBI／邊境債利差、避險成本","note":"","updatedAt":0},{"id":"wl-B20186","bankCode":"B20186","name":"安聯收益成長AMg7月收總收益美元","currency":"USD","assetClass":"平衡型","instrumentType":"fund","divPolicy":"AMg7 月收總收益","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"hy_spread","macroName":"美高收利差＋權益波動","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、總收益配息組成、本金比、一年含息、HY OAS","note":"","updatedAt":0},{"id":"wl-A35062","bankCode":"A35062","name":"東方匯理新興市場非投資等級債券基金-AD月配台幣","currency":"TWD","assetClass":"高收益債","instrumentType":"fund","divPolicy":"AD 月配台幣","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"hy_spread","macroName":"EM HY／CEMBI 利差","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、台幣淨值、月配本金比、EM 非投等利差收斂／壓縮","note":"","updatedAt":0},{"id":"wl-B03563","bankCode":"B03563","name":"聯博-房貸收益基金AA穩定月配美元","currency":"USD","assetClass":"投資級債","instrumentType":"fund","divPolicy":"AA 穩定月配","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"ig_spread","macroName":"MBS／房貸信用利差＋美債殖利率","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、月配本金比、MBS 利差、存續期間、一年含息","note":"","updatedAt":0},{"id":"wl-A27035","bankCode":"A27035","name":"宏利新興市場非投資等級債券基金C(台幣)","currency":"TWD","assetClass":"高收益債","instrumentType":"fund","divPolicy":"C 台幣（確認配息或累積）","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"hy_spread","macroName":"EM HY 利差","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、淨值、配息政策確認、本金比、EM 利差","note":"","updatedAt":0},{"id":"wl-B23599","bankCode":"B23599","name":"施羅德環球-環球非投資等級債券美元A月配固定","currency":"USD","assetClass":"高收益債","instrumentType":"fund","divPolicy":"A 月配固定","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"hy_spread","macroName":"Bloomberg HY OAS / ICE BofA HY","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、固定月配本金侵蝕、利差位階、一年含息 vs 配息率落差","note":"","updatedAt":0},{"id":"wl-B33145","bankCode":"B33145","name":"高盛III新興市場債券基金X股對沖級別澳幣(月配息)","currency":"AUD","assetClass":"新興債","instrumentType":"fund","divPolicy":"X 股對沖澳幣月配","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"hy_spread","macroName":"EMBI／EM 主權利差","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、澳幣避險淨值、月配本金比、EM 利差、美元指數","note":"","updatedAt":0},{"id":"wl-A15015","bankCode":"A15015","name":"瑞銀全方位非投資等級債券基金(台幣)B月配","currency":"TWD","assetClass":"高收益債","instrumentType":"fund","divPolicy":"B 月配台幣","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"hy_spread","macroName":"全球 HY OAS","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、台幣淨值、月配本金比、HY 利差收斂／過度壓縮","note":"","updatedAt":0},{"id":"wl-B33173","bankCode":"B33173","name":"高盛III環球非投資等級債券基金X股對沖級別美元(月配息)","currency":"USD","assetClass":"高收益債","instrumentType":"fund","divPolicy":"X 股對沖美元月配","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"hy_spread","macroName":"Bloomberg Global HY OAS","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、美元對沖淨值、月配本金比、全球 HY 利差","note":"","updatedAt":0},{"id":"wl-B33060","bankCode":"B33060","name":"高盛III環球非投資等級債券基金X股對沖級別歐元(月配息)","currency":"EUR","assetClass":"高收益債","instrumentType":"fund","divPolicy":"X 股對沖歐元月配","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"hy_spread","macroName":"歐洲／全球 HY 利差","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"ISIN、歐元對沖淨值、月配本金比、歐元區 HY 利差、避險成本","note":"","updatedAt":0},{"id":"wl-0052","bankCode":"0052","name":"富邦科技（台股ETF｜臺灣資訊科技指數）","currency":"TWD","assetClass":"台股ETF","instrumentType":"etf","divPolicy":"ETF 收益分配（非境外基金穩定配息）","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"equity_idx","macroName":"臺灣資訊科技指數／台股電子","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"市價、淨值、折溢價%、52週高低、250日均線、追蹤誤差、成交量、殖利率；對照台積電／電子指數位階","note":"","updatedAt":0},{"id":"wl-00747","bankCode":"00747","name":"00747（你指定之美股相關ETF｜請核對代號；若為00747B則是FH中國政策債）","currency":"TWD","assetClass":"海外股票ETF","instrumentType":"etf","divPolicy":"ETF 收益分配（請確認）","isin":"","navDate":"","nav":null,"high52":null,"low52":null,"ma250":null,"premiumPct":null,"divPerUnit":null,"yieldAnn":null,"principalPct":null,"prevPrincipalPct":null,"totalReturn1y":null,"macroKind":"equity_idx","macroName":"Nasdaq-100／S&P 500（美股）","macroValue":null,"macroNote":"","goldBreak":false,"searchHints":"請先確認證交所代號與追蹤指數；市價、淨值、折溢價、52週位階、250MA、成交量、追蹤誤差","note":"","updatedAt":0}];

  function blankFromWatch(w) {
    return Object.assign({}, w);
  }

  function defaultFunds() {
    return WATCHLIST.map(blankFromWatch);
  }

  function loadSettings() {
    try {
      var raw = localStorage.getItem(SETTINGS_KEY);
      if (!raw) return Object.assign({}, DEFAULT_SETTINGS);
      return Object.assign({}, DEFAULT_SETTINGS, JSON.parse(raw));
    } catch (e) {
      return Object.assign({}, DEFAULT_SETTINGS);
    }
  }

  function saveSettings(s) {
    localStorage.setItem(SETTINGS_KEY, JSON.stringify(s));
  }

  function loadFunds() {
    try {
      var raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) {
        var init = defaultFunds();
        localStorage.setItem(STORAGE_KEY, JSON.stringify(init));
        return init;
      }
      var list = JSON.parse(raw);
      return Array.isArray(list) ? list : defaultFunds();
    } catch (e) {
      return defaultFunds();
    }
  }

  function saveFunds(list) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
  }

  /** 只補缺漏代碼，不覆蓋已填數值 */
  function syncWatchlist(existing) {
    var byCode = {};
    existing.forEach(function (f) {
      if (f.bankCode) byCode[String(f.bankCode).toUpperCase()] = f;
    });
    var out = existing.slice();
    var added = 0;
    WATCHLIST.forEach(function (w) {
      var key = String(w.bankCode).toUpperCase();
      if (!byCode[key]) {
        out.push(blankFromWatch(w));
        added++;
      }
    });
    return { list: out, added: added };
  }

  function num(v) {
    if (v === "" || v === null || v === undefined) return null;
    var n = Number(v);
    return Number.isFinite(n) ? n : null;
  }

  function calcPosition52(nav, high52, low52) {
    var e = num(nav), f = num(high52), g = num(low52);
    if (e === null || f === null || g === null || f <= g) return null;
    return ((e - g) / (f - g)) * 100;
  }

  function calcMaDev(nav, ma250) {
    var e = num(nav), ma = num(ma250);
    if (e === null || ma === null || ma === 0) return null;
    return ((e - ma) / ma) * 100;
  }

  /** 僅 0052／00747（或手動標 etf）走 ETF 邏輯；其餘基金照舊 */
  function isEtf(fund) {
    if (!fund) return false;
    if (fund.instrumentType === "etf") return true;
    var c = String(fund.bankCode || "").toUpperCase().replace(/\s/g, "");
    return c === "0052" || c === "00747" || c === "00747B";
  }

  function dataCompleteness(fund) {
    var need = [];
    if (num(fund.nav) === null) need.push(isEtf(fund) ? "最新市價／淨值" : "最新淨值");
    if (num(fund.high52) === null) need.push("52週高");
    if (num(fund.low52) === null) need.push("52週低");
    if (num(fund.ma250) === null) need.push("250MA");

    if (isEtf(fund)) {
      // ETF：不看境外基金「本金配息」；改看折溢價與指數位階
      if (num(fund.premiumPct) === null) need.push("折溢價%");
      if (num(fund.macroValue) === null) need.push("追蹤指數數值／位階");
      if (num(fund.totalReturn1y) === null) need.push("近一年報酬%");
      var total = 7;
      var filled = total - need.length;
      if (filled < 0) filled = 0;
      return { need: need, filled: filled, total: total, ready: need.length === 0, mode: "etf" };
    }

    var isDist = /配息|月配|月收|穩定配/.test(String(fund.divPolicy || fund.name || ""));
    if (isDist) {
      if (num(fund.principalPct) === null) need.push("本金配息比");
      if (num(fund.yieldAnn) === null) need.push("年化配息率");
      if (num(fund.totalReturn1y) === null) need.push("一年含息報酬");
    }
    if (num(fund.macroValue) === null && !fund.goldBreak) need.push("總經指標數值");
    var totalF = isDist ? 8 : 5;
    var filledF = totalF - need.length;
    if (filledF < 0) filledF = 0;
    return { need: need, filled: filledF, total: totalF, ready: need.length === 0, mode: "fund" };
  }

  function evaluate(fund, settings) {
    var s = settings || loadSettings();
    var H = calcPosition52(fund.nav, fund.high52, fund.low52);
    var I = calcMaDev(fund.nav, fund.ma250);
    var L = num(fund.principalPct);
    var prevL = num(fund.prevPrincipalPct);
    var macroVal = num(fund.macroValue);
    var premium = num(fund.premiumPct);
    var buyReasons = [], sellReasons = [];
    var comp = dataCompleteness(fund);
    var etf = isEtf(fund);

    if (H !== null && H <= s.buyHMax) {
      buyReasons.push("52 週位階 " + fmt1(H) + "%（後 " + s.buyHMax + "% 買區）");
    }
    if (I !== null && I <= s.buyMaDevMax) {
      buyReasons.push("年線負乖離 " + fmt1(I) + "%（≤ " + s.buyMaDevMax + "%）");
    }

    if (etf) {
      // ETF 專用：折溢價（不套用本金配息／HY 利差基金規則）
      if (premium !== null && premium <= -1) {
        buyReasons.push("相對淨值折價 " + fmt1(premium) + "%（較具進場空間）");
      }
      if (premium !== null && premium >= 1.5) {
        sellReasons.push("相對淨值溢價 " + fmt1(premium) + "%（追價風險偏高）");
      }
      if (I !== null && I >= s.sellMaDevMin) {
        sellReasons.push("年線正乖離 " + fmt1(I) + "%（≥ " + s.sellMaDevMin + "%）");
      }
      // 指數位階備註關鍵字
      if (fund.macroNote && /超賣|低檔|回測支撐|突破整理/.test(String(fund.macroNote))) {
        buyReasons.push("指數面：" + String(fund.macroNote).slice(0, 40));
      }
      if (fund.macroNote && /過熱|新高追價|乖離過大/.test(String(fund.macroNote))) {
        sellReasons.push("指數面：" + String(fund.macroNote).slice(0, 40));
      }
    } else {
      if (fund.goldBreak) buyReasons.push("金價突破關鍵阻力");
      if (fund.macroKind === "hy_spread" && macroVal !== null) {
        if (macroVal >= s.hySpreadTight && macroVal <= s.hySpreadWide + 80 && fund.macroNote) {
          if (/收斂|收窄|回落|下降|收緊/.test(String(fund.macroNote))) {
            buyReasons.push("信用利差開始收斂（目前 " + Math.round(macroVal) + " bp）");
          }
        }
        if (macroVal < s.hySpreadTight) {
          sellReasons.push("非投等債利差過度壓縮（" + Math.round(macroVal) + " bp ＜ " + s.hySpreadTight + "）");
        }
      }
      if (fund.macroKind === "ig_spread" && macroVal !== null && macroVal < 80) {
        sellReasons.push("投資級利差偏緊（" + Math.round(macroVal) + " bp），風險溢酬不足");
      }
      if (I !== null && I >= s.sellMaDevMin) {
        sellReasons.push("年線正乖離 " + fmt1(I) + "%（≥ " + s.sellMaDevMin + "%）");
      }
      if (L !== null && L >= s.sellPrincipalMin) {
        sellReasons.push("配息來自本金 " + fmt1(L) + "%（≥ " + s.sellPrincipalMin + "%）");
      }
      if (L !== null && prevL !== null && L - prevL >= s.sellPrincipalRise) {
        sellReasons.push("本金配息比例較上次再升 " + fmt1(L - prevL) + " 百分點（持續攀升）");
      }
    }

    var status;
    if (!comp.ready && !buyReasons.length && !sellReasons.length) status = "待補資料";
    else if (sellReasons.length) status = "減碼警戒";
    else if (buyReasons.length) status = "加碼";
    else status = etf ? "續抱觀察" : "續抱領息";

    var score = investScore({
      H: H, I: I, L: L, prevL: prevL, macroVal: macroVal, premium: premium,
      buyReasons: buyReasons, sellReasons: sellReasons,
      status: status, comp: comp, fund: fund, settings: s, etf: etf
    });

    return {
      H: H, I: I, status: status,
      buyReasons: buyReasons, sellReasons: sellReasons,
      comp: comp, score: score, etf: etf, premium: premium
    };
  }

  /**
   * 最值得投資分數（越高越優先）：買訊＋低位階＋負乖離＋配息品質＋利差空間
   * 減碼／本金侵蝕／利差過緊會大幅扣分
   */
  function investScore(x) {
    var score = 50;
    var f = x.fund;
    var s = x.settings;
    var etf = !!x.etf;

    if (x.status === "加碼") score += 35;
    else if (x.status === "續抱領息" || x.status === "續抱觀察") score += 12;
    else if (x.status === "待補資料") score -= 8;
    else if (x.status === "減碼警戒") score -= 40;

    score += x.buyReasons.length * 10;
    score -= x.sellReasons.length * 14;

    if (x.H !== null) {
      score += (50 - x.H) * 0.35;
      if (x.H <= s.buyHMax) score += 8;
    }
    if (x.I !== null) {
      score += (-x.I) * 0.55;
      if (x.I <= s.buyMaDevMax) score += 6;
      if (x.I >= s.sellMaDevMin) score -= 10;
    }

    if (etf) {
      // ETF：折溢價取代本金配息品質
      if (x.premium !== null) {
        score += (-x.premium) * 4; // 折價加分、溢價扣分
        if (x.premium >= 1.5) score -= 10;
        if (x.premium <= -1) score += 6;
      }
      var tr = num(f.totalReturn1y);
      if (tr !== null) score += Math.max(-8, Math.min(8, tr * 0.15));
    } else {
      if (x.L !== null) {
        score += (40 - x.L) * 0.25;
        if (x.L >= s.sellPrincipalMin) score -= 12;
      }
      if (x.L !== null && x.prevL !== null && x.L > x.prevL) {
        score -= Math.min(15, (x.L - x.prevL) * 1.2);
      }
      var yld = num(f.yieldAnn);
      var tr2 = num(f.totalReturn1y);
      if (yld !== null && tr2 !== null) {
        score += Math.max(-10, Math.min(10, (tr2 - yld * 0.5) * 0.4));
      } else if (yld !== null && yld > 0 && x.L !== null && x.L < 25) {
        score += 3;
      }
      if (f.macroKind === "hy_spread" && x.macroVal !== null) {
        if (x.macroVal < s.hySpreadTight) score -= 18;
        else if (x.macroVal >= s.hySpreadWide) score += 6;
        else score += 3;
        if (f.macroNote && /收斂|收窄|回落|下降|收緊/.test(String(f.macroNote))) score += 5;
      }
      if (f.goldBreak) score += 8;
    }

    score += x.comp.filled * 1.5;
    if (!x.comp.ready) score -= 5;
    return Math.round(score * 10) / 10;
  }

  function fmt1(n) {
    if (n === null || n === undefined || !Number.isFinite(n)) return "—";
    return (Math.round(n * 10) / 10).toFixed(1);
  }
  function fmt2(n) {
    if (n === null || n === undefined || !Number.isFinite(n)) return "—";
    return (Math.round(n * 100) / 100).toFixed(2);
  }
  function uid() {
    return "f-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 7);
  }
  function statusClass(st) {
    if (st === "加碼") return "st-buy";
    if (st === "減碼警戒") return "st-sell";
    if (st === "待補資料") return "st-need";
    return "st-hold";
  }

  var state = { funds: loadFunds(), settings: loadSettings(), filter: "all", editingId: null };
  function $(id) { return document.getElementById(id); }

  function renderSummary() {
    var buy = 0, sell = 0, hold = 0, need = 0;
    state.funds.forEach(function (f) {
      var st = evaluate(f, state.settings).status;
      if (st === "加碼") buy++;
      else if (st === "減碼警戒") sell++;
      else if (st === "待補資料") need++;
      else hold++;
    });
    $("sumBuy").textContent = String(buy);
    $("sumSell").textContent = String(sell);
    $("sumHold").textContent = String(hold);
    $("sumTotal").textContent = String(state.funds.length);
    if ($("sumNeed")) $("sumNeed").textContent = String(need);
  }

  function filteredFunds() {
    return state.funds.map(function (f) {
      return { fund: f, ev: evaluate(f, state.settings) };
    }).filter(function (row) {
      if (state.filter === "buy") return row.ev.status === "加碼";
      if (state.filter === "sell") return row.ev.status === "減碼警戒";
      if (state.filter === "hold") return row.ev.status === "續抱領息" || row.ev.status === "續抱觀察";
      if (state.filter === "need") return row.ev.status === "待補資料";
      return true;
    }).sort(function (a, b) {
      // 最值得投資：分數高 → 上；同分再比位階低、代碼
      var sa = a.ev.score != null ? a.ev.score : -999;
      var sb = b.ev.score != null ? b.ev.score : -999;
      if (sb !== sa) return sb - sa;
      var ha = a.ev.H != null ? a.ev.H : 999;
      var hb = b.ev.H != null ? b.ev.H : 999;
      if (ha !== hb) return ha - hb;
      return String(a.fund.bankCode || "").localeCompare(String(b.fund.bankCode || ""));
    });
  }

  function renderList() {
    var box = $("list");
    var rows = filteredFunds();
    if (!rows.length) {
      box.innerHTML = '<p class="empty">目前沒有符合篩選的基金。</p>';
      return;
    }
    box.innerHTML = rows.map(function (row, idx) {
      var f = row.fund, ev = row.ev;
      var reasons = "";
      if (ev.buyReasons.length) {
        reasons += '<ul class="reasons buy">' + ev.buyReasons.map(function (r) { return "<li>" + escapeHtml(r) + "</li>"; }).join("") + "</ul>";
      }
      if (ev.sellReasons.length) {
        reasons += '<ul class="reasons sell">' + ev.sellReasons.map(function (r) { return "<li>" + escapeHtml(r) + "</li>"; }).join("") + "</ul>";
      }
      if (!ev.buyReasons.length && !ev.sellReasons.length) {
        if (ev.status === "待補資料") {
          reasons = '<p class="muted-line">待補：' + escapeHtml(ev.comp.need.join("、")) +
            (f.searchHints ? '<br/>搜尋重點：' + escapeHtml(f.searchHints) : "") + "</p>";
        } else {
          reasons = '<p class="muted-line">無強烈進出場訊號：適合續抱檢視。</p>';
        }
      }
      return (
        '<article class="fund-card ' + statusClass(ev.status) + '" data-id="' + escapeHtml(f.id) + '">' +
        '<header class="fc-head"><div>' +
        '<span class="rank" title="最值得投資排序">#' + (idx + 1) + "</span> " +
        '<span class="bank">' + escapeHtml(f.bankCode || "—") + "</span> " +
        '<strong class="fname">' + escapeHtml(f.name || "未命名") + "</strong>" +
        '<div class="meta">' + escapeHtml(f.currency || "") + " · " + escapeHtml(f.assetClass || "") +
        (ev.etf ? " · ETF分析" : "") + (f.divPolicy ? " · " + escapeHtml(f.divPolicy) : "") +
        " · 資料 " + ev.comp.filled + "/" + ev.comp.total +
        " · 投資分數 " + (ev.score != null ? ev.score : "—") + "</div></div>" +
        '<span class="badge ' + statusClass(ev.status) + '">' + escapeHtml(ev.status) + "</span></header>" +
        '<div class="metrics">' +
        '<div><span class="k">淨值</span><span class="v">' + fmt2(num(f.nav)) + "</span></div>" +
        '<div><span class="k">52週位階</span><span class="v">' + fmt1(ev.H) + "%</span></div>" +
        '<div><span class="k">年線偏離</span><span class="v">' + fmt1(ev.I) + "%</span></div>" +
        '<div><span class="k">' + (ev.etf ? "折溢價" : "本金配息") + '</span><span class="v">' +
        (ev.etf ? fmt1(num(f.premiumPct)) : fmt1(num(f.principalPct))) + "%</span></div>" +
        '<div><span class="k">年化配息</span><span class="v">' + fmt1(num(f.yieldAnn)) + "%</span></div>" +
        '<div><span class="k">一年含息</span><span class="v">' + fmt1(num(f.totalReturn1y)) + "%</span></div>" +
        "</div>" +
        '<div class="macro-line">' + escapeHtml(macroLabel(f.macroKind)) + "：" +
        escapeHtml(f.macroName || "—") + "　" +
        escapeHtml(f.macroValue != null ? String(f.macroValue) : "—") +
        (f.macroNote ? "｜" + escapeHtml(f.macroNote) : "") + "</div>" +
        reasons +
        '<div class="fc-actions">' +
        '<button type="button" class="fbtn primary" data-act="research">自動搜尋</button>' +
        '<button type="button" class="fbtn" data-act="edit">填寫／編輯</button>' +
        '<button type="button" class="fbtn danger" data-act="del">刪除</button></div></article>'
      );
    }).join("");
  }

  function macroLabel(id) {
    for (var i = 0; i < MACRO_KIND.length; i++) if (MACRO_KIND[i].id === id) return MACRO_KIND[i].label;
    return "連動指標";
  }
  function escapeHtml(s) {
    return String(s == null ? "" : s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;");
  }
  function refresh() {
    renderSummary();
    renderList();
    scheduleSignalAlerts();
  }

  var alertTimer = null;
  function scheduleSignalAlerts() {
    if (alertTimer) clearTimeout(alertTimer);
    alertTimer = setTimeout(function () {
      checkAndNotifySignals(false);
    }, 600);
  }

  function loadAlertLog() {
    try {
      var raw = localStorage.getItem(ALERT_LOG_KEY);
      return raw ? JSON.parse(raw) : {};
    } catch (e) {
      return {};
    }
  }

  function saveAlertLog(log) {
    localStorage.setItem(ALERT_LOG_KEY, JSON.stringify(log));
  }

  function buildAlertMessage(fund, ev) {
    var kind = ev.status === "加碼" ? "買點（加碼）" : "賣點／減碼警戒";
    var lines = [
      "【基金評估台】" + kind,
      "",
      "代碼：" + (fund.bankCode || "—"),
      "名稱：" + (fund.name || "—"),
      "幣別／類別：" + (fund.currency || "") + " / " + (fund.assetClass || ""),
      "評估狀態：" + ev.status,
      "投資分數：" + (ev.score != null ? ev.score : "—"),
      "52週位階：" + fmt1(ev.H) + "%",
      "年線偏離：" + fmt1(ev.I) + "%",
      "本金配息：" + fmt1(num(fund.principalPct)) + "%",
      "淨值：" + fmt2(num(fund.nav)),
      ""
    ];
    if (ev.buyReasons.length) {
      lines.push("買訊：");
      ev.buyReasons.forEach(function (r) { lines.push("- " + r); });
    }
    if (ev.sellReasons.length) {
      lines.push("賣訊：");
      ev.sellReasons.forEach(function (r) { lines.push("- " + r); });
    }
    lines.push("");
    lines.push("時間：" + new Date().toLocaleString("zh-TW", { hour12: false }));
    lines.push("開啟：https://copyshae.github.io/-/fund-eval/");
    return lines.join("\n");
  }

  function sendEmailAlert(subject, message, email) {
    var to = (email || "").trim() || DEFAULT_SETTINGS.alertEmail;
    // FormSubmit：瀏覽器直接寄出；首次使用該信箱需點確認信
    return fetch("https://formsubmit.co/ajax/" + encodeURIComponent(to), {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json"
      },
      body: JSON.stringify({
        _subject: subject,
        _template: "box",
        _captcha: "false",
        name: "基金評估台",
        email: to,
        message: message
      })
    }).then(function (res) {
      if (!res.ok) throw new Error("HTTP " + res.status);
      return res.json().catch(function () { return { ok: true }; });
    });
  }

  function maybeBrowserNotify(title, body) {
    try {
      if (!("Notification" in window)) return;
      if (Notification.permission === "granted") {
        new Notification(title, { body: body, icon: "./icon-192.png" });
      } else if (Notification.permission !== "denied") {
        Notification.requestPermission().then(function (p) {
          if (p === "granted") new Notification(title, { body: body, icon: "./icon-192.png" });
        });
      }
    } catch (e) {}
  }

  /**
   * 掃清單：出現買點（加碼）或賣點（減碼警戒）就寄信
   * @param {boolean} force 測試／手動：忽略冷卻並可寄摘要
   */
  function checkAndNotifySignals(force) {
    var s = state.settings;
    if (!s.alertEnabled && !force) return Promise.resolve({ sent: 0, skipped: 0 });

    var email = (s.alertEmail || DEFAULT_SETTINGS.alertEmail).trim();
    var cooldownMs = (num(s.alertCooldownHours) != null ? num(s.alertCooldownHours) : 12) * 3600 * 1000;
    var log = loadAlertLog();
    var now = Date.now();
    var jobs = [];
    var sent = 0;
    var skipped = 0;

    state.funds.forEach(function (f) {
      var ev = evaluate(f, s);
      if (ev.status !== "加碼" && ev.status !== "減碼警戒") return;

      var key = f.id || f.bankCode;
      var prev = log[key];
      if (!force && prev && prev.status === ev.status && now - (prev.at || 0) < cooldownMs) {
        skipped++;
        return;
      }

      var kind = ev.status === "加碼" ? "買點" : "賣點";
      var subject = "【基金評估台】" + kind + "｜" + (f.bankCode || "") + " " + (f.name || "");
      var message = buildAlertMessage(f, ev);
      jobs.push(
        sendEmailAlert(subject, message, email)
          .then(function () {
            sent++;
            log[key] = { status: ev.status, at: now, score: ev.score };
            maybeBrowserNotify(subject, (f.name || "") + "｜分數 " + (ev.score != null ? ev.score : "—"));
          })
          .catch(function (err) {
            console.warn("寄信失敗", f.bankCode, err);
            // 失敗時改開 mailto 備援（使用者可手動傳送）
            if (force) {
              var mailto =
                "mailto:" +
                encodeURIComponent(email) +
                "?subject=" +
                encodeURIComponent(subject) +
                "&body=" +
                encodeURIComponent(message);
              window.open(mailto, "_blank");
            }
          })
      );
    });

    if (!jobs.length && force) {
      // 手動測試：目前無買賣點也寄一封狀態摘要
      var summaryLines = ["【基金評估台】訊號檢查（目前無新的買／賣點）", "", "全部：" + state.funds.length + " 檔"];
      state.funds.slice(0, 8).forEach(function (f) {
        var ev = evaluate(f, s);
        summaryLines.push((f.bankCode || "") + "｜" + ev.status + "｜分數 " + (ev.score != null ? ev.score : "—"));
      });
      summaryLines.push("", "時間：" + new Date().toLocaleString("zh-TW", { hour12: false }));
      jobs.push(
        sendEmailAlert("【基金評估台】測試寄信／無新訊號", summaryLines.join("\n"), email)
          .then(function () { sent++; })
          .catch(function () {
            window.open(
              "mailto:" + encodeURIComponent(email) +
              "?subject=" + encodeURIComponent("【基金評估台】測試寄信") +
              "&body=" + encodeURIComponent(summaryLines.join("\n")),
              "_blank"
            );
          })
      );
    }

    return Promise.all(jobs).then(function () {
      saveAlertLog(log);
      return { sent: sent, skipped: skipped };
    });
  }

  function openForm(fund) {
    state.editingId = fund ? fund.id : null;
    $("formTitle").textContent = fund ? "編輯／補資料" : "新增基金";
    $("f_bankCode").value = fund ? fund.bankCode || "" : "";
    $("f_name").value = fund ? fund.name || "" : "";
    $("f_currency").value = fund ? fund.currency || "TWD" : "TWD";
    $("f_assetClass").value = fund ? fund.assetClass || "高收益債" : "高收益債";
    $("f_divPolicy").value = fund ? fund.divPolicy || "" : "";
    if ($("f_instrumentType")) $("f_instrumentType").value = fund ? (fund.instrumentType || (isEtf(fund) ? "etf" : "fund")) : "fund";
    if ($("f_premiumPct")) $("f_premiumPct").value = fund && fund.premiumPct != null ? fund.premiumPct : "";
    toggleFormMode();
    $("f_isin").value = fund ? fund.isin || "" : "";
    $("f_navDate").value = fund ? fund.navDate || "" : "";
    $("f_nav").value = fund && fund.nav != null ? fund.nav : "";
    $("f_high52").value = fund && fund.high52 != null ? fund.high52 : "";
    $("f_low52").value = fund && fund.low52 != null ? fund.low52 : "";
    $("f_ma250").value = fund && fund.ma250 != null ? fund.ma250 : "";
    $("f_divPerUnit").value = fund && fund.divPerUnit != null ? fund.divPerUnit : "";
    $("f_yieldAnn").value = fund && fund.yieldAnn != null ? fund.yieldAnn : "";
    $("f_principalPct").value = fund && fund.principalPct != null ? fund.principalPct : "";
    $("f_prevPrincipalPct").value = fund && fund.prevPrincipalPct != null ? fund.prevPrincipalPct : "";
    $("f_totalReturn1y").value = fund && fund.totalReturn1y != null ? fund.totalReturn1y : "";
    $("f_macroKind").value = fund ? fund.macroKind || "other" : "hy_spread";
    $("f_macroName").value = fund ? fund.macroName || "" : "";
    $("f_macroValue").value = fund && fund.macroValue != null ? fund.macroValue : "";
    $("f_macroNote").value = fund ? fund.macroNote || "" : "";
    $("f_goldBreak").checked = !!(fund && fund.goldBreak);
    $("f_searchHints").value = fund ? fund.searchHints || "" : "";
    $("f_note").value = fund ? fund.note || "" : "";
    updateLivePreview();
    $("formPanel").classList.add("on");
    $("formPanel").scrollIntoView({ behavior: "smooth", block: "start" });
  }

  function closeForm() {
    state.editingId = null;
    $("formPanel").classList.remove("on");
  }

  function readForm() {
    return {
      bankCode: $("f_bankCode").value.trim(),
      name: $("f_name").value.trim(),
      currency: $("f_currency").value.trim() || "TWD",
      assetClass: $("f_assetClass").value,
      instrumentType: $("f_instrumentType") ? $("f_instrumentType").value : "fund",
      divPolicy: $("f_divPolicy").value.trim(),
      premiumPct: $("f_premiumPct") ? num($("f_premiumPct").value) : null,
      isin: $("f_isin").value.trim(),
      navDate: $("f_navDate").value.trim(),
      nav: num($("f_nav").value),
      high52: num($("f_high52").value),
      low52: num($("f_low52").value),
      ma250: num($("f_ma250").value),
      divPerUnit: num($("f_divPerUnit").value),
      yieldAnn: num($("f_yieldAnn").value),
      principalPct: num($("f_principalPct").value),
      prevPrincipalPct: num($("f_prevPrincipalPct").value),
      totalReturn1y: num($("f_totalReturn1y").value),
      macroKind: $("f_macroKind").value,
      macroName: $("f_macroName").value.trim(),
      macroValue: num($("f_macroValue").value),
      macroNote: $("f_macroNote").value.trim(),
      goldBreak: $("f_goldBreak").checked,
      searchHints: $("f_searchHints").value.trim(),
      note: $("f_note").value.trim(),
      updatedAt: Date.now()
    };
  }

  function updateLivePreview() {
    var draft = readForm();
    var ev = evaluate(draft, state.settings);
    $("liveH").textContent = fmt1(ev.H) + "%";
    $("liveI").textContent = fmt1(ev.I) + "%";
    $("liveStatus").textContent = ev.status;
    $("liveStatus").className = "live-st " + statusClass(ev.status);
    var lines = ev.buyReasons.concat(ev.sellReasons);
    if (!lines.length && ev.comp.need.length) lines = ["待補：" + ev.comp.need.join("、")];
    $("liveReasons").textContent = lines.length ? lines.join("；") : "尚無明確訊號";
  }

  function saveForm() {
    var data = readForm();
    if (!data.name) { alert("請填寫基金名稱"); return; }
    if (state.editingId) {
      state.funds = state.funds.map(function (f) {
        if (f.id !== state.editingId) return f;
        var next = Object.assign({}, f, data, { id: f.id });
        if (f.principalPct != null && data.principalPct != null && data.principalPct !== f.principalPct &&
            (data.prevPrincipalPct === null || data.prevPrincipalPct === f.prevPrincipalPct)) {
          next.prevPrincipalPct = f.principalPct;
        }
        return next;
      });
    } else {
      data.id = uid();
      state.funds.unshift(data);
    }
    saveFunds(state.funds);
    closeForm();
    refresh();
  }

  function deleteFund(id) {
    if (!confirm("確定刪除此基金？")) return;
    state.funds = state.funds.filter(function (f) { return f.id !== id; });
    saveFunds(state.funds);
    refresh();
  }

  function exportCsv() {
    var header = ["銀行代碼","基金名稱","ISIN","計價幣別","資產類別","配息政策","淨值日期","最新淨值","52週高","52週低","52週位階(%)","年線偏離(%)","每單位配息","年化配息率(%)","配息來自本金(%)","近一年含息總報酬(%)","連動指標","指標數值","評估狀態","待補欄位"];
    var lines = [header.join(",")];
    state.funds.forEach(function (f) {
      var ev = evaluate(f, state.settings);
      lines.push([
        csv(f.bankCode), csv(f.name), csv(f.isin), csv(f.currency), csv(f.assetClass), csv(f.divPolicy),
        csv(f.navDate), f.nav, f.high52, f.low52, fmt1(ev.H), fmt1(ev.I),
        f.divPerUnit, f.yieldAnn, f.principalPct, f.totalReturn1y,
        csv((f.macroName || "") + "/" + (f.macroKind || "")), f.macroValue, csv(ev.status), csv(ev.comp.need.join("|"))
      ].join(","));
    });
    var blob = new Blob(["\ufeff" + lines.join("\n")], { type: "text/csv;charset=utf-8" });
    var a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = "fund-eval-" + new Date().toISOString().slice(0, 10) + ".csv";
    a.click();
    URL.revokeObjectURL(a.href);
  }

  function csv(v) {
    var s = v == null ? "" : String(v);
    if (/[",\n]/.test(s)) return '"' + s.replace(/"/g, '""') + '"';
    return s;
  }

  function fillAssetSelect() {
    $("f_assetClass").innerHTML = ASSET_OPTIONS.map(function (o) {
      return '<option value="' + o + '">' + o + "</option>";
    }).join("");
  }
  function fillMacroSelect() {
    $("f_macroKind").innerHTML = MACRO_KIND.map(function (o) {
      return '<option value="' + o.id + '">' + o.label + "</option>";
    }).join("");
  }
  function loadSettingsForm() {
    var s = state.settings;
    $("s_buyHMax").value = s.buyHMax;
    $("s_buyMaDevMax").value = s.buyMaDevMax;
    $("s_sellMaDevMin").value = s.sellMaDevMin;
    $("s_sellPrincipalMin").value = s.sellPrincipalMin;
    $("s_hySpreadTight").value = s.hySpreadTight;
    $("s_hySpreadWide").value = s.hySpreadWide;
    if ($("s_alertEnabled")) $("s_alertEnabled").checked = s.alertEnabled !== false;
    if ($("s_alertEmail")) $("s_alertEmail").value = s.alertEmail || DEFAULT_SETTINGS.alertEmail;
    if ($("s_alertCooldownHours")) {
      $("s_alertCooldownHours").value =
        s.alertCooldownHours != null ? s.alertCooldownHours : DEFAULT_SETTINGS.alertCooldownHours;
    }
  }
  function saveSettingsForm() {
    state.settings = {
      buyHMax: num($("s_buyHMax").value) != null ? num($("s_buyHMax").value) : DEFAULT_SETTINGS.buyHMax,
      buyMaDevMax: num($("s_buyMaDevMax").value) != null ? num($("s_buyMaDevMax").value) : DEFAULT_SETTINGS.buyMaDevMax,
      sellMaDevMin: num($("s_sellMaDevMin").value) != null ? num($("s_sellMaDevMin").value) : DEFAULT_SETTINGS.sellMaDevMin,
      sellPrincipalMin: num($("s_sellPrincipalMin").value) != null ? num($("s_sellPrincipalMin").value) : DEFAULT_SETTINGS.sellPrincipalMin,
      sellPrincipalRise: DEFAULT_SETTINGS.sellPrincipalRise,
      hySpreadWide: num($("s_hySpreadWide").value) != null ? num($("s_hySpreadWide").value) : DEFAULT_SETTINGS.hySpreadWide,
      hySpreadTight: num($("s_hySpreadTight").value) != null ? num($("s_hySpreadTight").value) : DEFAULT_SETTINGS.hySpreadTight,
      alertEnabled: $("s_alertEnabled") ? $("s_alertEnabled").checked : true,
      alertEmail: $("s_alertEmail")
        ? ($("s_alertEmail").value.trim() || DEFAULT_SETTINGS.alertEmail)
        : DEFAULT_SETTINGS.alertEmail,
      alertCooldownHours:
        num($("s_alertCooldownHours") && $("s_alertCooldownHours").value) != null
          ? num($("s_alertCooldownHours").value)
          : DEFAULT_SETTINGS.alertCooldownHours
    };
    saveSettings(state.settings);
    $("settingsPanel").classList.remove("on");
    refresh();
    alert("設定已更新（含郵件通知）。");
  }

  function doSyncWatchlist() {
    var r = syncWatchlist(state.funds);
    state.funds = r.list;
    saveFunds(state.funds);
    refresh();
    alert(r.added ? ("已補上 " + r.added + " 檔追蹤名單（不覆蓋既有資料）") : "追蹤名單已齊，無需新增");
  }

  function resetToWatchlist() {
    if (!confirm("將清單重置為 19 檔追蹤名單（會清除本機已填數值）。確定？")) return;
    state.funds = defaultFunds();
    saveFunds(state.funds);
    refresh();
  }


  // —— 自動搜尋網路並整理參考資訊（Gemini + Google 搜尋）——
  var KEY_GEMINI = "fund-eval-gemini-key";
  var GEMINI_MODELS = ["gemini-2.5-flash", "gemini-2.5-flash-lite", "gemini-flash-latest"];
  var researchBusy = false;

  function getGeminiKey() {
    var el = $("geminiKey");
    var k = (el && el.value ? el.value : "").trim() || localStorage.getItem(KEY_GEMINI) || "";
    return k.slice(0, 200);
  }

  function saveGeminiKey() {
    var k = getGeminiKey();
    if (k) localStorage.setItem(KEY_GEMINI, k);
    else localStorage.removeItem(KEY_GEMINI);
  }

  function extractJson(text) {
    var s = String(text || "").trim();
    if (!s) return null;
    s = s.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/i, "");
    try { return JSON.parse(s); } catch (e1) {}
    var a = s.indexOf("{");
    var b = s.lastIndexOf("}");
    if (a >= 0 && b > a) {
      try { return JSON.parse(s.slice(a, b + 1)); } catch (e2) {}
    }
    return null;
  }

  function buildResearchPrompt(fund) {
    var etf = isEtf(fund);
    var todayStr = new Date().toISOString().slice(0, 10);
    if (etf) {
      return (
        "你是台股／海外 ETF 研究員。今天約 " + todayStr + "。" +
        "請用網路最新公開資料，查證代號「" + (fund.bankCode || "") + "」名稱「" + (fund.name || "") + "」。" +
        "若代號有誤請在 confirmedName／summary 更正。" +
        "只回一個 JSON，不要 markdown：" +
        '{"confirmedName":"正式名稱","isin":"或空","navDate":"YYYY-MM-DD或空",' +
        '"nav":市價或淨值數字或null,"high52":數字或null,"low52":數字或null,"ma250":250日均線數字或null,' +
        '"premiumPct":折溢價百分點數字或null,"yieldAnn":殖利率%或null,"totalReturn1y":近一年報酬%或null,' +
        '"macroName":"追蹤指數","macroValue":指數數值或位階或null,' +
        '"macroNote":"一句技術／指數備註（可用超賣|低檔|過熱|新高追價）",' +
        '"sources":["來源"],"confidence":"高|中|低","summary":"兩句繁中摘要"}。' +
        "查不到填 null，禁止捏造。數字用阿拉伯數字。"
      );
    }
    return (
      "你是境外基金研究員（台灣銀行通路代碼）。今天約 " + todayStr + "。" +
      "請用網路最新公開資料（基金資訊觀測站、Morningstar、投信、銀行基金頁），查「" +
      (fund.bankCode || "") + "」「" + (fund.name || "") + "」計價 " + (fund.currency || "") + "。" +
      "只回一個 JSON，不要 markdown：" +
      '{"confirmedName":"正式名稱含級別","isin":"或空","navDate":"YYYY-MM-DD或空",' +
      '"nav":最新淨值或null,"high52":52週高或null,"low52":52週低或null,"ma250":約250日均線或null,' +
      '"divPerUnit":最近每單位配息或null,"yieldAnn":年化配息率%或null,' +
      '"principalPct":配息來自本金比例%或null,"totalReturn1y":近一年含息總報酬%或null,' +
      '"macroName":"建議連動指標","macroValue":指標數值(利差bp或指數)或null,' +
      '"macroNote":"一句總經備註（利差可寫收斂/回落/過度壓縮）",' +
      '"goldBreak":是否金價突破阻力true/false,' +
      '"sources":["來源"],"confidence":"高|中|低","summary":"兩句繁中摘要含進出場參考"}。' +
      "查不到填 null，禁止捏造。配息本金比若無公開資料填 null。"
    );
  }

  function callGeminiResearch(fund) {
    var apiKey = getGeminiKey();
    if (!apiKey) return Promise.reject(new Error("請先貼上 Gemini 金鑰（與購物帳相同，來自 Google AI Studio）"));

    var prompt = buildResearchPrompt(fund);
    var lastErr = null;
    var idx = 0;
    var noTool = false;

    function tryNext() {
      if (idx >= GEMINI_MODELS.length) {
        return Promise.reject(lastErr || new Error("Gemini 無回應"));
      }
      var model = GEMINI_MODELS[idx++];
      var url =
        "https://generativelanguage.googleapis.com/v1beta/models/" +
        encodeURIComponent(model) +
        ":generateContent?key=" +
        encodeURIComponent(apiKey);

      var body = {
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.2, maxOutputTokens: 4096 }
      };
      if (!noTool) body.tools = [{ google_search: {} }];

      return fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body)
      })
        .then(function (res) {
          return res.json().then(function (data) {
            if (!res.ok) {
              var rawMsg = (data.error && data.error.message) || ("HTTP " + res.status);
              lastErr = new Error(rawMsg);
              if (!noTool && /google_search|Unknown|not supported|INVALID_ARGUMENT/i.test(rawMsg)) {
                noTool = true;
                idx--;
                return tryNext();
              }
              return tryNext();
            }
            var parts = ((((data.candidates || [])[0] || {}).content || {}).parts) || [];
            var text = parts.map(function (p) { return p.text || ""; }).join("");
            var parsed = extractJson(text);
            if (parsed) return { parsed: parsed, model: model, raw: text };
            lastErr = new Error("無法解析搜尋結果 JSON");
            return tryNext();
          });
        })
        .catch(function (e) {
          lastErr = e;
          return tryNext();
        });
    }

    return tryNext();
  }

  /** 可選：台股 ETF 先打 Yahoo 圖表（若 CORS 失敗則略過） */
  function tryYahooTwEtf(code) {
    var symbol = String(code || "").replace(/[^0-9A-Za-z]/g, "") + ".TW";
    var url =
      "https://query1.finance.yahoo.com/v8/finance/chart/" +
      encodeURIComponent(symbol) +
      "?range=1y&interval=1d";
    return fetch(url)
      .then(function (r) {
        if (!r.ok) throw new Error("yahoo " + r.status);
        return r.json();
      })
      .then(function (data) {
        var r0 = (((data.chart || {}).result || [])[0]) || {};
        var meta = r0.meta || {};
        var q = (r0.indicators || {}).quote || [];
        var closes = (q[0] && q[0].close) || [];
        var valid = closes.filter(function (x) { return x != null && Number.isFinite(x); });
        if (!valid.length) return null;
        var nav = valid[valid.length - 1];
        var high52 = Math.max.apply(null, valid);
        var low52 = Math.min.apply(null, valid);
        var ma250 = null;
        if (valid.length >= 60) {
          var slice = valid.slice(-Math.min(250, valid.length));
          var sum = 0;
          for (var i = 0; i < slice.length; i++) sum += slice[i];
          ma250 = sum / slice.length;
        }
        return {
          nav: nav,
          high52: high52,
          low52: low52,
          ma250: ma250,
          navDate: meta.regularMarketTime
            ? new Date(meta.regularMarketTime * 1000).toISOString().slice(0, 10)
            : "",
          source: "Yahoo Finance " + symbol
        };
      })
      .catch(function () { return null; });
  }

  function applyResearchToFund(fund, parsed, yahoo) {
    var next = Object.assign({}, fund);
    var p = parsed || {};
    if (p.confirmedName) next.name = String(p.confirmedName).trim();
    if (p.isin) next.isin = String(p.isin).trim();
    if (p.navDate) next.navDate = String(p.navDate).trim();

    function take(field, val) {
      var n = num(val);
      if (n !== null) next[field] = n;
    }

    // Yahoo 先填價位，Gemini 可覆寫較完整欄位
    if (yahoo) {
      take("nav", yahoo.nav);
      take("high52", yahoo.high52);
      take("low52", yahoo.low52);
      take("ma250", yahoo.ma250);
      if (yahoo.navDate) next.navDate = yahoo.navDate;
    }

    take("nav", p.nav);
    take("high52", p.high52);
    take("low52", p.low52);
    take("ma250", p.ma250);
    take("premiumPct", p.premiumPct);
    take("divPerUnit", p.divPerUnit);
    take("yieldAnn", p.yieldAnn);
    take("totalReturn1y", p.totalReturn1y);

    if (!isEtf(fund)) {
      var oldL = num(fund.principalPct);
      var newL = num(p.principalPct);
      if (newL !== null) {
        if (oldL !== null && newL !== oldL) next.prevPrincipalPct = oldL;
        next.principalPct = newL;
      }
      if (typeof p.goldBreak === "boolean") next.goldBreak = p.goldBreak;
    }

    if (p.macroName) next.macroName = String(p.macroName).trim();
    take("macroValue", p.macroValue);
    if (p.macroNote) next.macroNote = String(p.macroNote).trim();

    var bits = [];
    if (p.summary) bits.push(String(p.summary).trim());
    if (p.confidence) bits.push("信心：" + p.confidence);
    if (Array.isArray(p.sources) && p.sources.length) bits.push("來源：" + p.sources.slice(0, 4).join("、"));
    if (yahoo && yahoo.source) bits.push(yahoo.source);
    bits.push("自動搜尋：" + new Date().toLocaleString("zh-TW", { hour12: false }));
    next.note = bits.join("｜");
    next.updatedAt = Date.now();
    next._lastResearch = {
      at: Date.now(),
      confidence: p.confidence || "",
      summary: p.summary || ""
    };
    return next;
  }

  function setResearchStatus(msg) {
    var el = $("researchStatus");
    if (el) el.textContent = msg || "";
  }

  function researchOneFund(fund) {
    var yahooPromise =
      isEtf(fund) && /^\d{4,5}[A-Za-z]?$/.test(String(fund.bankCode || ""))
        ? tryYahooTwEtf(fund.bankCode)
        : Promise.resolve(null);

    return yahooPromise.then(function (yahoo) {
      return callGeminiResearch(fund).then(function (res) {
        return applyResearchToFund(fund, res.parsed, yahoo);
      });
    });
  }

  function researchAndSave(id) {
    if (researchBusy) {
      alert("正在搜尋中，請稍候");
      return Promise.resolve();
    }
    var fund = state.funds.find(function (f) { return f.id === id; });
    if (!fund) return Promise.resolve();
    researchBusy = true;
    setResearchStatus("搜尋中：" + (fund.bankCode || "") + " " + (fund.name || "") + "…");
    return researchOneFund(fund)
      .then(function (next) {
        state.funds = state.funds.map(function (f) {
          return f.id === id ? next : f;
        });
        saveFunds(state.funds);
        refresh();
        var conf = (next._lastResearch && next._lastResearch.confidence) || "";
        setResearchStatus(
          "已更新 " + (next.bankCode || "") +
            (conf ? "（信心 " + conf + "）" : "") +
            "｜請核對摘要後再決策"
        );
      })
      .catch(function (err) {
        var msg = String((err && err.message) || err || "失敗");
        if (/API key|invalid|PERMISSION|401|403/i.test(msg)) {
          msg = "Gemini 金鑰無效，請到 AI Studio 重建後貼上";
        } else if (/high demand|429|Resource exhausted|overloaded/i.test(msg)) {
          msg = "Gemini 忙線，請等 1～2 分鐘再試";
        } else if (/Failed to fetch|NetworkError/i.test(msg)) {
          msg = "網路失敗，請確認可連線 Google";
        }
        setResearchStatus("失敗：" + msg);
        alert(msg);
      })
      .then(function () {
        researchBusy = false;
      });
  }

  function researchBatch(onlyNeed) {
    if (researchBusy) {
      alert("正在搜尋中，請稍候");
      return;
    }
    if (!getGeminiKey()) {
      alert("請先在上方貼上 Gemini 金鑰");
      return;
    }
    saveGeminiKey();
    var list = state.funds.filter(function (f) {
      if (!onlyNeed) return true;
      return evaluate(f, state.settings).status === "待補資料";
    });
    if (!list.length) {
      alert(onlyNeed ? "沒有「待補資料」的項目" : "清單是空的");
      return;
    }
    if (!confirm("將自動搜尋並填入 " + list.length + " 檔（約需數分鐘，請保持畫面開啟）。確定？")) return;

    researchBusy = true;
    var i = 0;
    var ok = 0;
    var fail = 0;

    function step() {
      if (i >= list.length) {
        researchBusy = false;
        saveFunds(state.funds);
        refresh();
        setResearchStatus("批次完成：成功 " + ok + "、失敗 " + fail);
        alert("自動搜尋完成：成功 " + ok + "、失敗 " + fail + "。請抽查摘要與數字。");
        return;
      }
      var fund = list[i++];
      setResearchStatus("搜尋 " + i + "/" + list.length + "：" + (fund.bankCode || "") + "…");
      researchOneFund(fund)
        .then(function (next) {
          ok++;
          state.funds = state.funds.map(function (f) {
            return f.id === fund.id ? next : f;
          });
          saveFunds(state.funds);
          refresh();
        })
        .catch(function () {
          fail++;
        })
        .then(function () {
          setTimeout(step, 1600);
        });
    }
    step();
  }

  function toggleFormMode() {
    var etf = $("f_instrumentType") && $("f_instrumentType").value === "etf";
    var fundBox = $("fundOnlyFields");
    var etfBox = $("etfOnlyFields");
    if (fundBox) fundBox.style.display = etf ? "none" : "block";
    if (etfBox) etfBox.style.display = etf ? "block" : "none";
    var lab = $("labelNav");
    if (lab) lab.textContent = etf ? "E 最新市價／淨值" : "E 最新淨值";
  }

  function on(id, ev, fn) {
    var el = $(id);
    if (el) el.addEventListener(ev, fn);
  }

  function bind() {
    fillAssetSelect();
    fillMacroSelect();
    loadSettingsForm();
    document.querySelectorAll("[data-filter]").forEach(function (btn) {
      btn.addEventListener("click", function () {
        state.filter = btn.getAttribute("data-filter");
        document.querySelectorAll("[data-filter]").forEach(function (b) {
          b.classList.toggle("on", b === btn);
        });
        renderList();
      });
    });
    on("btnAdd", "click", function () { openForm(null); });
    on("btnCancel", "click", closeForm);
    on("btnSave", "click", saveForm);
    on("btnExport", "click", exportCsv);
    on("btnSettings", "click", function () {
      loadSettingsForm();
      $("settingsPanel").classList.add("on");
    });
    on("btnSettingsCancel", "click", function () { $("settingsPanel").classList.remove("on"); });
    on("btnSettingsSave", "click", saveSettingsForm);
    on("btnSyncWatch", "click", doSyncWatchlist);
    on("btnResetWatch", "click", resetToWatchlist);
    on("btnResearchNeed", "click", function () { researchBatch(true); });
    on("btnResearchAll", "click", function () { researchBatch(false); });
    on("btnSaveKey", "click", function () {
      saveGeminiKey();
      setResearchStatus(getGeminiKey() ? "金鑰已存本機" : "已清除金鑰");
    });
    on("f_instrumentType", "change", function () { toggleFormMode(); updateLivePreview(); });
    try {
      var savedKey = localStorage.getItem(KEY_GEMINI);
      if (savedKey && $("geminiKey")) $("geminiKey").value = savedKey;
    } catch (eKey) {}
    on("btnTestAlert", "click", function () {
      var statusEl = $("alertStatus");
      if (statusEl) statusEl.textContent = "寄送中…";
      checkAndNotifySignals(true).then(function (r) {
        if (statusEl) {
          statusEl.textContent =
            "已處理：寄出 " + r.sent + " 封（冷卻略過 " + r.skipped + "）。請查收 " +
            (state.settings.alertEmail || DEFAULT_SETTINGS.alertEmail) +
            "；若是第一次，請先點 FormSubmit 確認信。";
        }
      });
    });
    on("btnEnableNotify", "click", function () {
      if (!("Notification" in window)) {
        alert("此瀏覽器不支援系統通知");
        return;
      }
      Notification.requestPermission().then(function (p) {
        alert(p === "granted" ? "已開啟系統通知（買／賣點會同時跳出）" : "未授權系統通知，仍會嘗試寄信");
      });
    });
    ["f_nav","f_high52","f_low52","f_ma250","f_principalPct","f_prevPrincipalPct","f_premiumPct","f_macroKind","f_macroValue","f_macroNote","f_goldBreak","f_divPolicy","f_yieldAnn","f_totalReturn1y","f_instrumentType"].forEach(function (id) {
      var el = $(id); if (!el) return;
      el.addEventListener("input", updateLivePreview);
      el.addEventListener("change", updateLivePreview);
    });
    $("list").addEventListener("click", function (e) {
      var btn = e.target.closest("[data-act]");
      if (!btn) return;
      var card = btn.closest(".fund-card");
      if (!card) return;
      var id = card.getAttribute("data-id");
      var fund = state.funds.find(function (f) { return f.id === id; });
      if (!fund) return;
      if (btn.getAttribute("data-act") === "research") researchAndSave(id);
      if (btn.getAttribute("data-act") === "edit") openForm(fund);
      if (btn.getAttribute("data-act") === "del") deleteFund(id);
    });
    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.register("./sw.js").catch(function () {});
    }
  }

  document.addEventListener("DOMContentLoaded", function () { bind(); refresh(); });
})();
