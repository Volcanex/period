import json
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent


def test_model_benchmark_script_outputs_stable_json():
    result = subprocess.run(
        [
            sys.executable,
            "scripts/model_benchmark.py",
            "--max-subjects",
            "1200",
            "--calibration-subjects",
            "400",
        ],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
    report = json.loads(result.stdout)
    assert report["dataset"]["calibration_subjects"] == 400
    assert report["dataset"]["validation_subjects"] == 800
    assert report["fold_count"] > 6000
    assert report["prior"]["interval_scale"] == 0.9
    metric_names = {metric["name"] for metric in report["metrics"]}
    assert {"period_v1", "population_mean", "personal_mean", "recent3_mean"} <= metric_names
