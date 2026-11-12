"""Static package-integrity check; intentionally does not compile or run ports."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PORTS = {
    "c": "c/f/splash2_fmm.c",
    "c3": "c3/f/splash2_fmm.c3",
    "cpp": "cpp/f/splash2_fmm.cpp",
    "elisa": "elisa/f/splash2_fmm.elisa",
    "mojo": "mojo/f/splash2_fmm.mojo",
    "nim": "nim/f/splash2_fmm.nim",
    "odin": "odin/f/splash2_fmm.odin",
    "rust": "rust/f/splash2_fmm.rs",
    "v": "v/f/splash2_fmm.v",
    "zig": "zig/f/splash2_fmm.zig",
}


def check_package() -> list[str]:
    errors = []
    workload_path = ROOT / "benchmarks/f/splash2_fmm/workload.json"
    try:
        workload = json.loads(workload_path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        return [f"workload is unreadable: {exc}"]
    if (workload.get("algorithm") != "splash2_fmm"
            or workload.get("function_symbol") != "splash2_fmm"
            or workload.get("abi") != "float64_slice_io"):
        errors.append("workload algorithm name does not match the package")
    if workload.get("function_symbol") != "splash2_fmm":
        errors.append("workload function symbol is missing")
    contract = workload.get("contract", {})
    if contract.get("expansion_order") != 32 or "Chebyshev" not in contract.get("far_field_rule", ""):
        errors.append("workload does not pin the expansion order and far-field rule")
    if contract.get("valid_particle_count_range") != [2, 48]:
        errors.append("workload particle-count bounds changed")
    if workload.get("output", {}).get("absolute_tolerance") != 1e-10:
        errors.append("workload absolute tolerance changed")
    if workload.get("workspace", {}).get("elements") != 48:
        errors.append("workload workspace does not cover every particle output")
    cases = workload.get("cases", [])
    case_ids = {case.get("id") for case in cases}
    for required in ("near_pair_same_box", "far_pair_multipole_translation",
                     "far_box_multi_source_moments",
                     "near_neighbor_boxes_direct_interaction", "invalid_duplicate_positions"):
        if required not in case_ids:
            errors.append(f"workload is missing case {required}")

    for language, relative in PORTS.items():
        path = ROOT / relative
        try:
            source = path.read_text()
        except OSError:
            errors.append(f"missing {language} port: {relative}")
            continue
        if "splash2_fmm" not in source:
            errors.append(f"{relative} does not export splash2_fmm")
        if "32" not in source or not any(token in source.lower() for token in ("log", "ln(")):
            errors.append(f"{relative} is missing the pinned expansion or logarithmic kernel")
        if not any(marker in source for marker in ("multipole", "mr[", "mr ", "mr=", "mr :=", "mr =")):
            errors.append(f"{relative} is missing visible multipole state")

    oracle = ROOT / "benchmarks/splash2_fmm_oracle.py"
    verifier = ROOT / "benchmarks/splash2_fmm_verifier_oracle.py"
    for path in (oracle, verifier):
        if not path.is_file():
            errors.append(f"missing direct oracle: {path.relative_to(ROOT)}")
    if oracle.is_file() and verifier.is_file():
        oracle_text = oracle.read_text()
        verifier_text = verifier.read_text()
        if "log(hypot" not in oracle_text or "for tx, ty" not in oracle_text:
            errors.append("primary oracle is not the target-wise direct logarithmic reference")
        if "for source," not in verifier_text or "for target," not in verifier_text:
            errors.append("verifier oracle does not use its independent source-major loop")
        if "ORDER" in oracle_text or "ORDER" in verifier_text:
            errors.append("direct oracles must not use the FMM expansion")

    for relative in ("benchmarks/f/splash2_fmm/README.md", "benchmarks/f/splash2_fmm/RIGHTS.md"):
        if not (ROOT / relative).is_file():
            errors.append(f"missing package document: {relative}")
    return errors


if __name__ == "__main__":
    for error in check_package():
        print(error)
