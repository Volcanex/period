"""Atlas tracker registry and condition pack definitions."""

from core.contracts import EvidenceReference, TrackerDefinition, TrackerPack

VERSION = "2026.05.02"

_BASE_EVIDENCE = EvidenceReference(
    source="Period Atlas v1 tracker taxonomy",
    assumption="Trackers support symptom recording and clinician conversations, not diagnosis.",
    confidence=0.45,
    version=VERSION,
    review_status="draft",
)


def _tracker(
    code: str,
    display_name: str,
    value_type: str,
    validation_schema: dict,
    *,
    unit: str | None = None,
    allowed_values: list[str] | None = None,
    temporal_grain: str = "day",
    calendar_layer: str = "symptom",
    calendar_priority: int = 50,
    fhir_mapping: dict | None = None,
    healthkit_mapping: dict | None = None,
    health_connect_mapping: dict | None = None,
) -> TrackerDefinition:
    return TrackerDefinition(
        code=code,
        display_name=display_name,
        value_type=value_type,  # type: ignore[arg-type]
        temporal_grain=temporal_grain,  # type: ignore[arg-type]
        calendar_layer=calendar_layer,  # type: ignore[arg-type]
        calendar_priority=calendar_priority,
        unit=unit,
        allowed_values=allowed_values,
        validation_schema=validation_schema,
        fhir_mapping=fhir_mapping,
        healthkit_mapping=healthkit_mapping,
        health_connect_mapping=health_connect_mapping,
        version=VERSION,
        evidence=[_BASE_EVIDENCE],
    )


def tracker_definitions() -> list[TrackerDefinition]:
    severity = ["none", "mild", "moderate", "severe"]
    yes_no_unknown = ["yes", "no", "unknown"]
    return [
        _tracker(
            "period_bleeding",
            "Period bleeding",
            "enum",
            {"type": "string", "enum": ["none", "spotting", "light", "medium", "heavy"]},
            allowed_values=["none", "spotting", "light", "medium", "heavy"],
            calendar_layer="bleeding",
            calendar_priority=95,
            fhir_mapping={"resource": "Observation", "code": "menstrual-bleeding"},
        ),
        _tracker("spotting", "Spotting", "boolean", {"type": "boolean"}, calendar_layer="bleeding", calendar_priority=85),
        _tracker("cramps", "Cramps", "enum", {"type": "string", "enum": severity}, allowed_values=severity),
        _tracker("pelvic_pain", "Pelvic pain", "enum", {"type": "string", "enum": severity}, allowed_values=severity),
        _tracker("pain_with_sex", "Pain with sex", "enum", {"type": "string", "enum": severity}, allowed_values=severity),
        _tracker("bowel_symptoms", "Bowel symptoms", "enum", {"type": "string", "enum": ["none", "constipation", "diarrhea", "painful", "other"]}, allowed_values=["none", "constipation", "diarrhea", "painful", "other"]),
        _tracker("bladder_symptoms", "Bladder symptoms", "enum", {"type": "string", "enum": ["none", "frequency", "urgency", "pain", "other"]}, allowed_values=["none", "frequency", "urgency", "pain", "other"]),
        _tracker("fatigue", "Fatigue", "enum", {"type": "string", "enum": severity}, allowed_values=severity),
        _tracker("migraine", "Migraine or headache", "enum", {"type": "string", "enum": severity}, allowed_values=severity),
        _tracker("breast_tenderness", "Breast tenderness", "enum", {"type": "string", "enum": severity}, allowed_values=severity),
        _tracker("bloating", "Bloating", "enum", {"type": "string", "enum": severity}, allowed_values=severity),
        _tracker("mood", "Mood", "enum", {"type": "string", "enum": ["low", "neutral", "good", "anxious", "irritable"]}, allowed_values=["low", "neutral", "good", "anxious", "irritable"]),
        _tracker("anxiety_severity", "Anxiety severity", "enum", {"type": "string", "enum": severity}, allowed_values=severity),
        _tracker("depression_severity", "Depression severity", "enum", {"type": "string", "enum": severity}, allowed_values=severity),
        _tracker("irritability", "Irritability", "enum", {"type": "string", "enum": severity}, allowed_values=severity),
        _tracker("energy", "Energy", "enum", {"type": "string", "enum": ["low", "normal", "high"]}, allowed_values=["low", "normal", "high"]),
        _tracker("sleep_hours", "Sleep hours", "decimal", {"type": "number", "minimum": 0, "maximum": 24}, unit="hours", calendar_layer="context", calendar_priority=30),
        _tracker("cervical_mucus", "Cervical mucus", "enum", {"type": "string", "enum": ["dry", "sticky", "creamy", "watery", "egg_white"]}, allowed_values=["dry", "sticky", "creamy", "watery", "egg_white"]),
        _tracker("sex", "Sex", "boolean", {"type": "boolean"}),
        _tracker("medication", "Medication or supplement", "string", {"type": "string", "maxLength": 160}),
        _tracker(
            "basal_body_temperature",
            "Basal body temperature",
            "decimal",
            {"type": "number", "minimum": 30, "maximum": 45},
            unit="celsius",
            calendar_layer="temperature",
            calendar_priority=65,
            fhir_mapping={"resource": "Observation", "code": "body-temperature"},
            healthkit_mapping={"quantity_type": "bodyTemperature"},
            health_connect_mapping={"record_type": "BodyTemperatureRecord"},
        ),
        _tracker("weight", "Weight", "decimal", {"type": "number", "minimum": 20, "maximum": 400}, unit="kg", calendar_layer="context", calendar_priority=25),
        _tracker("note", "Note", "string", {"type": "string", "maxLength": 1000}, calendar_layer="context", calendar_priority=10),
        _tracker("contraception_use", "Contraception use", "enum", {"type": "string", "enum": ["none", "pill", "iud", "implant", "injection", "patch", "ring", "barrier", "other"]}, allowed_values=["none", "pill", "iud", "implant", "injection", "patch", "ring", "barrier", "other"]),
        _tracker("contraception_start", "Contraception start", "date", {"type": "string", "format": "date"}, calendar_layer="context", calendar_priority=70),
        _tracker("contraception_stop", "Contraception stop", "date", {"type": "string", "format": "date"}, calendar_layer="context", calendar_priority=70),
        _tracker("missed_contraception", "Missed contraception", "boolean", {"type": "boolean"}, calendar_layer="context", calendar_priority=75),
        _tracker("pregnancy_test", "Pregnancy test", "enum", {"type": "string", "enum": ["negative", "positive", "invalid"]}, allowed_values=["negative", "positive", "invalid"]),
        _tracker("ovulation_test", "Ovulation test", "enum", {"type": "string", "enum": ["negative", "positive", "peak", "invalid"]}, allowed_values=["negative", "positive", "peak", "invalid"]),
        _tracker("postpartum_status", "Postpartum status", "boolean", {"type": "boolean"}),
        _tracker("lactation_status", "Lactation status", "boolean", {"type": "boolean"}),
        _tracker("hot_flashes", "Hot flashes", "enum", {"type": "string", "enum": severity}, allowed_values=severity),
        _tracker("night_sweats", "Night sweats", "enum", {"type": "string", "enum": severity}, allowed_values=severity),
        _tracker("vaginal_dryness", "Vaginal dryness", "enum", {"type": "string", "enum": severity}, allowed_values=severity),
        _tracker("cycle_pattern_change", "Cycle pattern change", "enum", {"type": "string", "enum": yes_no_unknown}, allowed_values=yes_no_unknown),
        _tracker("acne_severity", "Acne severity", "enum", {"type": "string", "enum": severity}, allowed_values=severity),
        _tracker("hair_growth", "Unwanted hair growth", "enum", {"type": "string", "enum": severity}, allowed_values=severity),
        _tracker("hair_thinning", "Hair thinning", "enum", {"type": "string", "enum": severity}, allowed_values=severity),
        _tracker("cycle_irregularity_note", "Cycle irregularity note", "string", {"type": "string", "maxLength": 500}),
        _tracker("insulin_metabolic_note", "Insulin or metabolic note", "string", {"type": "string", "maxLength": 500}),
    ]


def tracker_registry() -> dict[str, TrackerDefinition]:
    return {definition.code: definition for definition in tracker_definitions()}


def tracker_packs() -> list[TrackerPack]:
    return [
        TrackerPack(
            code="base_symptoms",
            display_name="Base symptoms",
            description="Universal symptom and cycle logging used across Period.",
            tracker_codes=[
                "period_bleeding", "spotting", "cramps", "pelvic_pain", "mood", "energy", "fatigue",
                "sleep_hours", "cervical_mucus", "sex", "medication", "basal_body_temperature", "weight", "note",
            ],
            enabled_by_default=True,
            clinical_note="General tracking only; not diagnosis or treatment guidance.",
            evidence=[_BASE_EVIDENCE],
        ),
        TrackerPack(
            code="reproductive_context",
            display_name="Reproductive context",
            description="Optional context that can explain cycle changes without becoming diagnostic logic.",
            tracker_codes=["contraception_use", "pregnancy_test", "ovulation_test", "postpartum_status", "lactation_status"],
            enabled_by_default=False,
            clinical_note="Context trackers help users record relevant changes for themselves or clinicians.",
            evidence=[_BASE_EVIDENCE],
        ),
        TrackerPack(
            code="pcos_support",
            display_name="PCOS support",
            description="Optional PCOS-oriented symptom set layered on universal observation events.",
            tracker_codes=[
                "cycle_irregularity_note", "acne_severity", "hair_growth", "hair_thinning", "weight",
                "insulin_metabolic_note", "mood", "sleep_hours", "period_bleeding", "cramps", "medication", "note",
            ],
            enabled_by_default=False,
            clinical_note="This pack supports symptom logging for clinician conversations and does not infer or diagnose PCOS.",
            evidence=[_BASE_EVIDENCE],
        ),
        TrackerPack(
            code="endometriosis_support",
            display_name="Endometriosis support",
            description="Pain, bleeding, bowel, bladder, fatigue, and sex-pain logging for endometriosis-oriented conversations.",
            tracker_codes=[
                "period_bleeding", "spotting", "cramps", "pelvic_pain", "pain_with_sex", "bowel_symptoms",
                "bladder_symptoms", "fatigue", "medication", "note",
            ],
            enabled_by_default=False,
            clinical_note="This pack supports symptom logging and does not infer or diagnose endometriosis.",
            evidence=[_BASE_EVIDENCE],
        ),
        TrackerPack(
            code="pms_pmdd_support",
            display_name="PMS and PMDD support",
            description="Mood, physical symptom, sleep, and energy tracking for cycle-linked pattern review.",
            tracker_codes=[
                "mood", "anxiety_severity", "depression_severity", "irritability", "migraine",
                "breast_tenderness", "bloating", "sleep_hours", "energy", "fatigue", "note",
            ],
            enabled_by_default=False,
            clinical_note="This pack supports pattern logging and does not diagnose PMS, PMDD, depression, or anxiety.",
            evidence=[_BASE_EVIDENCE],
        ),
        TrackerPack(
            code="perimenopause_support",
            display_name="Perimenopause support",
            description="Cycle variability, vasomotor, sleep, mood, and dryness tracking for midlife transition context.",
            tracker_codes=[
                "cycle_pattern_change", "period_bleeding", "hot_flashes", "night_sweats", "vaginal_dryness",
                "sleep_hours", "mood", "energy", "fatigue", "note",
            ],
            enabled_by_default=False,
            clinical_note="This pack supports symptom logging and does not infer or diagnose perimenopause.",
            evidence=[_BASE_EVIDENCE],
        ),
        TrackerPack(
            code="contraception_support",
            display_name="Contraception support",
            description="Contraception method, start/stop, missed use, bleeding, and context logging.",
            tracker_codes=[
                "contraception_use", "contraception_start", "contraception_stop", "missed_contraception",
                "period_bleeding", "spotting", "pregnancy_test", "medication", "note",
            ],
            enabled_by_default=False,
            clinical_note="This pack records contraception context only; it does not provide contraceptive efficacy or safety advice.",
            evidence=[_BASE_EVIDENCE],
        ),
    ]
