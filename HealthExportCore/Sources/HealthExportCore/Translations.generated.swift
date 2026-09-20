// このファイルは Translations.json から作っている。**手で直さない。**
// 訳を足すときは JSON を直してから `python3 Tools-GenTranslations.py` を走らせる。
//
// 訳が無い言語は英語に落とす（Language.fallback）。新しい言語を足したとき、
// 訳し終えていない項目があっても画面が空にならない。

import Foundation

public enum Tr {
    /// 表から引く。その言語に無ければ英語、それも無ければキーをそのまま返す。
    public static func get(_ table: [String: [Language: String]], _ key: String, _ language: Language) -> String {
        guard let entry = table[key] else { return key }
        return entry[language] ?? entry[Language.fallback] ?? key
    }

    /// 依頼文のなかで、免責の一文が入る場所を指す目印。
    /// 6つの目的すべてで同じ文を使うので、訳を12言語 × 6回持たずに済ませている。
    public static let disclaimerPlaceholder = "__DISCLAIMER__"

    public static let disclaimer: [Language: String] = [.ja: "これは医療的な診断のためのものではありません。気になる症状があるときは受診します。", .en: "This is not for medical diagnosis. I will see a doctor if I have symptoms of concern.", .zhHans: "这不是用于医学诊断的内容。如有不适症状，我会去看医生。", .zhHant: "這不是用於醫學診斷的內容。如有不適症狀，我會去看醫生。", .ko: "이것은 의학적 진단을 위한 것이 아닙니다. 걱정되는 증상이 있으면 진료를 받겠습니다.", .es: "Esto no es para un diagnóstico médico. Si tengo síntomas preocupantes, acudiré al médico.", .fr: "Ceci n'est pas destiné à un diagnostic médical. En cas de symptômes inquiétants, je consulterai un médecin.", .de: "Dies dient nicht der medizinischen Diagnose. Bei besorgniserregenden Symptomen gehe ich zum Arzt.", .it: "Questo non è a scopo di diagnosi medica. In caso di sintomi preoccupanti mi rivolgerò a un medico.", .ptBR: "Isto não se destina a diagnóstico médico. Se eu tiver sintomas preocupantes, procurarei um médico.", .ru: "Это не предназначено для медицинской диагностики. При тревожных симптомах я обращусь к врачу.", .ar: "هذا ليس لغرض التشخيص الطبي. وإذا ظهرت أعراض مقلقة، فسأراجع الطبيب."]

    static let purposeTitle: [String: [Language: String]] = [
        "general": [.ja: "ふだんの管理", .en: "General check-in", .zhHans: "日常管理", .zhHant: "日常管理", .ko: "일상 관리", .es: "Revisión general", .fr: "Bilan général", .de: "Allgemeiner Überblick", .it: "Panoramica generale", .ptBR: "Visão geral", .ru: "Общий обзор", .ar: "نظرة عامة"],
        "sleep": [.ja: "睡眠のこと", .en: "Sleep", .zhHans: "睡眠", .zhHant: "睡眠", .ko: "수면", .es: "Sueño", .fr: "Sommeil", .de: "Schlaf", .it: "Sonno", .ptBR: "Sono", .ru: "Сон", .ar: "النوم"],
        "training": [.ja: "運動のこと", .en: "Training", .zhHans: "训练", .zhHant: "訓練", .ko: "운동", .es: "Entrenamiento", .fr: "Entraînement", .de: "Training", .it: "Allenamento", .ptBR: "Treino", .ru: "Тренировки", .ar: "التمارين"],
        "condition": [.ja: "体調の変化", .en: "Condition", .zhHans: "身体状况", .zhHant: "身體狀況", .ko: "컨디션", .es: "Estado físico", .fr: "État de forme", .de: "Verfassung", .it: "Condizione", .ptBR: "Condição", .ru: "Самочувствие", .ar: "الحالة الصحية"],
        "mind": [.ja: "こころの調子", .en: "Mood", .zhHans: "心情", .zhHant: "心情", .ko: "기분", .es: "Estado de ánimo", .fr: "Humeur", .de: "Stimmung", .it: "Umore", .ptBR: "Humor", .ru: "Настроение", .ar: "المزاج"],
        "everything": [.ja: "質問せずに渡す", .en: "No questions", .zhHans: "不提问题", .zhHant: "不提問題", .ko: "질문 없이", .es: "Sin preguntas", .fr: "Sans question", .de: "Ohne Fragen", .it: "Senza domande", .ptBR: "Sem perguntas", .ru: "Без вопросов", .ar: "بدون أسئلة"],
    ]

    static let purposeDetail: [String: [Language: String]] = [
        "general": [.ja: "記録があるもの全部", .en: "Everything you have", .zhHans: "你记录的全部数据", .zhHant: "你記錄的全部數據", .ko: "기록된 모든 항목", .es: "Todo lo que tengas", .fr: "Tout ce que vous avez", .de: "Alles, was vorhanden ist", .it: "Tutto ciò che hai", .ptBR: "Tudo o que você tem", .ru: "Всё, что записано", .ar: "كل ما لديك من بيانات"],
        "sleep": [.ja: "睡眠と、影響する項目", .en: "Sleep and what affects it", .zhHans: "睡眠及其影响因素", .zhHant: "睡眠及其影響因素", .ko: "수면과 영향 요인", .es: "El sueño y lo que le afecta", .fr: "Le sommeil et ce qui l'influence", .de: "Schlaf und was ihn beeinflusst", .it: "Il sonno e ciò che lo influenza", .ptBR: "O sono e o que o afeta", .ru: "Сон и что на него влияет", .ar: "النوم وما يؤثر فيه"],
        "training": [.ja: "運動量と、疲れの回復", .en: "Training load and recovery", .zhHans: "训练量与恢复情况", .zhHant: "訓練量與恢復情況", .ko: "운동량과 회복", .es: "Carga de entrenamiento y recuperación", .fr: "Charge d'entraînement et récupération", .de: "Trainingsbelastung und Erholung", .it: "Carico di allenamento e recupero", .ptBR: "Carga de treino e recuperação", .ru: "Нагрузка и восстановление", .ar: "حمل التمرين والتعافي"],
        "condition": [.ja: "ふだんと違う時期を探す", .en: "Find days unlike your usual", .zhHans: "找出与平时不同的日子", .zhHant: "找出與平時不同的日子", .ko: "평소와 다른 날 찾기", .es: "Encuentra los días fuera de lo habitual", .fr: "Repérer les jours inhabituels", .de: "Tage finden, die vom Normalen abweichen", .it: "Trova i giorni fuori dal solito", .ptBR: "Encontre os dias fora do normal", .ru: "Найти дни, не похожие на обычные", .ar: "ابحث عن الأيام المختلفة عن المعتاد"],
        "mind": [.ja: "気分と、体の記録の関係", .en: "Mood against body data", .zhHans: "心情与身体数据的关系", .zhHant: "心情與身體數據的關係", .ko: "기분과 신체 기록의 관계", .es: "El ánimo frente a los datos corporales", .fr: "L'humeur au regard des données corporelles", .de: "Stimmung im Vergleich zu Körperdaten", .it: "L'umore rispetto ai dati corporei", .ptBR: "O humor em relação aos dados do corpo", .ru: "Настроение и данные тела", .ar: "المزاج مقارنةً ببيانات الجسم"],
        "everything": [.ja: "何も聞かず、自由に見てもらう", .en: "Let the AI look freely", .zhHans: "让 AI 自由查看", .zhHant: "讓 AI 自由查看", .ko: "AI가 자유롭게 살펴보도록", .es: "Deja que la IA lo revise libremente", .fr: "Laisser l'IA regarder librement", .de: "Die KI frei schauen lassen", .it: "Lascia che l'IA guardi liberamente", .ptBR: "Deixe a IA analisar livremente", .ru: "Пусть ИИ посмотрит сам", .ar: "دع الذكاء الاصطناعي يطّلع بحرية"],
    ]

    static let period: [String: [Language: String]] = [
        "14": [.ja: "2週間", .en: "2 weeks", .zhHans: "2周", .zhHant: "2週", .ko: "2주", .es: "2 semanas", .fr: "2 semaines", .de: "2 Wochen", .it: "2 settimane", .ptBR: "2 semanas", .ru: "2 недели", .ar: "أسبوعان"],
        "30": [.ja: "1ヶ月", .en: "1 month", .zhHans: "1个月", .zhHant: "1個月", .ko: "1개월", .es: "1 mes", .fr: "1 mois", .de: "1 Monat", .it: "1 mese", .ptBR: "1 mês", .ru: "1 месяц", .ar: "شهر واحد"],
        "90": [.ja: "3ヶ月", .en: "3 months", .zhHans: "3个月", .zhHant: "3個月", .ko: "3개월", .es: "3 meses", .fr: "3 mois", .de: "3 Monate", .it: "3 mesi", .ptBR: "3 meses", .ru: "3 месяца", .ar: "3 أشهر"],
        "180": [.ja: "6ヶ月", .en: "6 months", .zhHans: "6个月", .zhHant: "6個月", .ko: "6개월", .es: "6 meses", .fr: "6 mois", .de: "6 Monate", .it: "6 mesi", .ptBR: "6 meses", .ru: "6 месяцев", .ar: "6 أشهر"],
        "365": [.ja: "1年", .en: "1 year", .zhHans: "1年", .zhHant: "1年", .ko: "1년", .es: "1 año", .fr: "1 an", .de: "1 Jahr", .it: "1 anno", .ptBR: "1 ano", .ru: "1 год", .ar: "سنة واحدة"],
        "_": [.ja: "%d日間", .en: "%d days", .zhHans: "%d天", .zhHant: "%d天", .ko: "%d일", .es: "%d días", .fr: "%d jours", .de: "%d Tage", .it: "%d giorni", .ptBR: "%d dias", .ru: "%d дн.", .ar: "%d يوم"],
    ]

    static let metricName: [String: [Language: String]] = [
        "steps": [.ja: "歩数", .en: "Steps", .zhHans: "步数", .zhHant: "步數", .ko: "걸음", .es: "Pasos", .fr: "Pas", .de: "Schritte", .it: "Passi", .ptBR: "Passos", .ru: "Шаги", .ar: "الخطوات"],
        "distance": [.ja: "歩行+走行距離", .en: "Walking+running distance", .zhHans: "步行+跑步距离", .zhHant: "步行+跑步距離", .ko: "걷기+달리기 거리", .es: "Distancia a pie y corriendo", .fr: "Distance marche+course", .de: "Geh- und Laufstrecke", .it: "Distanza camminata+corsa", .ptBR: "Distância caminhada+corrida", .ru: "Дистанция ходьбы и бега", .ar: "مسافة المشي والجري"],
        "flights": [.ja: "上った階数", .en: "Flights climbed", .zhHans: "已爬楼层", .zhHant: "已爬樓層", .ko: "오른 층수", .es: "Pisos subidos", .fr: "Étages montés", .de: "Etagen gestiegen", .it: "Piani saliti", .ptBR: "Andares subidos", .ru: "Пройдено этажей", .ar: "الطوابق المصعودة"],
        "activeEnergy": [.ja: "アクティブエネルギー", .en: "Active energy", .zhHans: "活动能量", .zhHant: "活動能量", .ko: "활동 에너지", .es: "Energía activa", .fr: "Énergie active", .de: "Aktive Energie", .it: "Energia attiva", .ptBR: "Energia ativa", .ru: "Активная энергия", .ar: "الطاقة النشطة"],
        "basalEnergy": [.ja: "安静時エネルギー", .en: "Resting energy", .zhHans: "静息能量", .zhHant: "靜息能量", .ko: "휴식 에너지", .es: "Energía en reposo", .fr: "Énergie au repos", .de: "Ruheenergie", .it: "Energia a riposo", .ptBR: "Energia em repouso", .ru: "Энергия покоя", .ar: "طاقة الراحة"],
        "exerciseTime": [.ja: "エクササイズ時間", .en: "Exercise minutes", .zhHans: "锻炼时间", .zhHant: "鍛鍊時間", .ko: "운동 시간", .es: "Minutos de ejercicio", .fr: "Minutes d'exercice", .de: "Trainingsminuten", .it: "Minuti di esercizio", .ptBR: "Minutos de exercício", .ru: "Минуты упражнений", .ar: "دقائق التمرين"],
        "standTime": [.ja: "スタンド時間", .en: "Stand minutes", .zhHans: "站立时间", .zhHant: "站立時間", .ko: "서 있기 시간", .es: "Minutos de pie", .fr: "Minutes debout", .de: "Stehminuten", .it: "Minuti in piedi", .ptBR: "Minutos em pé", .ru: "Минуты стоя", .ar: "دقائق الوقوف"],
        "workouts": [.ja: "ワークアウト", .en: "Workouts", .zhHans: "体能训练", .zhHant: "體能訓練", .ko: "운동 기록", .es: "Entrenamientos", .fr: "Entraînements", .de: "Workouts", .it: "Allenamenti", .ptBR: "Treinos", .ru: "Тренировки", .ar: "التمارين"],
        "heartRate": [.ja: "心拍数", .en: "Heart rate", .zhHans: "心率", .zhHant: "心率", .ko: "심박수", .es: "Frecuencia cardíaca", .fr: "Fréquence cardiaque", .de: "Herzfrequenz", .it: "Frequenza cardiaca", .ptBR: "Frequência cardíaca", .ru: "Пульс", .ar: "معدل ضربات القلب"],
        "restingHeartRate": [.ja: "安静時心拍数", .en: "Resting heart rate", .zhHans: "静息心率", .zhHant: "靜息心率", .ko: "안정 시 심박수", .es: "Frecuencia cardíaca en reposo", .fr: "Fréquence cardiaque au repos", .de: "Ruheherzfrequenz", .it: "Frequenza cardiaca a riposo", .ptBR: "Frequência cardíaca em repouso", .ru: "Пульс покоя", .ar: "معدل ضربات القلب أثناء الراحة"],
        "hrv": [.ja: "心拍変動（SDNN）", .en: "Heart rate variability", .zhHans: "心率变异性（SDNN）", .zhHant: "心率變異性（SDNN）", .ko: "심박 변이도(SDNN)", .es: "Variabilidad cardíaca (SDNN)", .fr: "Variabilité cardiaque (SDNN)", .de: "Herzfrequenzvariabilität (SDNN)", .it: "Variabilità cardiaca (SDNN)", .ptBR: "Variabilidade cardíaca (SDNN)", .ru: "Вариабельность пульса (SDNN)", .ar: "تغير معدل ضربات القلب (SDNN)"],
        "walkingHeartRate": [.ja: "歩行時平均心拍数", .en: "Walking heart rate average", .zhHans: "步行平均心率", .zhHant: "步行平均心率", .ko: "보행 중 평균 심박수", .es: "Frecuencia cardíaca al caminar", .fr: "Fréquence cardiaque à la marche", .de: "Herzfrequenz beim Gehen", .it: "Frequenza cardiaca camminando", .ptBR: "Frequência cardíaca ao caminhar", .ru: "Пульс при ходьбе", .ar: "معدل ضربات القلب أثناء المشي"],
        "vo2Max": [.ja: "心肺機能（VO2max）", .en: "Cardio fitness (VO2max)", .zhHans: "心肺适能（VO2max）", .zhHant: "心肺適能（VO2max）", .ko: "심폐 체력(VO2max)", .es: "Capacidad cardiorrespiratoria (VO2máx)", .fr: "Capacité cardio (VO2max)", .de: "Cardiofitness (VO2max)", .it: "Forma cardiovascolare (VO2max)", .ptBR: "Preparo cardiovascular (VO2máx)", .ru: "Кардиовыносливость (VO2max)", .ar: "اللياقة القلبية (VO2max)"],
        "oxygenSaturation": [.ja: "血中酸素", .en: "Blood oxygen", .zhHans: "血氧", .zhHant: "血氧", .ko: "혈중 산소", .es: "Oxígeno en sangre", .fr: "Oxygène sanguin", .de: "Blutsauerstoff", .it: "Ossigeno nel sangue", .ptBR: "Oxigênio no sangue", .ru: "Кислород в крови", .ar: "أكسجين الدم"],
        "respiratoryRate": [.ja: "呼吸数", .en: "Respiratory rate", .zhHans: "呼吸频率", .zhHant: "呼吸頻率", .ko: "호흡수", .es: "Frecuencia respiratoria", .fr: "Fréquence respiratoire", .de: "Atemfrequenz", .it: "Frequenza respiratoria", .ptBR: "Frequência respiratória", .ru: "Частота дыхания", .ar: "معدل التنفس"],
        "wristTemperature": [.ja: "手首皮膚温の変化", .en: "Wrist temperature deviation", .zhHans: "手腕皮温变化", .zhHant: "手腕皮溫變化", .ko: "손목 피부 온도 변화", .es: "Variación de temperatura en la muñeca", .fr: "Écart de température au poignet", .de: "Handgelenktemperatur-Abweichung", .it: "Variazione temperatura al polso", .ptBR: "Variação da temperatura do pulso", .ru: "Отклонение температуры запястья", .ar: "انحراف حرارة المعصم"],
        "sleep": [.ja: "睡眠", .en: "Sleep", .zhHans: "睡眠", .zhHant: "睡眠", .ko: "수면", .es: "Sueño", .fr: "Sommeil", .de: "Schlaf", .it: "Sonno", .ptBR: "Sono", .ru: "Сон", .ar: "النوم"],
        "bodyMass": [.ja: "体重", .en: "Body mass", .zhHans: "体重", .zhHant: "體重", .ko: "체중", .es: "Peso corporal", .fr: "Poids", .de: "Körpergewicht", .it: "Peso corporeo", .ptBR: "Peso corporal", .ru: "Вес", .ar: "وزن الجسم"],
        "bodyFat": [.ja: "体脂肪率", .en: "Body fat percentage", .zhHans: "体脂率", .zhHant: "體脂率", .ko: "체지방률", .es: "Porcentaje de grasa corporal", .fr: "Masse grasse", .de: "Körperfettanteil", .it: "Percentuale di grasso corporeo", .ptBR: "Percentual de gordura corporal", .ru: "Процент жира", .ar: "نسبة دهون الجسم"],
        "walkingSpeed": [.ja: "歩行速度", .en: "Walking speed", .zhHans: "步行速度", .zhHant: "步行速度", .ko: "보행 속도", .es: "Velocidad al caminar", .fr: "Vitesse de marche", .de: "Gehgeschwindigkeit", .it: "Velocità di camminata", .ptBR: "Velocidade da caminhada", .ru: "Скорость ходьбы", .ar: "سرعة المشي"],
        "stepLength": [.ja: "歩幅", .en: "Walking step length", .zhHans: "步幅", .zhHant: "步幅", .ko: "보폭", .es: "Longitud del paso", .fr: "Longueur de pas", .de: "Schrittlänge", .it: "Lunghezza del passo", .ptBR: "Comprimento da passada", .ru: "Длина шага", .ar: "طول الخطوة"],
        "walkingAsymmetry": [.ja: "歩行の非対称性", .en: "Walking asymmetry", .zhHans: "步行不对称性", .zhHant: "步行不對稱性", .ko: "보행 비대칭성", .es: "Asimetría al caminar", .fr: "Asymétrie de marche", .de: "Gangasymmetrie", .it: "Asimmetria della camminata", .ptBR: "Assimetria da caminhada", .ru: "Асимметрия ходьбы", .ar: "عدم تناسق المشي"],
        "headphoneAudio": [.ja: "ヘッドフォン音量", .en: "Headphone audio levels", .zhHans: "耳机音量", .zhHant: "耳機音量", .ko: "헤드폰 음량", .es: "Nivel de audio con auriculares", .fr: "Niveau sonore du casque", .de: "Kopfhörerpegel", .it: "Livello audio delle cuffie", .ptBR: "Nível de áudio dos fones", .ru: "Громкость наушников", .ar: "مستوى صوت السماعات"],
        "environmentalAudio": [.ja: "環境音レベル", .en: "Environmental sound levels", .zhHans: "环境音量", .zhHant: "環境音量", .ko: "주변 소음 수준", .es: "Nivel de sonido ambiental", .fr: "Niveau sonore ambiant", .de: "Umgebungslautstärke", .it: "Livello del suono ambientale", .ptBR: "Nível de som ambiente", .ru: "Уровень окружающего шума", .ar: "مستوى الصوت المحيط"],
        "mindful": [.ja: "マインドフルネス", .en: "Mindful minutes", .zhHans: "正念时间", .zhHant: "正念時間", .ko: "마음챙김 시간", .es: "Minutos de mindfulness", .fr: "Minutes de pleine conscience", .de: "Achtsamkeitsminuten", .it: "Minuti di mindfulness", .ptBR: "Minutos de mindfulness", .ru: "Минуты осознанности", .ar: "دقائق اليقظة الذهنية"],
        "stateOfMind": [.ja: "気分の記録", .en: "State of mind", .zhHans: "心情记录", .zhHant: "心情記錄", .ko: "마음 상태", .es: "Estado de ánimo", .fr: "État d'esprit", .de: "Gemütszustand", .it: "Stato d'animo", .ptBR: "Estado emocional", .ru: "Душевное состояние", .ar: "الحالة الذهنية"],
    ]

    static let metricUnit: [String: [Language: String]] = [
        "steps": [.ja: "歩", .en: "steps", .zhHans: "步", .zhHant: "步", .ko: "걸음", .es: "pasos", .fr: "pas", .de: "Schritte", .it: "passi", .ptBR: "passos", .ru: "шагов", .ar: "خطوة"],
        "distance": [.ja: "km", .en: "km"],
        "flights": [.ja: "階", .en: "floors", .zhHans: "层", .zhHant: "層", .ko: "층", .es: "pisos", .fr: "étages", .de: "Etagen", .it: "piani", .ptBR: "andares", .ru: "этажей", .ar: "طابق"],
        "activeEnergy": [.ja: "kcal", .en: "kcal"],
        "basalEnergy": [.ja: "kcal", .en: "kcal"],
        "exerciseTime": [.ja: "分", .en: "min"],
        "standTime": [.ja: "分", .en: "min"],
        "workouts": [.ja: "", .en: ""],
        "heartRate": [.ja: "bpm", .en: "bpm"],
        "restingHeartRate": [.ja: "bpm", .en: "bpm"],
        "hrv": [.ja: "ms", .en: "ms"],
        "walkingHeartRate": [.ja: "bpm", .en: "bpm"],
        "vo2Max": [.ja: "mL/kg/min", .en: "mL/kg/min"],
        "oxygenSaturation": [.ja: "%", .en: "%"],
        "respiratoryRate": [.ja: "回/分", .en: "breaths/min", .zhHans: "次/分", .zhHant: "次/分", .ko: "회/분", .es: "resp./min", .fr: "resp./min", .de: "Atemzüge/min", .it: "resp./min", .ptBR: "resp./min", .ru: "вдох./мин", .ar: "نفس/دقيقة"],
        "wristTemperature": [.ja: "℃", .en: "C"],
        "sleep": [.ja: "時間", .en: "h"],
        "bodyMass": [.ja: "kg", .en: "kg"],
        "bodyFat": [.ja: "%", .en: "%"],
        "walkingSpeed": [.ja: "km/h", .en: "km/h"],
        "stepLength": [.ja: "cm", .en: "cm"],
        "walkingAsymmetry": [.ja: "%", .en: "%"],
        "headphoneAudio": [.ja: "dB", .en: "dB"],
        "environmentalAudio": [.ja: "dB", .en: "dB"],
        "mindful": [.ja: "分", .en: "min"],
        "stateOfMind": [.ja: "", .en: ""],
    ]

    static let keyLabel: [String: [Language: String]] = [
        "total": [.ja: "合計", .en: "total", .zhHans: "合计", .zhHant: "合計", .ko: "합계", .es: "total", .fr: "total", .de: "Gesamt", .it: "totale", .ptBR: "total", .ru: "всего", .ar: "الإجمالي"],
        "deep": [.ja: "深い", .en: "deep", .zhHans: "深睡", .zhHant: "深睡", .ko: "깊은수면", .es: "profundo", .fr: "profond", .de: "Tief", .it: "profondo", .ptBR: "profundo", .ru: "глубокий", .ar: "عميق"],
        "rem": [.ja: "レム", .en: "rem", .zhHans: "REM", .zhHant: "REM", .ko: "렘수면", .es: "REM", .fr: "REM", .de: "REM", .it: "REM", .ptBR: "REM", .ru: "REM", .ar: "REM"],
        "core": [.ja: "コア", .en: "core", .zhHans: "核心", .zhHant: "核心", .ko: "코어", .es: "central", .fr: "central", .de: "Kern", .it: "centrale", .ptBR: "central", .ru: "основной", .ar: "أساسي"],
        "awake": [.ja: "覚醒", .en: "awake", .zhHans: "清醒", .zhHant: "清醒", .ko: "깸", .es: "despierto", .fr: "éveillé", .de: "Wach", .it: "sveglio", .ptBR: "acordado", .ru: "бодрств.", .ar: "مستيقظ"],
        "bed": [.ja: "就寝", .en: "bed", .zhHans: "就寝", .zhHant: "就寢", .ko: "취침", .es: "acostarse", .fr: "coucher", .de: "Zubett", .it: "a letto", .ptBR: "deitar", .ru: "отбой", .ar: "النوم"],
        "wake": [.ja: "起床", .en: "wake", .zhHans: "起床", .zhHant: "起床", .ko: "기상", .es: "despertar", .fr: "lever", .de: "Aufstehen", .it: "sveglia", .ptBR: "acordar", .ru: "подъём", .ar: "الاستيقاظ"],
        "avg": [.ja: "平均", .en: "avg", .zhHans: "平均", .zhHant: "平均", .ko: "평균", .es: "media", .fr: "moy.", .de: "Ø", .it: "media", .ptBR: "média", .ru: "сред.", .ar: "المتوسط"],
        "min": [.ja: "最小", .en: "min", .zhHans: "最小", .zhHant: "最小", .ko: "최소", .es: "mín.", .fr: "min", .de: "Min", .it: "min", .ptBR: "mín.", .ru: "мин.", .ar: "الأدنى"],
        "max": [.ja: "最大", .en: "max", .zhHans: "最大", .zhHant: "最大", .ko: "최대", .es: "máx.", .fr: "max", .de: "Max", .it: "max", .ptBR: "máx.", .ru: "макс.", .ar: "الأعلى"],
    ]

    static let category: [String: [Language: String]] = [
        "activity": [.ja: "アクティビティ", .en: "Activity", .zhHans: "活动", .zhHant: "活動", .ko: "활동", .es: "Actividad", .fr: "Activité", .de: "Aktivität", .it: "Attività", .ptBR: "Atividade", .ru: "Активность", .ar: "النشاط"],
        "heart": [.ja: "心臓", .en: "Heart", .zhHans: "心脏", .zhHant: "心臟", .ko: "심장", .es: "Corazón", .fr: "Cœur", .de: "Herz", .it: "Cuore", .ptBR: "Coração", .ru: "Сердце", .ar: "القلب"],
        "respiratory": [.ja: "呼吸・体温", .en: "Respiratory", .zhHans: "呼吸与体温", .zhHant: "呼吸與體溫", .ko: "호흡·체온", .es: "Respiración", .fr: "Respiration", .de: "Atmung", .it: "Respirazione", .ptBR: "Respiração", .ru: "Дыхание", .ar: "التنفس"],
        "sleep": [.ja: "睡眠", .en: "Sleep", .zhHans: "睡眠", .zhHant: "睡眠", .ko: "수면", .es: "Sueño", .fr: "Sommeil", .de: "Schlaf", .it: "Sonno", .ptBR: "Sono", .ru: "Сон", .ar: "النوم"],
        "body": [.ja: "からだ", .en: "Body", .zhHans: "身体", .zhHant: "身體", .ko: "신체", .es: "Cuerpo", .fr: "Corps", .de: "Körper", .it: "Corpo", .ptBR: "Corpo", .ru: "Тело", .ar: "الجسم"],
        "mobility": [.ja: "歩行の質", .en: "Mobility", .zhHans: "行动能力", .zhHant: "行動能力", .ko: "보행 능력", .es: "Movilidad", .fr: "Mobilité", .de: "Mobilität", .it: "Mobilità", .ptBR: "Mobilidade", .ru: "Подвижность", .ar: "الحركة"],
        "hearing": [.ja: "聴覚", .en: "Hearing", .zhHans: "听力", .zhHant: "聽力", .ko: "청각", .es: "Audición", .fr: "Audition", .de: "Hören", .it: "Udito", .ptBR: "Audição", .ru: "Слух", .ar: "السمع"],
        "mind": [.ja: "こころ", .en: "Mind", .zhHans: "心理", .zhHant: "心理", .ko: "마음", .es: "Mente", .fr: "Esprit", .de: "Psyche", .it: "Mente", .ptBR: "Mente", .ru: "Психика", .ar: "الحالة الذهنية"],
    ]

    static let aggregation: [String: [Language: String]] = [
        "sum": [.ja: "合計", .en: "sum", .zhHans: "合计", .zhHant: "合計", .ko: "합계", .es: "suma", .fr: "somme", .de: "Summe", .it: "somma", .ptBR: "soma", .ru: "сумма", .ar: "المجموع"],
        "average": [.ja: "平均", .en: "average", .zhHans: "平均", .zhHant: "平均", .ko: "평균", .es: "media", .fr: "moyenne", .de: "Durchschnitt", .it: "media", .ptBR: "média", .ru: "среднее", .ar: "المتوسط"],
        "minMaxAverage": [.ja: "平均/最小/最大", .en: "avg/min/max", .zhHans: "平均/最小/最大", .zhHant: "平均/最小/最大", .ko: "평균/최소/최대", .es: "media/mín/máx", .fr: "moy./min/max", .de: "Ø/Min/Max", .it: "media/min/max", .ptBR: "média/mín/máx", .ru: "сред./мин/макс", .ar: "المتوسط/الأدنى/الأعلى"],
        "latest": [.ja: "当日値", .en: "daily value", .zhHans: "当日数值", .zhHant: "當日數值", .ko: "당일 값", .es: "valor del día", .fr: "valeur du jour", .de: "Tageswert", .it: "valore del giorno", .ptBR: "valor do dia", .ru: "значение за день", .ar: "قيمة اليوم"],
        "sleep": [.ja: "合計と内訳", .en: "total and stages", .zhHans: "合计与各阶段", .zhHant: "合計與各階段", .ko: "합계와 단계별", .es: "total y fases", .fr: "total et phases", .de: "Gesamt und Phasen", .it: "totale e fasi", .ptBR: "total e fases", .ru: "всего и фазы", .ar: "الإجمالي والمراحل"],
        "workoutList": [.ja: "一覧", .en: "list", .zhHans: "列表", .zhHant: "列表", .ko: "목록", .es: "lista", .fr: "liste", .de: "Liste", .it: "elenco", .ptBR: "lista", .ru: "список", .ar: "قائمة"],
        "moodLatest": [.ja: "当日値", .en: "daily value", .zhHans: "当日数值", .zhHant: "當日數值", .ko: "당일 값", .es: "valor del día", .fr: "valeur du jour", .de: "Tageswert", .it: "valore del giorno", .ptBR: "valor do dia", .ru: "значение за день", .ar: "قيمة اليوم"],
    ]

    static let workout: [String: [Language: String]] = [
        "walking": [.ja: "ウォーキング", .en: "Walking", .zhHans: "步行", .zhHant: "步行", .ko: "걷기", .es: "Caminar", .fr: "Marche", .de: "Gehen", .it: "Camminata", .ptBR: "Caminhada", .ru: "Ходьба", .ar: "المشي"],
        "running": [.ja: "ランニング", .en: "Running", .zhHans: "跑步", .zhHant: "跑步", .ko: "달리기", .es: "Correr", .fr: "Course", .de: "Laufen", .it: "Corsa", .ptBR: "Corrida", .ru: "Бег", .ar: "الجري"],
        "cycling": [.ja: "サイクリング", .en: "Cycling", .zhHans: "骑行", .zhHant: "騎行", .ko: "자전거", .es: "Ciclismo", .fr: "Vélo", .de: "Radfahren", .it: "Ciclismo", .ptBR: "Ciclismo", .ru: "Велосипед", .ar: "ركوب الدراجة"],
        "hiking": [.ja: "ハイキング", .en: "Hiking", .zhHans: "徒步", .zhHant: "徒步", .ko: "하이킹", .es: "Senderismo", .fr: "Randonnée", .de: "Wandern", .it: "Escursionismo", .ptBR: "Caminhada na trilha", .ru: "Поход", .ar: "المشي لمسافات طويلة"],
        "swimming": [.ja: "スイミング", .en: "Swimming", .zhHans: "游泳", .zhHant: "游泳", .ko: "수영", .es: "Natación", .fr: "Natation", .de: "Schwimmen", .it: "Nuoto", .ptBR: "Natação", .ru: "Плавание", .ar: "السباحة"],
        "yoga": [.ja: "ヨガ", .en: "Yoga", .zhHans: "瑜伽", .zhHant: "瑜伽", .ko: "요가", .es: "Yoga", .fr: "Yoga", .de: "Yoga", .it: "Yoga", .ptBR: "Yoga", .ru: "Йога", .ar: "اليوغا"],
        "pilates": [.ja: "ピラティス", .en: "Pilates", .zhHans: "普拉提", .zhHant: "皮拉提斯", .ko: "필라테스", .es: "Pilates", .fr: "Pilates", .de: "Pilates", .it: "Pilates", .ptBR: "Pilates", .ru: "Пилатес", .ar: "البيلاتس"],
        "traditionalStrengthTraining": [.ja: "筋力トレーニング", .en: "Strength training", .zhHans: "力量训练", .zhHant: "力量訓練", .ko: "근력 운동", .es: "Entrenamiento de fuerza", .fr: "Musculation", .de: "Krafttraining", .it: "Allenamento di forza", .ptBR: "Musculação", .ru: "Силовая тренировка", .ar: "تمارين القوة"],
        "functionalStrengthTraining": [.ja: "機能的筋力トレーニング", .en: "Functional strength training", .zhHans: "功能性力量训练", .zhHant: "功能性力量訓練", .ko: "기능성 근력 운동", .es: "Fuerza funcional", .fr: "Renforcement fonctionnel", .de: "Funktionelles Krafttraining", .it: "Forza funzionale", .ptBR: "Força funcional", .ru: "Функциональная силовая", .ar: "تمارين القوة الوظيفية"],
        "coreTraining": [.ja: "体幹トレーニング", .en: "Core training", .zhHans: "核心训练", .zhHant: "核心訓練", .ko: "코어 운동", .es: "Entrenamiento del core", .fr: "Gainage", .de: "Core-Training", .it: "Allenamento core", .ptBR: "Treino de core", .ru: "Тренировка кора", .ar: "تمارين المركز"],
        "highIntensityIntervalTraining": [.ja: "HIIT", .en: "HIIT", .zhHans: "HIIT", .zhHant: "HIIT", .ko: "HIIT", .es: "HIIT", .fr: "HIIT", .de: "HIIT", .it: "HIIT", .ptBR: "HIIT", .ru: "HIIT", .ar: "HIIT"],
        "elliptical": [.ja: "エリプティカル", .en: "Elliptical", .zhHans: "椭圆机", .zhHant: "橢圓機", .ko: "일립티컬", .es: "Elíptica", .fr: "Elliptique", .de: "Crosstrainer", .it: "Ellittica", .ptBR: "Elíptico", .ru: "Эллипс", .ar: "الجهاز الإهليلجي"],
        "rowing": [.ja: "ローイング", .en: "Rowing", .zhHans: "划船", .zhHant: "划船", .ko: "로잉", .es: "Remo", .fr: "Rameur", .de: "Rudern", .it: "Vogatore", .ptBR: "Remo", .ru: "Гребля", .ar: "التجديف"],
        "stairClimbing": [.ja: "階段昇降", .en: "Stair climbing", .zhHans: "爬楼梯", .zhHant: "爬樓梯", .ko: "계단 오르기", .es: "Subir escaleras", .fr: "Montée d'escaliers", .de: "Treppensteigen", .it: "Salita scale", .ptBR: "Subida de escadas", .ru: "Подъём по лестнице", .ar: "صعود الدرج"],
        "stairs": [.ja: "ステップ", .en: "Stairs", .zhHans: "台阶", .zhHant: "台階", .ko: "스텝", .es: "Escaleras", .fr: "Escaliers", .de: "Stufen", .it: "Scale", .ptBR: "Escadas", .ru: "Ступени", .ar: "الدرج"],
        "dance": [.ja: "ダンス", .en: "Dance", .zhHans: "舞蹈", .zhHant: "舞蹈", .ko: "댄스", .es: "Baile", .fr: "Danse", .de: "Tanz", .it: "Danza", .ptBR: "Dança", .ru: "Танцы", .ar: "الرقص"],
        "cooldown": [.ja: "クールダウン", .en: "Cooldown", .zhHans: "整理运动", .zhHant: "緩和運動", .ko: "쿨다운", .es: "Vuelta a la calma", .fr: "Retour au calme", .de: "Cool-down", .it: "Defaticamento", .ptBR: "Desaquecimento", .ru: "Заминка", .ar: "التهدئة"],
        "flexibility": [.ja: "ストレッチ", .en: "Flexibility", .zhHans: "拉伸", .zhHant: "伸展", .ko: "스트레칭", .es: "Flexibilidad", .fr: "Étirements", .de: "Beweglichkeit", .it: "Flessibilità", .ptBR: "Flexibilidade", .ru: "Растяжка", .ar: "المرونة"],
        "mixedCardio": [.ja: "有酸素運動", .en: "Mixed cardio", .zhHans: "混合有氧", .zhHant: "混合有氧", .ko: "복합 유산소", .es: "Cardio mixto", .fr: "Cardio mixte", .de: "Gemischtes Cardio", .it: "Cardio misto", .ptBR: "Cardio misto", .ru: "Смешанное кардио", .ar: "كارديو متنوع"],
        "tennis": [.ja: "テニス", .en: "Tennis", .zhHans: "网球", .zhHant: "網球", .ko: "테니스", .es: "Tenis", .fr: "Tennis", .de: "Tennis", .it: "Tennis", .ptBR: "Tênis", .ru: "Теннис", .ar: "التنس"],
        "golf": [.ja: "ゴルフ", .en: "Golf", .zhHans: "高尔夫", .zhHant: "高爾夫", .ko: "골프", .es: "Golf", .fr: "Golf", .de: "Golf", .it: "Golf", .ptBR: "Golfe", .ru: "Гольф", .ar: "الغولف"],
        "basketball": [.ja: "バスケットボール", .en: "Basketball", .zhHans: "篮球", .zhHant: "籃球", .ko: "농구", .es: "Baloncesto", .fr: "Basket", .de: "Basketball", .it: "Basket", .ptBR: "Basquete", .ru: "Баскетбол", .ar: "كرة السلة"],
        "soccer": [.ja: "サッカー", .en: "Soccer", .zhHans: "足球", .zhHant: "足球", .ko: "축구", .es: "Fútbol", .fr: "Football", .de: "Fußball", .it: "Calcio", .ptBR: "Futebol", .ru: "Футбол", .ar: "كرة القدم"],
        "baseball": [.ja: "野球", .en: "Baseball", .zhHans: "棒球", .zhHant: "棒球", .ko: "야구", .es: "Béisbol", .fr: "Baseball", .de: "Baseball", .it: "Baseball", .ptBR: "Beisebol", .ru: "Бейсбол", .ar: "البيسبول"],
        "badminton": [.ja: "バドミントン", .en: "Badminton", .zhHans: "羽毛球", .zhHant: "羽毛球", .ko: "배드민턴", .es: "Bádminton", .fr: "Badminton", .de: "Badminton", .it: "Badminton", .ptBR: "Badminton", .ru: "Бадминтон", .ar: "الريشة الطائرة"],
        "tableTennis": [.ja: "卓球", .en: "Table tennis", .zhHans: "乒乓球", .zhHant: "桌球", .ko: "탁구", .es: "Tenis de mesa", .fr: "Tennis de table", .de: "Tischtennis", .it: "Ping pong", .ptBR: "Tênis de mesa", .ru: "Настольный теннис", .ar: "تنس الطاولة"],
        "boxing": [.ja: "ボクシング", .en: "Boxing", .zhHans: "拳击", .zhHant: "拳擊", .ko: "복싱", .es: "Boxeo", .fr: "Boxe", .de: "Boxen", .it: "Boxe", .ptBR: "Boxe", .ru: "Бокс", .ar: "الملاكمة"],
        "climbing": [.ja: "クライミング", .en: "Climbing", .zhHans: "攀岩", .zhHant: "攀岩", .ko: "클라이밍", .es: "Escalada", .fr: "Escalade", .de: "Klettern", .it: "Arrampicata", .ptBR: "Escalada", .ru: "Скалолазание", .ar: "التسلق"],
        "skatingSports": [.ja: "スケート", .en: "Skating", .zhHans: "滑冰", .zhHant: "溜冰", .ko: "스케이팅", .es: "Patinaje", .fr: "Patinage", .de: "Eislaufen", .it: "Pattinaggio", .ptBR: "Patinação", .ru: "Катание на коньках", .ar: "التزلج"],
        "snowSports": [.ja: "スノースポーツ", .en: "Snow sports", .zhHans: "雪上运动", .zhHant: "雪上運動", .ko: "설상 스포츠", .es: "Deportes de nieve", .fr: "Sports de neige", .de: "Wintersport", .it: "Sport sulla neve", .ptBR: "Esportes na neve", .ru: "Снежный спорт", .ar: "الرياضات الثلجية"],
        "surfingSports": [.ja: "サーフィン", .en: "Surfing", .zhHans: "冲浪", .zhHant: "衝浪", .ko: "서핑", .es: "Surf", .fr: "Surf", .de: "Surfen", .it: "Surf", .ptBR: "Surfe", .ru: "Сёрфинг", .ar: "ركوب الأمواج"],
        "martialArts": [.ja: "武術", .en: "Martial arts", .zhHans: "武术", .zhHant: "武術", .ko: "무술", .es: "Artes marciales", .fr: "Arts martiaux", .de: "Kampfsport", .it: "Arti marziali", .ptBR: "Artes marciais", .ru: "Боевые искусства", .ar: "فنون القتال"],
        "mindAndBody": [.ja: "心と体", .en: "Mind and body", .zhHans: "身心练习", .zhHant: "身心練習", .ko: "마음과 몸", .es: "Mente y cuerpo", .fr: "Corps et esprit", .de: "Körper und Geist", .it: "Mente e corpo", .ptBR: "Mente e corpo", .ru: "Тело и разум", .ar: "الجسد والعقل"],
        "preparationAndRecovery": [.ja: "準備と回復", .en: "Preparation and recovery", .zhHans: "准备与恢复", .zhHant: "準備與恢復", .ko: "준비와 회복", .es: "Preparación y recuperación", .fr: "Préparation et récupération", .de: "Vorbereitung und Erholung", .it: "Preparazione e recupero", .ptBR: "Preparação e recuperação", .ru: "Подготовка и восстановление", .ar: "التحضير والتعافي"],
        "wheelchairWalkPace": [.ja: "車椅子（ウォーキングペース）", .en: "Wheelchair walk pace", .zhHans: "轮椅（步行速度）", .zhHant: "輪椅（步行速度）", .ko: "휠체어(걷기 속도)", .es: "Silla de ruedas (ritmo de marcha)", .fr: "Fauteuil roulant (allure marche)", .de: "Rollstuhl (Gehtempo)", .it: "Sedia a rotelle (passo di marcia)", .ptBR: "Cadeira de rodas (ritmo de caminhada)", .ru: "Коляска (темп ходьбы)", .ar: "كرسي متحرك (سرعة المشي)"],
        "wheelchairRunPace": [.ja: "車椅子（ランニングペース）", .en: "Wheelchair run pace", .zhHans: "轮椅（跑步速度）", .zhHant: "輪椅（跑步速度）", .ko: "휠체어(달리기 속도)", .es: "Silla de ruedas (ritmo de carrera)", .fr: "Fauteuil roulant (allure course)", .de: "Rollstuhl (Lauftempo)", .it: "Sedia a rotelle (passo di corsa)", .ptBR: "Cadeira de rodas (ritmo de corrida)", .ru: "Коляска (темп бега)", .ar: "كرسي متحرك (سرعة الجري)"],
        "other": [.ja: "その他", .en: "Other", .zhHans: "其他", .zhHant: "其他", .ko: "기타", .es: "Otro", .fr: "Autre", .de: "Sonstiges", .it: "Altro", .ptBR: "Outro", .ru: "Другое", .ar: "أخرى"],
    ]

    static let mood: [String: [Language: String]] = [
        "veryUnpleasant": [.ja: "とても不快", .en: "very unpleasant", .zhHans: "非常不适", .zhHant: "非常不適", .ko: "매우 불쾌", .es: "muy desagradable", .fr: "très désagréable", .de: "sehr unangenehm", .it: "molto spiacevole", .ptBR: "muito desagradável", .ru: "очень неприятно", .ar: "غير سار جداً"],
        "unpleasant": [.ja: "不快", .en: "unpleasant", .zhHans: "不适", .zhHant: "不適", .ko: "불쾌", .es: "desagradable", .fr: "désagréable", .de: "unangenehm", .it: "spiacevole", .ptBR: "desagradável", .ru: "неприятно", .ar: "غير سار"],
        "slightlyUnpleasant": [.ja: "やや不快", .en: "slightly unpleasant", .zhHans: "略微不适", .zhHant: "略微不適", .ko: "약간 불쾌", .es: "algo desagradable", .fr: "légèrement désagréable", .de: "etwas unangenehm", .it: "leggermente spiacevole", .ptBR: "um pouco desagradável", .ru: "слегка неприятно", .ar: "غير سار قليلاً"],
        "neutral": [.ja: "ふつう", .en: "neutral", .zhHans: "一般", .zhHant: "一般", .ko: "보통", .es: "neutral", .fr: "neutre", .de: "neutral", .it: "neutro", .ptBR: "neutro", .ru: "нейтрально", .ar: "محايد"],
        "slightlyPleasant": [.ja: "やや快い", .en: "slightly pleasant", .zhHans: "略微愉快", .zhHant: "略微愉快", .ko: "약간 쾌적", .es: "algo agradable", .fr: "légèrement agréable", .de: "etwas angenehm", .it: "leggermente piacevole", .ptBR: "um pouco agradável", .ru: "слегка приятно", .ar: "سار قليلاً"],
        "pleasant": [.ja: "快い", .en: "pleasant", .zhHans: "愉快", .zhHant: "愉快", .ko: "쾌적", .es: "agradable", .fr: "agréable", .de: "angenehm", .it: "piacevole", .ptBR: "agradável", .ru: "приятно", .ar: "سار"],
        "veryPleasant": [.ja: "とても快い", .en: "very pleasant", .zhHans: "非常愉快", .zhHant: "非常愉快", .ko: "매우 쾌적", .es: "muy agradable", .fr: "très agréable", .de: "sehr angenehm", .it: "molto piacevole", .ptBR: "muito agradável", .ru: "очень приятно", .ar: "سار جداً"],
    ]

    static let askLines: [String: [Language: [String]]] = [
        "general": [
            .ja: ["以下は私のiPhoneのヘルスケアに記録されている、この期間のデータです。", "次のことを教えてください。", "1. この期間の全体的な傾向（良くなっている点・悪くなっている点）", "2. ほかの日と比べて明らかにずれている日と、その日に何があったと考えられるか", "3. 数字から見て、生活のなかで続けるとよさそうなこと", "__DISCLAIMER__"],
            .en: ["Below is my health data exported from the Health app on my iPhone for this period.", "Please tell me:", "1. The overall trends in this period (what improved, what got worse)", "2. Days that clearly stand out from the rest, and what might explain them", "3. Habits worth keeping, based on what the numbers show", "__DISCLAIMER__"],
            .zhHans: ["以下是我 iPhone“健康”App 中这段时间的记录。", "请告诉我：", "1. 这段时间的整体趋势（哪些在好转，哪些在变差）", "2. 明显偏离其他日子的那些天，以及可能的原因", "3. 从数据来看，生活中值得继续保持的习惯", "__DISCLAIMER__"],
            .zhHant: ["以下是我 iPhone「健康」App 中這段時間的記錄。", "請告訴我：", "1. 這段時間的整體趨勢（哪些在好轉，哪些在變差）", "2. 明顯偏離其他日子的那幾天，以及可能的原因", "3. 從數據來看，生活中值得繼續保持的習慣", "__DISCLAIMER__"],
            .ko: ["다음은 제 iPhone 건강 앱에 기록된 이 기간의 데이터입니다.", "다음을 알려주세요:", "1. 이 기간의 전반적인 경향(좋아진 점과 나빠진 점)", "2. 다른 날과 뚜렷하게 다른 날과, 그 이유로 생각할 수 있는 것", "3. 숫자로 볼 때 생활에서 계속하면 좋을 것", "__DISCLAIMER__"],
            .es: ["A continuación están mis datos de salud exportados de la app Salud de mi iPhone para este periodo.", "Dime, por favor:", "1. Las tendencias generales de este periodo (qué mejoró y qué empeoró)", "2. Los días que destacan claramente del resto y qué podría explicarlos", "3. Hábitos que conviene mantener, según lo que muestran los números", "__DISCLAIMER__"],
            .fr: ["Voici mes données de santé exportées depuis l'app Santé de mon iPhone pour cette période.", "Dites-moi :", "1. Les tendances générales sur cette période (ce qui s'améliore, ce qui se dégrade)", "2. Les jours qui se détachent nettement des autres, et ce qui pourrait l'expliquer", "3. Les habitudes à conserver, d'après ce que montrent les chiffres", "__DISCLAIMER__"],
            .de: ["Hier sind meine Gesundheitsdaten aus der Health-App meines iPhones für diesen Zeitraum.", "Bitte sag mir:", "1. Die allgemeinen Trends in diesem Zeitraum (was besser wurde, was schlechter)", "2. Tage, die deutlich aus dem Rahmen fallen, und was sie erklären könnte", "3. Gewohnheiten, die sich laut den Zahlen lohnen", "__DISCLAIMER__"],
            .it: ["Di seguito i miei dati di salute esportati dall'app Salute del mio iPhone per questo periodo.", "Dimmi:", "1. Le tendenze generali del periodo (cosa è migliorato e cosa è peggiorato)", "2. I giorni che si distinguono nettamente dagli altri e cosa potrebbe spiegarli", "3. Le abitudini da mantenere, in base a ciò che mostrano i numeri", "__DISCLAIMER__"],
            .ptBR: ["Abaixo estão meus dados de saúde exportados do app Saúde do meu iPhone neste período.", "Por favor, me diga:", "1. As tendências gerais do período (o que melhorou e o que piorou)", "2. Os dias que se destacam claramente dos demais e o que pode explicá-los", "3. Hábitos que vale a pena manter, de acordo com os números", "__DISCLAIMER__"],
            .ru: ["Ниже — мои данные о здоровье из приложения «Здоровье» на iPhone за этот период.", "Подскажите, пожалуйста:", "1. Общие тенденции за период (что улучшилось, что ухудшилось)", "2. Дни, которые заметно выделяются среди остальных, и чем это можно объяснить", "3. Привычки, которые стоит сохранить, судя по цифрам", "__DISCLAIMER__"],
            .ar: ["في ما يلي بيانات صحتي المُصدَّرة من تطبيق «الصحة» على iPhone خلال هذه الفترة.", "أخبرني من فضلك:", "1. الاتجاهات العامة في هذه الفترة (ما الذي تحسّن وما الذي ساء)", "2. الأيام التي تختلف بوضوح عن غيرها، وما الذي قد يفسّرها", "3. العادات التي يُستحسن الاستمرار فيها بحسب ما تُظهره الأرقام", "__DISCLAIMER__"],
        ],
        "sleep": [
            .ja: ["以下は私の睡眠を中心とした記録です。", "次のことを教えてください。", "1. 睡眠時間と、その内訳（深い・レム・コア）の傾向", "2. よく眠れた日とそうでない日で、日中の活動量や心拍にどんな違いがあるか", "3. 眠りをよくするために、この数字から言えること", "__DISCLAIMER__"],
            .en: ["Below is my sleep-focused health data.", "Please tell me:", "1. Trends in total sleep and its stages (deep, REM, core)", "2. How daytime activity and heart rate differ between good and bad nights", "3. What these numbers suggest I could try to sleep better", "__DISCLAIMER__"],
            .zhHans: ["以下是我以睡眠为主的记录。", "请告诉我：", "1. 睡眠总时长及各阶段（深睡、REM、核心）的趋势", "2. 睡得好的日子和不好的日子，白天活动量与心率有什么不同", "3. 从这些数字来看，为了睡得更好可以尝试什么", "__DISCLAIMER__"],
            .zhHant: ["以下是我以睡眠為主的記錄。", "請告訴我：", "1. 睡眠總時長及各階段（深睡、REM、核心）的趨勢", "2. 睡得好的日子和不好的日子，白天活動量與心率有什麼不同", "3. 從這些數字來看，為了睡得更好可以嘗試什麼", "__DISCLAIMER__"],
            .ko: ["다음은 수면을 중심으로 한 제 기록입니다.", "다음을 알려주세요:", "1. 총 수면 시간과 단계별(깊은수면, REM, 코어) 경향", "2. 잘 잔 날과 그렇지 않은 날에 낮 활동량과 심박수가 어떻게 다른지", "3. 이 수치로 볼 때 더 잘 자기 위해 시도해 볼 만한 것", "__DISCLAIMER__"],
            .es: ["A continuación están mis datos centrados en el sueño.", "Dime, por favor:", "1. Las tendencias del sueño total y de sus fases (profundo, REM, central)", "2. En qué se diferencian la actividad diurna y la frecuencia cardíaca entre las noches buenas y las malas", "3. Qué sugieren estos números que podría probar para dormir mejor", "__DISCLAIMER__"],
            .fr: ["Voici mes données centrées sur le sommeil.", "Dites-moi :", "1. Les tendances du sommeil total et de ses phases (profond, REM, central)", "2. Ce qui distingue l'activité diurne et la fréquence cardiaque entre les bonnes et les mauvaises nuits", "3. Ce que ces chiffres suggèrent d'essayer pour mieux dormir", "__DISCLAIMER__"],
            .de: ["Hier sind meine auf den Schlaf bezogenen Daten.", "Bitte sag mir:", "1. Trends bei der Gesamtschlafdauer und den Phasen (Tief, REM, Kern)", "2. Wie sich Tagesaktivität und Herzfrequenz zwischen guten und schlechten Nächten unterscheiden", "3. Was diese Zahlen nahelegen, um besser zu schlafen", "__DISCLAIMER__"],
            .it: ["Di seguito i miei dati incentrati sul sonno.", "Dimmi:", "1. Le tendenze del sonno totale e delle sue fasi (profondo, REM, centrale)", "2. In cosa differiscono attività diurna e frequenza cardiaca tra le notti buone e quelle cattive", "3. Cosa suggeriscono questi numeri per dormire meglio", "__DISCLAIMER__"],
            .ptBR: ["Abaixo estão meus dados focados no sono.", "Por favor, me diga:", "1. As tendências do sono total e de suas fases (profundo, REM, central)", "2. Como a atividade diurna e a frequência cardíaca diferem entre as noites boas e ruins", "3. O que esses números sugerem que eu poderia tentar para dormir melhor", "__DISCLAIMER__"],
            .ru: ["Ниже — мои данные, связанные со сном.", "Подскажите, пожалуйста:", "1. Тенденции общей продолжительности сна и его фаз (глубокий, REM, основной)", "2. Чем отличаются дневная активность и пульс в хорошие и плохие ночи", "3. Что эти цифры подсказывают попробовать, чтобы спать лучше", "__DISCLAIMER__"],
            .ar: ["في ما يلي بياناتي المتعلقة بالنوم.", "أخبرني من فضلك:", "1. اتجاهات إجمالي النوم ومراحله (العميق وREM والأساسي)", "2. كيف يختلف نشاط النهار ومعدل ضربات القلب بين الليالي الجيدة والسيئة", "3. ما الذي تقترحه هذه الأرقام لتحسين نومي", "__DISCLAIMER__"],
        ],
        "training": [
            .ja: ["以下は私の運動と回復に関する記録です。", "次のことを教えてください。", "1. 運動量の推移と、負荷が高すぎた時期・少なすぎた時期", "2. 安静時心拍・心拍変動・睡眠から見て、疲れが抜けているかどうか", "3. これを踏まえた、次の1ヶ月の運動の組み立て方", "__DISCLAIMER__"],
            .en: ["Below is my training and recovery data.", "Please tell me:", "1. How my training load changed, and periods that were too hard or too light", "2. Whether I am recovering, based on resting heart rate, HRV and sleep", "3. How to structure the next month of training given all this", "__DISCLAIMER__"],
            .zhHans: ["以下是我关于训练与恢复的记录。", "请告诉我：", "1. 训练量的变化，以及负荷过大或过小的时期", "2. 从静息心率、心率变异性和睡眠来看，疲劳是否已经恢复", "3. 据此如何安排接下来一个月的训练", "__DISCLAIMER__"],
            .zhHant: ["以下是我關於訓練與恢復的記錄。", "請告訴我：", "1. 訓練量的變化，以及負荷過大或過小的時期", "2. 從靜息心率、心率變異性和睡眠來看，疲勞是否已經恢復", "3. 據此如何安排接下來一個月的訓練", "__DISCLAIMER__"],
            .ko: ["다음은 제 운동과 회복에 관한 기록입니다.", "다음을 알려주세요:", "1. 운동량의 변화와, 부하가 너무 컸던 시기·너무 적었던 시기", "2. 안정 시 심박수, 심박 변이도, 수면으로 볼 때 피로가 풀렸는지", "3. 이를 토대로 다음 한 달의 운동을 어떻게 구성하면 좋을지", "__DISCLAIMER__"],
            .es: ["A continuación están mis datos de entrenamiento y recuperación.", "Dime, por favor:", "1. Cómo cambió mi carga de entrenamiento y qué periodos fueron demasiado duros o demasiado suaves", "2. Si me estoy recuperando, según la frecuencia cardíaca en reposo, la variabilidad y el sueño", "3. Cómo organizar el próximo mes de entrenamiento con todo esto", "__DISCLAIMER__"],
            .fr: ["Voici mes données d'entraînement et de récupération.", "Dites-moi :", "1. Comment ma charge d'entraînement a évolué, et les périodes trop dures ou trop légères", "2. Si je récupère, d'après la fréquence cardiaque au repos, la variabilité et le sommeil", "3. Comment organiser le mois d'entraînement à venir", "__DISCLAIMER__"],
            .de: ["Hier sind meine Trainings- und Erholungsdaten.", "Bitte sag mir:", "1. Wie sich meine Trainingsbelastung verändert hat und welche Phasen zu hart oder zu leicht waren", "2. Ob ich mich erhole – anhand von Ruheherzfrequenz, HRV und Schlaf", "3. Wie ich den nächsten Trainingsmonat aufbauen sollte", "__DISCLAIMER__"],
            .it: ["Di seguito i miei dati di allenamento e recupero.", "Dimmi:", "1. Come è cambiato il mio carico di allenamento e quali periodi sono stati troppo intensi o troppo leggeri", "2. Se sto recuperando, in base a frequenza cardiaca a riposo, variabilità e sonno", "3. Come impostare il prossimo mese di allenamento", "__DISCLAIMER__"],
            .ptBR: ["Abaixo estão meus dados de treino e recuperação.", "Por favor, me diga:", "1. Como minha carga de treino mudou e quais períodos foram pesados ou leves demais", "2. Se estou me recuperando, com base na frequência cardíaca em repouso, na variabilidade e no sono", "3. Como montar o próximo mês de treino considerando tudo isso", "__DISCLAIMER__"],
            .ru: ["Ниже — мои данные о тренировках и восстановлении.", "Подскажите, пожалуйста:", "1. Как менялась нагрузка и какие периоды были слишком тяжёлыми или слишком лёгкими", "2. Восстанавливаюсь ли я — судя по пульсу покоя, вариабельности и сну", "3. Как построить следующий месяц тренировок с учётом этого", "__DISCLAIMER__"],
            .ar: ["في ما يلي بياناتي عن التمارين والتعافي.", "أخبرني من فضلك:", "1. كيف تغيّر حمل التمرين لديّ، وما الفترات التي كانت شاقة أو خفيفة أكثر من اللازم", "2. هل أتعافى، استناداً إلى معدل ضربات القلب أثناء الراحة وتغيّره والنوم", "3. كيف أُنظّم شهر التمارين المقبل بناءً على ذلك", "__DISCLAIMER__"],
        ],
        "condition": [
            .ja: ["以下は私の直近の体調に関する記録です。", "次のことを教えてください。", "1. 安静時心拍・心拍変動・呼吸数・皮膚温から見て、ふだんと違っていた時期", "2. その時期の睡眠や活動量に、いっしょに起きていた変化があるか", "3. 記録のとり方として、足したほうがよい項目", "__DISCLAIMER__"],
            .en: ["Below is my recent health data.", "Please tell me:", "1. Periods that differ from my baseline in resting heart rate, HRV, respiratory rate and skin temperature", "2. Whether sleep or activity changed at the same time", "3. What else I should start recording", "__DISCLAIMER__"],
            .zhHans: ["以下是我最近的身体状况记录。", "请告诉我：", "1. 从静息心率、心率变异性、呼吸频率和皮温来看，与平时不同的时期", "2. 那段时间的睡眠或活动量是否同时发生了变化", "3. 作为记录方式，还应该补充哪些项目", "__DISCLAIMER__"],
            .zhHant: ["以下是我最近的身體狀況記錄。", "請告訴我：", "1. 從靜息心率、心率變異性、呼吸頻率和皮溫來看，與平時不同的時期", "2. 那段時間的睡眠或活動量是否同時發生了變化", "3. 作為記錄方式，還應該補充哪些項目", "__DISCLAIMER__"],
            .ko: ["다음은 최근 제 컨디션에 관한 기록입니다.", "다음을 알려주세요:", "1. 안정 시 심박수, 심박 변이도, 호흡수, 피부 온도로 볼 때 평소와 달랐던 시기", "2. 그 시기에 수면이나 활동량에도 함께 일어난 변화가 있는지", "3. 기록 항목으로 추가하면 좋을 것", "__DISCLAIMER__"],
            .es: ["A continuación están mis datos de salud recientes.", "Dime, por favor:", "1. Los periodos que se apartan de mi línea base en frecuencia cardíaca en reposo, variabilidad, frecuencia respiratoria y temperatura de la piel", "2. Si el sueño o la actividad cambiaron al mismo tiempo", "3. Qué otros datos debería empezar a registrar", "__DISCLAIMER__"],
            .fr: ["Voici mes données de santé récentes.", "Dites-moi :", "1. Les périodes qui s'écartent de ma normale pour la fréquence cardiaque au repos, la variabilité, la fréquence respiratoire et la température cutanée", "2. Si le sommeil ou l'activité ont changé au même moment", "3. Quelles autres données je devrais commencer à enregistrer", "__DISCLAIMER__"],
            .de: ["Hier sind meine aktuellen Gesundheitsdaten.", "Bitte sag mir:", "1. Zeiträume, die bei Ruheherzfrequenz, HRV, Atemfrequenz und Hauttemperatur von meinem Normalwert abweichen", "2. Ob sich Schlaf oder Aktivität zur gleichen Zeit verändert haben", "3. Was ich zusätzlich aufzeichnen sollte", "__DISCLAIMER__"],
            .it: ["Di seguito i miei dati di salute recenti.", "Dimmi:", "1. I periodi che si discostano dalla mia normalità per frequenza cardiaca a riposo, variabilità, frequenza respiratoria e temperatura cutanea", "2. Se sonno o attività sono cambiati nello stesso momento", "3. Quali altri dati dovrei iniziare a registrare", "__DISCLAIMER__"],
            .ptBR: ["Abaixo estão meus dados de saúde recentes.", "Por favor, me diga:", "1. Os períodos que fogem do meu padrão em frequência cardíaca em repouso, variabilidade, frequência respiratória e temperatura da pele", "2. Se o sono ou a atividade mudaram ao mesmo tempo", "3. Que outros dados eu deveria começar a registrar", "__DISCLAIMER__"],
            .ru: ["Ниже — мои недавние данные о здоровье.", "Подскажите, пожалуйста:", "1. Периоды, отличающиеся от моей нормы по пульсу покоя, вариабельности, частоте дыхания и температуре кожи", "2. Менялись ли в это же время сон или активность", "3. Что ещё мне стоит начать записывать", "__DISCLAIMER__"],
            .ar: ["في ما يلي بياناتي الصحية الأخيرة.", "أخبرني من فضلك:", "1. الفترات التي تختلف عن معدّلي المعتاد في معدل ضربات القلب أثناء الراحة وتغيّره ومعدل التنفس وحرارة الجلد", "2. هل تغيّر النوم أو النشاط في الوقت نفسه", "3. ما البيانات الأخرى التي ينبغي أن أبدأ بتسجيلها", "__DISCLAIMER__"],
        ],
        "mind": [
            .ja: ["以下は私の気分の記録と、そのころの体の記録です。", "次のことを教えてください。", "1. 気分の記録と、睡眠・活動量・心拍変動のあいだに見える関係", "2. 気分が下がっていた時期に、体の記録のほうで何が起きていたか", "3. 調子を整えるために、この数字から言えること", "__DISCLAIMER__"],
            .en: ["Below are my state of mind entries and my body data from the same period.", "Please tell me:", "1. Relationships between my mood and sleep, activity and HRV", "2. What my body data was doing during periods when my mood was low", "3. What these numbers suggest I could do to feel steadier", "__DISCLAIMER__"],
            .zhHans: ["以下是我的心情记录，以及同一时期的身体数据。", "请告诉我：", "1. 心情记录与睡眠、活动量、心率变异性之间的关系", "2. 心情低落的时期，身体数据上发生了什么", "3. 从这些数字来看，为了让状态更平稳可以做什么", "__DISCLAIMER__"],
            .zhHant: ["以下是我的心情記錄，以及同一時期的身體數據。", "請告訴我：", "1. 心情記錄與睡眠、活動量、心率變異性之間的關係", "2. 心情低落的時期，身體數據上發生了什麼", "3. 從這些數字來看，為了讓狀態更平穩可以做什麼", "__DISCLAIMER__"],
            .ko: ["다음은 제 기분 기록과 같은 시기의 신체 기록입니다.", "다음을 알려주세요:", "1. 기분 기록과 수면·활동량·심박 변이도 사이에 보이는 관계", "2. 기분이 가라앉았던 시기에 신체 기록에서는 무슨 일이 있었는지", "3. 컨디션을 고르게 하기 위해 이 수치로 말할 수 있는 것", "__DISCLAIMER__"],
            .es: ["A continuación están mis registros de estado de ánimo y mis datos corporales del mismo periodo.", "Dime, por favor:", "1. Las relaciones entre mi ánimo y el sueño, la actividad y la variabilidad cardíaca", "2. Qué hacían mis datos corporales en los periodos de ánimo bajo", "3. Qué sugieren estos números para sentirme más estable", "__DISCLAIMER__"],
            .fr: ["Voici mes relevés d'état d'esprit et mes données corporelles de la même période.", "Dites-moi :", "1. Les liens entre mon humeur et le sommeil, l'activité et la variabilité cardiaque", "2. Ce que faisaient mes données corporelles pendant les périodes de baisse de moral", "3. Ce que ces chiffres suggèrent pour me sentir plus stable", "__DISCLAIMER__"],
            .de: ["Hier sind meine Einträge zum Gemütszustand und meine Körperdaten aus demselben Zeitraum.", "Bitte sag mir:", "1. Zusammenhänge zwischen meiner Stimmung und Schlaf, Aktivität und HRV", "2. Was meine Körperdaten in Phasen gedrückter Stimmung gemacht haben", "3. Was diese Zahlen nahelegen, um ausgeglichener zu sein", "__DISCLAIMER__"],
            .it: ["Di seguito i miei stati d'animo registrati e i dati corporei dello stesso periodo.", "Dimmi:", "1. Le relazioni tra il mio umore e sonno, attività e variabilità cardiaca", "2. Cosa facevano i miei dati corporei nei periodi di umore basso", "3. Cosa suggeriscono questi numeri per sentirmi più stabile", "__DISCLAIMER__"],
            .ptBR: ["Abaixo estão meus registros de estado emocional e meus dados corporais do mesmo período.", "Por favor, me diga:", "1. As relações entre meu humor e o sono, a atividade e a variabilidade cardíaca", "2. O que meus dados corporais mostravam nos períodos de humor baixo", "3. O que esses números sugerem para eu me sentir mais estável", "__DISCLAIMER__"],
            .ru: ["Ниже — мои записи о душевном состоянии и данные тела за тот же период.", "Подскажите, пожалуйста:", "1. Связи между настроением и сном, активностью и вариабельностью пульса", "2. Что происходило с данными тела в периоды пониженного настроения", "3. Что эти цифры подсказывают, чтобы чувствовать себя ровнее", "__DISCLAIMER__"],
            .ar: ["في ما يلي سجلات حالتي الذهنية وبيانات جسمي في الفترة نفسها.", "أخبرني من فضلك:", "1. العلاقات بين مزاجي والنوم والنشاط وتغيّر معدل ضربات القلب", "2. ماذا كانت تُظهر بيانات جسمي في الفترات التي تراجع فيها مزاجي", "3. ما الذي تقترحه هذه الأرقام كي أشعر باستقرار أكبر", "__DISCLAIMER__"],
        ],
        "everything": [
            .ja: ["以下は私のiPhoneのヘルスケアにある、この期間の記録すべてです。", "気づいたことを自由に指摘してください。", "__DISCLAIMER__"],
            .en: ["Below is everything recorded in the Health app on my iPhone for this period.", "Please point out anything you notice.", "__DISCLAIMER__"],
            .zhHans: ["以下是我 iPhone“健康”App 中这段时间的全部记录。", "请自由指出你注意到的任何事情。", "__DISCLAIMER__"],
            .zhHant: ["以下是我 iPhone「健康」App 中這段時間的全部記錄。", "請自由指出你注意到的任何事情。", "__DISCLAIMER__"],
            .ko: ["다음은 제 iPhone 건강 앱에 있는 이 기간의 모든 기록입니다.", "눈에 띄는 점을 자유롭게 지적해 주세요.", "__DISCLAIMER__"],
            .es: ["A continuación está todo lo registrado en la app Salud de mi iPhone para este periodo.", "Señala cualquier cosa que te llame la atención.", "__DISCLAIMER__"],
            .fr: ["Voici tout ce qui est enregistré dans l'app Santé de mon iPhone pour cette période.", "Signalez-moi tout ce qui vous semble notable.", "__DISCLAIMER__"],
            .de: ["Hier ist alles, was die Health-App meines iPhones für diesen Zeitraum aufgezeichnet hat.", "Weise mich bitte auf alles hin, was dir auffällt.", "__DISCLAIMER__"],
            .it: ["Di seguito tutto ciò che è registrato nell'app Salute del mio iPhone per questo periodo.", "Segnalami qualsiasi cosa noti.", "__DISCLAIMER__"],
            .ptBR: ["Abaixo está tudo o que está registrado no app Saúde do meu iPhone neste período.", "Aponte qualquer coisa que você notar.", "__DISCLAIMER__"],
            .ru: ["Ниже — всё, что записано в приложении «Здоровье» на моём iPhone за этот период.", "Отметьте, пожалуйста, всё, что покажется вам заметным.", "__DISCLAIMER__"],
            .ar: ["في ما يلي كل ما هو مسجَّل في تطبيق «الصحة» على iPhone خلال هذه الفترة.", "أشِر إلى أي شيء تلاحظه.", "__DISCLAIMER__"],
        ],
    ]
}
