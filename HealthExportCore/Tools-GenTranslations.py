#!/usr/bin/env python3
"""Translations.json から Swift の翻訳表を作る。

訳を足すときは JSON だけ直して、これを走らせる。Swift は手で直さない。
    python3 Tools-GenTranslations.py
"""
import json, collections, pathlib

ROOT = pathlib.Path(__file__).parent
d = json.load(open(ROOT / "Translations.json"), object_pairs_hook=collections.OrderedDict)

# Swift の enum ケース名。JSON のキー（BCP47）とは書き方が違うものがある。
CASE = {"ja": "ja", "en": "en", "zh-Hans": "zhHans", "zh-Hant": "zhHant", "ko": "ko",
        "es": "es", "fr": "fr", "de": "de", "it": "it", "pt-BR": "ptBR", "ru": "ru", "ar": "ar"}

def lit(s):
    """Swift の文字列リテラル。

    日数の入る場所は JSON では `\\(days)` と書いてあるが、そのまま Swift に出すと
    その場で補間されてしまう（`days` はこのスコープに無いのでコンパイルが通らない）。
    プレースホルダ `%d` に置き換えて、使う側で差し込む。
    """
    s = s.replace("\\(days)", "%d")
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'

def table(name, section, indent="    "):
    out = [f"{indent}static let {name}: [String: [Language: String]] = ["]
    for key, byLang in d[section].items():
        pairs = ", ".join(f".{CASE[l]}: {lit(v)}" for l, v in byLang.items() if l in CASE)
        out.append(f'{indent}    "{key}": [{pairs}],')
    out.append(f"{indent}]")
    return "\n".join(out)

def askTable(indent="    "):
    out = [f"{indent}static let askLines: [String: [Language: [String]]] = ["]
    for key, byLang in d["askLines"].items():
        out.append(f'{indent}    "{key}": [')
        for l, lines in byLang.items():
            if l not in CASE: continue
            body = ", ".join(lit(x) for x in lines)
            out.append(f"{indent}        .{CASE[l]}: [{body}],")
        out.append(f"{indent}    ],")
    out.append(f"{indent}]")
    return "\n".join(out)

disc = ", ".join(f".{CASE[l]}: {lit(v)}" for l, v in d["disclaimer"].items() if l in CASE)

swift = f'''// このファイルは Translations.json から作っている。**手で直さない。**
// 訳を足すときは JSON を直してから `python3 Tools-GenTranslations.py` を走らせる。
//
// 訳が無い言語は英語に落とす（Language.fallback）。新しい言語を足したとき、
// 訳し終えていない項目があっても画面が空にならない。

import Foundation

public enum Tr {{
    /// 表から引く。その言語に無ければ英語、それも無ければキーをそのまま返す。
    public static func get(_ table: [String: [Language: String]], _ key: String, _ language: Language) -> String {{
        guard let entry = table[key] else {{ return key }}
        return entry[language] ?? entry[Language.fallback] ?? key
    }}

    /// 書き出しの枠の文言。`{{from}}` のような目印に値を差し込む。
    /// 語順が言語ごとに違う（「期間: A 〜 B」と「du A au B」）ので、文を丸ごと訳して目印で埋める。
    public static func frame(_ key: String, _ language: Language, _ values: [String: String] = [:]) -> String {{
        var text = get(export, key, language)
        for (name, value) in values {{ text = text.replacingOccurrences(of: "{{\(name)}}", with: value) }}
        return text
    }}

    /// 依頼文のなかで、免責の一文が入る場所を指す目印。
    /// 6つの目的すべてで同じ文を使うので、訳を12言語 × 6回持たずに済ませている。
    public static let disclaimerPlaceholder = "__DISCLAIMER__"

    public static let disclaimer: [Language: String] = [{disc}]

{table("purposeTitle", "purposeTitle")}

{table("purposeDetail", "purposeDetail")}

{table("period", "period")}

{table("metricName", "metricName")}

{table("metricUnit", "metricUnit")}

{table("keyLabel", "keyLabel")}

{table("category", "category")}

{table("aggregation", "aggregation")}

{table("workout", "workout")}

{table("mood", "mood")}

{table("export", "export")}

{askTable()}
}}
'''
out = ROOT / "Sources/HealthExportCore/Translations.generated.swift"
out.write_text(swift)
print(f"{out.name}: {len(swift.splitlines())} 行 / 言語 {len(CASE)}")
