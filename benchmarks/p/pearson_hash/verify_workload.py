"""Package-local materialization and static fixture comparison entry point."""

import json
from pathlib import Path

from independent_oracle import expected_result as independent_result
from primary_oracle import expected_result as primary_result


def materialize(case: dict) -> list[int]:
    table = [((value & 15) << 4) | (value >> 4) for value in range(256)]
    mutation = case.get("table_mutation")
    if mutation is not None:
        table[mutation["index"]] = mutation["value"]

    if "text_length" in case:
        text = [case["text_fill"]] * case["text_length"]
    else:
        text = list(case["text_values"])
    frame = [len(text), *table, *text]

    frame_mutation = case.get("frame_mutation")
    if frame_mutation == "remove_last_word":
        frame.pop()
    elif frame_mutation == "append_zero":
        frame.append(0)
    elif frame_mutation is not None:
        raise ValueError(f"unknown frame mutation: {frame_mutation}")
    return frame


def check_workload() -> None:
    path = Path(__file__).with_name("workload.json")
    workload = json.loads(path.read_text(encoding="utf-8"))
    if workload.get("algorithm") != "pearson_hash":
        raise ValueError("workload algorithm ID does not match the package")
    for case in workload["cases"]:
        frame = materialize(case)
        expected = case["expected_result"]
        primary = primary_result(frame)
        independent = independent_result(frame)
        if primary != expected or independent != expected:
            raise ValueError(
                f"{case['id']}: fixture expected {expected}, got "
                f"primary {primary}, independent {independent}"
            )


if __name__ == "__main__":
    check_workload()
