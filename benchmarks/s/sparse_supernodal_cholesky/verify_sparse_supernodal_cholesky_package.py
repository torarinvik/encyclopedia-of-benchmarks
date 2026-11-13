"""Static inventory checks for the bounded sparse Cholesky package."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
              "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
              "v": "v", "zig": "zig"}


def static_issues() -> list[str]:
    issues = []
    package = ROOT / "benchmarks/s/sparse_supernodal_cholesky"
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (package / name).is_file():
            issues.append(f"missing {name}")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "s" / f"sparse_supernodal_cholesky.{extension}"
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
        elif "sparse_supernodal_cholesky" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing symbol in {path.relative_to(ROOT)}")
    try:
        workload = json.loads((package / "workload.json").read_text(encoding="utf-8"))
        if (workload.get("algorithm") != "sparse_supernodal_cholesky"
                or workload.get("function_symbol") != "sparse_supernodal_cholesky"
                or workload.get("abi") != "i64_array_bytes_output"
                or workload.get("input", {}).get("maximum_valid_input_length") != 55
                or workload.get("input", {}).get("maximum_parseable_input_length") != 56
                or workload.get("output", {}).get("kind") != "float64_vector"
                or workload.get("output", {}).get("maximum_bytes") != 288
                or workload.get("workspace", {}).get("bytes") != 4096
                or workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call"):
            issues.append("workload metadata differs from the sparse Cholesky contract")
    except (OSError, json.JSONDecodeError) as error:
        issues.append(f"invalid workload: {error}")
    return issues
