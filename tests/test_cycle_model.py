import json
from pathlib import Path

from core.model import CycleLengthObservation, backtest_subjects, fit_cycle_model, predict_next_cycle
from core.contracts import Prediction
from core.model.cycle_model import load_cycle_length_fixture

PROJECT_ROOT = Path(__file__).resolve().parent.parent


def test_sparse_history_shrinks_toward_population_prior():
    state = fit_cycle_model([
        CycleLengthObservation(subject_id="new", cycle_index=0, length_days=35),
    ])
    assert 29 < state.posterior_mean_days < 35
    prediction = predict_next_cycle(state)
    assert prediction.p10_length_days < prediction.p50_length_days < prediction.p90_length_days


def test_skip_artifact_long_cycle_is_adjusted_toward_two_cycles():
    state = fit_cycle_model([
        CycleLengthObservation(subject_id="skip", cycle_index=0, length_days=27),
        CycleLengthObservation(subject_id="skip", cycle_index=1, length_days=28),
        CycleLengthObservation(subject_id="skip", cycle_index=2, length_days=56),
    ])
    assert state.skip_probabilities[-1] > 0.80
    assert state.adjusted_lengths[-1] < 35
    assert state.posterior_mean_days < 31


def test_prediction_updates_online_for_elapsed_cycle_day():
    state = fit_cycle_model([
        CycleLengthObservation(subject_id="online", cycle_index=0, length_days=28),
        CycleLengthObservation(subject_id="online", cycle_index=1, length_days=29),
        CycleLengthObservation(subject_id="online", cycle_index=2, length_days=30),
    ])
    baseline = predict_next_cycle(state)
    day_35 = predict_next_cycle(state, elapsed_cycle_day=35)
    assert day_35.p50_length_days > baseline.p50_length_days
    assert day_35.p10_length_days >= 35


def test_small_fixture_backtest_runs_with_reasonable_error():
    rows = json.loads((PROJECT_ROOT / "tests" / "data" / "cycle_lengths_small.json").read_text())
    subjects = load_cycle_length_fixture(rows)
    summary = backtest_subjects(subjects, min_train_cycles=3)
    assert summary.fold_count == 9
    assert summary.mean_absolute_error_days < 12
    assert summary.p80_coverage >= 0.50


def test_prediction_payload_matches_existing_prediction_contract_shape():
    state = fit_cycle_model([
        CycleLengthObservation(subject_id="payload", cycle_index=0, length_days=28),
        CycleLengthObservation(subject_id="payload", cycle_index=1, length_days=29),
        CycleLengthObservation(subject_id="payload", cycle_index=2, length_days=28),
    ])
    payload = predict_next_cycle(state).as_contract_payload()
    assert payload["algorithm_version"] == state.algorithm_version
    assert "next_period" in payload
    assert "self_tracking" in payload


def test_prediction_converts_to_public_prediction_contract():
    state = fit_cycle_model([
        CycleLengthObservation(subject_id="contract", cycle_index=0, length_days=28),
        CycleLengthObservation(subject_id="contract", cycle_index=1, length_days=29),
        CycleLengthObservation(subject_id="contract", cycle_index=2, length_days=28),
    ])
    contract = predict_next_cycle(state).to_contract(prediction_id="prediction-contract")
    assert isinstance(contract, Prediction)
    assert contract.id == "prediction-contract"
    assert contract.subject_id == "contract"
    assert contract.ovulation is None
    assert contract.next_period is not None
    assert "cycle_length_days" in contract.next_period
