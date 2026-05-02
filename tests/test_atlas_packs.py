from core.tracking import tracker_packs, tracker_registry


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


def test_universal_symptom_base_contains_calendar_relevant_trackers():
    packs = {pack.code: pack for pack in tracker_packs()}
    base_codes = set(packs["base_symptoms"].tracker_codes)
    assert {"period_bleeding", "cramps", "pelvic_pain", "basal_body_temperature", "note"}.issubset(base_codes)
