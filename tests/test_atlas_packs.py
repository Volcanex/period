from datetime import UTC, datetime

from core.contracts import TrackerSettings
from core.tracking import (
    addon_tracker_definitions,
    addon_tracker_packs,
    base_tracker_pack,
    resolve_tracker_settings,
    tracker_definitions,
    tracker_packs,
    tracker_registry,
    universal_tracker_definitions,
)


def test_tracker_pack_catalog_is_base_plus_addons():
    base_pack = base_tracker_pack()
    add_on_packs = addon_tracker_packs()
    packs = tracker_packs()

    assert packs[0].code == base_pack.code == "base_symptoms"
    assert [pack.code for pack in packs[1:]] == [pack.code for pack in add_on_packs]
    assert all(pack.enabled_by_default is False for pack in add_on_packs)


def test_tracker_definition_catalog_is_universal_plus_addons():
    universal = universal_tracker_definitions()
    addons = addon_tracker_definitions()
    combined = tracker_definitions()

    assert [definition.code for definition in combined] == [
        *[definition.code for definition in universal],
        *[definition.code for definition in addons],
    ]
    assert "cramps" in {definition.code for definition in universal}
    assert "acne_severity" not in {definition.code for definition in universal}
    assert "acne_severity" in {definition.code for definition in addons}
    assert "cycle_regularity" in {definition.code for definition in addons}


def test_optional_condition_packs_are_metadata_only_and_reference_known_trackers():
    registry = tracker_registry()
    packs = {pack.code: pack for pack in tracker_packs()}

    for code in [
        "pcos_support",
        "endometriosis_support",
        "pms_pmdd_support",
        "perimenopause_support",
        "contraception_support",
    ]:
        assert code in packs
        assert packs[code].enabled_by_default is False
        assert packs[code].clinical_note is not None
        assert "diagnos" in packs[code].clinical_note.lower() or "advice" in packs[code].clinical_note.lower()
        assert set(packs[code].tracker_codes).issubset(registry)


def test_pms_pmdd_pack_exposes_rich_pattern_and_context_trackers():
    packs = {pack.code: pack for pack in tracker_packs()}
    pms_pack = packs["pms_pmdd_support"]

    assert {
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
        "psychotropic_medication_change",
        "pregnancy_test",
        "postpartum_status",
        "lactation_status",
    }.issubset(pms_pack.tracker_codes)


def test_universal_symptom_base_contains_calendar_relevant_trackers():
    base_codes = set(base_tracker_pack().tracker_codes)
    assert {"period_bleeding", "cramps", "pelvic_pain", "basal_body_temperature", "note"}.issubset(base_codes)


def test_addon_pack_resolution_is_additive_not_special_cased():
    base_settings = TrackerSettings(
        subject_id="subject-1",
        enabled_pack_codes=["base_symptoms"],
        disabled_tracker_codes=[],
        tracker_preferences=[],
        updated_at=datetime(2026, 5, 2, 10, 0, tzinfo=UTC),
        schema_version="2026.05.02",
    )
    pcos_settings = TrackerSettings(
        subject_id="subject-1",
        enabled_pack_codes=["base_symptoms", "pcos_support"],
        disabled_tracker_codes=[],
        tracker_preferences=[],
        updated_at=datetime(2026, 5, 2, 10, 0, tzinfo=UTC),
        schema_version="2026.05.02",
    )

    base_catalog = resolve_tracker_settings(base_settings).active_catalog
    pcos_catalog = resolve_tracker_settings(pcos_settings).active_catalog

    assert base_catalog is not None
    assert pcos_catalog is not None

    base_codes = {definition.code for definition in base_catalog.tracker_definitions}
    pcos_codes = {definition.code for definition in pcos_catalog.tracker_definitions}
    pcos_pack_codes = set(next(pack for pack in addon_tracker_packs() if pack.code == "pcos_support").tracker_codes)

    assert base_codes.issubset(pcos_codes)
    assert pcos_pack_codes.issubset(pcos_codes)
    assert pcos_codes - base_codes == pcos_pack_codes - base_codes


def test_addon_definition_codes_are_reachable_through_pack_membership():
    addon_codes = {definition.code for definition in addon_tracker_definitions()}
    pack_codes = {code for pack in addon_tracker_packs() for code in pack.tracker_codes}

    assert addon_codes.issubset(pack_codes)
    assert {
        "acne_severity",
        "hair_growth",
        "hair_thinning",
        "cycle_regularity",
        "acanthosis_nigricans",
        "glucose_lab_note",
        "lipid_note",
        "hot_flashes",
    }.issubset(addon_codes)
