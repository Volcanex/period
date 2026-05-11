"""Atlas tracker registry and condition pack definitions."""

from core.contracts import EvidenceReference, TrackerDefinition, TrackerPack

VERSION = "2026.05.08"

_BASE_EVIDENCE = EvidenceReference(
    source="Period Atlas v1 tracker taxonomy",
    assumption="Trackers support symptom recording and clinician conversations, not diagnosis.",
    confidence=0.45,
    version=VERSION,
    review_status="draft",
)

_PCOS_GUIDELINE_EVIDENCE = EvidenceReference(
    source="2023 International Evidence-based Guideline for the Assessment and Management of PCOS",
    assumption="PCOS tracking should emphasize menstrual irregularity, hyperandrogenic features, metabolic context, and uncertainty without implying diagnosis.",
    confidence=0.71,
    version=VERSION,
    review_status="draft",
)

_PMDD_DRSP_EVIDENCE = EvidenceReference(
    source="Endicott et al. 2006 DRSP reliability and validity",
    assumption="PMDD-oriented daily tracking should use validated daily severity items and impairment ratings rather than retrospective summaries.",
    confidence=0.83,
    version=VERSION,
    review_status="draft",
)

_PMDD_CPASS_EVIDENCE = EvidenceReference(
    source="Eisenlohr-Moul et al. 2017 C-PASS",
    assumption="Prospective PMDD classification should require DRSP-style daily ratings, symptom content thresholds, cyclicity, postmenstrual clearance, impairment, and at least two symptomatic cycles.",
    confidence=0.86,
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
    evidence: list[EvidenceReference] | None = None,
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
        evidence=evidence or [_BASE_EVIDENCE],
    )


SEVERITY_VALUES = ["none", "mild", "moderate", "severe"]
YES_NO_UNKNOWN_VALUES = ["yes", "no", "unknown"]


def universal_tracker_definitions() -> list[TrackerDefinition]:
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
        _tracker("cramps", "Cramps", "enum", {"type": "string", "enum": SEVERITY_VALUES}, allowed_values=SEVERITY_VALUES),
        _tracker("pelvic_pain", "Pelvic pain", "enum", {"type": "string", "enum": SEVERITY_VALUES}, allowed_values=SEVERITY_VALUES),
        _tracker("pain_with_sex", "Pain with sex", "enum", {"type": "string", "enum": SEVERITY_VALUES}, allowed_values=SEVERITY_VALUES),
        _tracker("bowel_symptoms", "Bowel symptoms", "enum", {"type": "string", "enum": ["none", "constipation", "diarrhea", "painful", "other"]}, allowed_values=["none", "constipation", "diarrhea", "painful", "other"]),
        _tracker("bladder_symptoms", "Bladder symptoms", "enum", {"type": "string", "enum": ["none", "frequency", "urgency", "pain", "other"]}, allowed_values=["none", "frequency", "urgency", "pain", "other"]),
        _tracker("fatigue", "Fatigue", "enum", {"type": "string", "enum": SEVERITY_VALUES}, allowed_values=SEVERITY_VALUES),
        _tracker("migraine", "Migraine or headache", "enum", {"type": "string", "enum": SEVERITY_VALUES}, allowed_values=SEVERITY_VALUES),
        _tracker("breast_tenderness", "Breast tenderness", "enum", {"type": "string", "enum": SEVERITY_VALUES}, allowed_values=SEVERITY_VALUES),
        _tracker("bloating", "Bloating", "enum", {"type": "string", "enum": SEVERITY_VALUES}, allowed_values=SEVERITY_VALUES),
        _tracker("mood", "Mood", "enum", {"type": "string", "enum": ["low", "neutral", "good", "anxious", "irritable"]}, allowed_values=["low", "neutral", "good", "anxious", "irritable"]),
        _tracker("anxiety_severity", "Anxiety severity", "enum", {"type": "string", "enum": SEVERITY_VALUES}, allowed_values=SEVERITY_VALUES),
        _tracker("depression_severity", "Depression severity", "enum", {"type": "string", "enum": SEVERITY_VALUES}, allowed_values=SEVERITY_VALUES),
        _tracker("irritability", "Irritability", "enum", {"type": "string", "enum": SEVERITY_VALUES}, allowed_values=SEVERITY_VALUES),
        _tracker("mood_lability", "Mood swings or rejection sensitivity", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6"),
        _tracker("hopelessness", "Hopelessness, guilt, or worthlessness", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6"),
        _tracker("productivity_impairment", "Productivity or home impairment", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", calendar_priority=45),
        _tracker("social_impairment", "Social activity impairment", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", calendar_priority=45),
        _tracker("relationship_impairment", "Relationship friction or conflict", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", calendar_priority=45),
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
        _tracker("psychotropic_medication_change", "Psychotropic medication change", "boolean", {"type": "boolean"}, calendar_layer="context", calendar_priority=60),
    ]


def addon_tracker_definitions() -> list[TrackerDefinition]:
    return [
        _tracker("drsp_depressed_mood", "DRSP depressed, sad, down, or blue", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_hopelessness", "DRSP hopeless", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_worthlessness_guilt", "DRSP worthless or guilty", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_anxiety_tension", "DRSP anxious, keyed up, or on edge", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_mood_swings", "DRSP mood swings", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_rejection_sensitivity", "DRSP sensitive to rejection or easily hurt", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_anger_irritability", "DRSP angry or irritable", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_interpersonal_conflict", "DRSP conflicts or problems with people", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_less_interest", "DRSP less interest in usual activities", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_difficulty_concentrating", "DRSP difficulty concentrating", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_lethargy", "DRSP lethargic, tired, or low energy", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_appetite_overeating", "DRSP increased appetite or overeating", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_food_cravings", "DRSP specific food cravings", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_hypersomnia", "DRSP slept more or hard to get up", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_insomnia", "DRSP trouble getting to sleep or staying asleep", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_overwhelmed", "DRSP overwhelmed, couldn't cope", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_out_of_control", "DRSP out of control", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_breast_tenderness", "DRSP breast tenderness", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_bloating_weight_gain", "DRSP bloating or weight gain", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_headache", "DRSP headache", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_joint_muscle_pain", "DRSP joint or muscle pain", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_productivity_impairment", "DRSP less productivity at work, school, home, or routine", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", calendar_priority=45, evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_social_impairment", "DRSP interference with hobbies or social activities", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", calendar_priority=45, evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("drsp_relationship_impairment", "DRSP interference with relationships", "integer", {"type": "integer", "minimum": 1, "maximum": 6}, unit="drsp_1_6", calendar_priority=45, evidence=[_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE]),
        _tracker("hot_flashes", "Hot flashes", "enum", {"type": "string", "enum": SEVERITY_VALUES}, allowed_values=SEVERITY_VALUES),
        _tracker("night_sweats", "Night sweats", "enum", {"type": "string", "enum": SEVERITY_VALUES}, allowed_values=SEVERITY_VALUES),
        _tracker("vaginal_dryness", "Vaginal dryness", "enum", {"type": "string", "enum": SEVERITY_VALUES}, allowed_values=SEVERITY_VALUES),
        _tracker("cycle_pattern_change", "Cycle pattern change", "enum", {"type": "string", "enum": YES_NO_UNKNOWN_VALUES}, allowed_values=YES_NO_UNKNOWN_VALUES),
        _tracker(
            "cycle_regularity",
            "Cycle regularity",
            "enum",
            {"type": "string", "enum": ["regular", "variable", "infrequent", "absent", "unknown"]},
            allowed_values=["regular", "variable", "infrequent", "absent", "unknown"],
            calendar_layer="context",
            calendar_priority=55,
            evidence=[_BASE_EVIDENCE, _PCOS_GUIDELINE_EVIDENCE],
        ),
        _tracker(
            "acne_severity",
            "Acne severity",
            "enum",
            {"type": "string", "enum": SEVERITY_VALUES},
            allowed_values=SEVERITY_VALUES,
            evidence=[_BASE_EVIDENCE, _PCOS_GUIDELINE_EVIDENCE],
        ),
        _tracker(
            "hair_growth",
            "Unwanted hair growth",
            "enum",
            {"type": "string", "enum": SEVERITY_VALUES},
            allowed_values=SEVERITY_VALUES,
            evidence=[_BASE_EVIDENCE, _PCOS_GUIDELINE_EVIDENCE],
        ),
        _tracker(
            "hair_thinning",
            "Scalp hair thinning or loss",
            "enum",
            {"type": "string", "enum": SEVERITY_VALUES},
            allowed_values=SEVERITY_VALUES,
            evidence=[_BASE_EVIDENCE, _PCOS_GUIDELINE_EVIDENCE],
        ),
        _tracker(
            "acanthosis_nigricans",
            "Acanthosis nigricans observed",
            "boolean",
            {"type": "boolean"},
            calendar_layer="context",
            calendar_priority=40,
            evidence=[_BASE_EVIDENCE, _PCOS_GUIDELINE_EVIDENCE],
        ),
        _tracker(
            "cycle_irregularity_note",
            "Cycle irregularity note",
            "string",
            {"type": "string", "maxLength": 500},
            calendar_layer="context",
            calendar_priority=35,
            evidence=[_BASE_EVIDENCE, _PCOS_GUIDELINE_EVIDENCE],
        ),
        _tracker(
            "insulin_metabolic_note",
            "Insulin or metabolic note",
            "string",
            {"type": "string", "maxLength": 500},
            calendar_layer="context",
            calendar_priority=35,
            evidence=[_BASE_EVIDENCE, _PCOS_GUIDELINE_EVIDENCE],
        ),
        _tracker(
            "glucose_lab_note",
            "Glucose or HbA1c note",
            "string",
            {"type": "string", "maxLength": 500},
            calendar_layer="context",
            calendar_priority=35,
            evidence=[_BASE_EVIDENCE, _PCOS_GUIDELINE_EVIDENCE],
        ),
        _tracker(
            "lipid_note",
            "Lipid panel note",
            "string",
            {"type": "string", "maxLength": 500},
            calendar_layer="context",
            calendar_priority=35,
            evidence=[_BASE_EVIDENCE, _PCOS_GUIDELINE_EVIDENCE],
        ),
    ]


def tracker_definitions() -> list[TrackerDefinition]:
    return [*universal_tracker_definitions(), *addon_tracker_definitions()]


def tracker_registry() -> dict[str, TrackerDefinition]:
    return {definition.code: definition for definition in tracker_definitions()}


BASE_TRACKER_CODES = [
    "period_bleeding",
    "spotting",
    "cramps",
    "pelvic_pain",
    "mood",
    "energy",
    "fatigue",
    "sleep_hours",
    "cervical_mucus",
    "sex",
    "medication",
    "basal_body_temperature",
    "weight",
    "note",
]

OPTIONAL_PACK_SPECS = [
    {
        "code": "reproductive_context",
        "display_name": "Reproductive context",
        "description": "Optional context that can explain cycle changes without becoming diagnostic logic.",
        "tracker_codes": [
            "contraception_use",
            "pregnancy_test",
            "ovulation_test",
            "postpartum_status",
            "lactation_status",
        ],
        "clinical_note": "Context trackers help users record relevant changes for themselves or clinicians.",
    },
    {
        "code": "pcos_support",
        "display_name": "PCOS support",
        "description": "Optional PCOS-oriented symptom and metabolic-context set layered on universal observation events.",
        "tracker_codes": [
            "cycle_regularity",
            "cycle_irregularity_note",
            "acne_severity",
            "hair_growth",
            "hair_thinning",
            "acanthosis_nigricans",
            "weight",
            "insulin_metabolic_note",
            "glucose_lab_note",
            "lipid_note",
            "mood",
            "sleep_hours",
            "period_bleeding",
            "cramps",
            "medication",
            "note",
        ],
        "clinical_note": "This pack supports symptom, cycle, and metabolic-context logging for clinician conversations and does not infer or diagnose PCOS.",
        "evidence": [_BASE_EVIDENCE, _PCOS_GUIDELINE_EVIDENCE],
    },
    {
        "code": "endometriosis_support",
        "display_name": "Endometriosis support",
        "description": "Pain, bleeding, bowel, bladder, fatigue, and sex-pain logging for endometriosis-oriented conversations.",
        "tracker_codes": [
            "period_bleeding",
            "spotting",
            "cramps",
            "pelvic_pain",
            "pain_with_sex",
            "bowel_symptoms",
            "bladder_symptoms",
            "fatigue",
            "medication",
            "note",
        ],
        "clinical_note": "This pack supports symptom logging and does not infer or diagnose endometriosis.",
    },
    {
        "code": "pms_pmdd_support",
        "display_name": "PMS and PMDD support",
        "description": "DRSP-aligned daily symptom and impairment tracking for prospective PMDD and PMS pattern evaluation.",
        "tracker_codes": [
            "drsp_depressed_mood",
            "drsp_hopelessness",
            "drsp_worthlessness_guilt",
            "drsp_anxiety_tension",
            "drsp_mood_swings",
            "drsp_rejection_sensitivity",
            "drsp_anger_irritability",
            "drsp_interpersonal_conflict",
            "drsp_less_interest",
            "drsp_difficulty_concentrating",
            "drsp_lethargy",
            "drsp_appetite_overeating",
            "drsp_food_cravings",
            "drsp_hypersomnia",
            "drsp_insomnia",
            "drsp_overwhelmed",
            "drsp_out_of_control",
            "drsp_breast_tenderness",
            "drsp_bloating_weight_gain",
            "drsp_headache",
            "drsp_joint_muscle_pain",
            "drsp_productivity_impairment",
            "drsp_social_impairment",
            "drsp_relationship_impairment",
            "period_bleeding",
            "psychotropic_medication_change",
            "pregnancy_test",
            "postpartum_status",
            "lactation_status",
            "note",
        ],
        "clinical_note": "This pack supports prospective DRSP-style pattern logging and backend PMDD evaluation; it does not by itself establish diagnosis.",
        "evidence": [_BASE_EVIDENCE, _PMDD_DRSP_EVIDENCE, _PMDD_CPASS_EVIDENCE],
    },
    {
        "code": "perimenopause_support",
        "display_name": "Perimenopause support",
        "description": "Cycle variability, vasomotor, sleep, mood, and dryness tracking for midlife transition context.",
        "tracker_codes": [
            "cycle_pattern_change",
            "period_bleeding",
            "hot_flashes",
            "night_sweats",
            "vaginal_dryness",
            "sleep_hours",
            "mood",
            "energy",
            "fatigue",
            "note",
        ],
        "clinical_note": "This pack supports symptom logging and does not infer or diagnose perimenopause.",
    },
    {
        "code": "contraception_support",
        "display_name": "Contraception support",
        "description": "Contraception method, start/stop, missed use, bleeding, and context logging.",
        "tracker_codes": [
            "contraception_use",
            "contraception_start",
            "contraception_stop",
            "missed_contraception",
            "period_bleeding",
            "spotting",
            "pregnancy_test",
            "medication",
            "note",
        ],
        "clinical_note": "This pack records contraception context only; it does not provide contraceptive efficacy or safety advice.",
    },
]


def _pack(
    code: str,
    display_name: str,
    description: str,
    tracker_codes: list[str],
    clinical_note: str,
    *,
    enabled_by_default: bool,
    evidence: list[EvidenceReference] | None = None,
) -> TrackerPack:
    return TrackerPack(
        code=code,
        display_name=display_name,
        description=description,
        tracker_codes=tracker_codes,
        enabled_by_default=enabled_by_default,
        clinical_note=clinical_note,
        evidence=evidence or [_BASE_EVIDENCE],
    )


def base_tracker_pack() -> TrackerPack:
    return _pack(
        code="base_symptoms",
        display_name="Base symptoms",
        description="Universal symptom and cycle logging used across Period.",
        tracker_codes=BASE_TRACKER_CODES,
        clinical_note="General tracking only; not diagnosis or treatment guidance.",
        enabled_by_default=True,
    )


def addon_tracker_packs() -> list[TrackerPack]:
    return [
        _pack(
            code=spec["code"],
            display_name=spec["display_name"],
            description=spec["description"],
            tracker_codes=spec["tracker_codes"],
            clinical_note=spec["clinical_note"],
            enabled_by_default=False,
            evidence=spec.get("evidence"),
        )
        for spec in OPTIONAL_PACK_SPECS
    ]


def tracker_packs() -> list[TrackerPack]:
    return [base_tracker_pack(), *addon_tracker_packs()]
