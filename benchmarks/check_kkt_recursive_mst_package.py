"""Static inventory checks for the complete KKT recursive MSF package."""

from pathlib import Path

from workload_json import load_workload

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/k/kkt_recursive_mst"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa", "mojo": "mojo",
    "nim": "nim", "odin": "odin", "rust": "rs", "v": "v", "zig": "zig",
}


def static_issues(workload=None):
    if workload is None:
        try:
            workload = load_workload(PACKAGE / "workload.json")
        except (OSError, ValueError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    issues = []
    input_contract = workload.get("input")
    if (workload.get("algorithm") != "kkt_recursive_mst"
            or workload.get("function_symbol") != "kkt_recursive_mst"
            or workload.get("abi") != "i64_array_scalar"
            or not isinstance(input_contract, dict)
            or input_contract.get("maximum_vertices") != 16
            or input_contract.get("maximum_valid_values") != 51
            or input_contract.get("maximum_parseable_values") != 52):
        issues.append("identity or input bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "k" / f"kkt_recursive_mst.{extension}"
        if not path.is_file() or "kkt_recursive_mst" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing port or symbol: {language}")
    for name in ("README.md", "RIGHTS.md", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        issues.append("missing workload cases")
    return issues
