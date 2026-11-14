"""Draft driver for paired comparisons against closed-form structured cases.

This script is not executed during compiler profiling. It expects an already
built paired harness and already built shared libraries; it never builds them.
"""
import argparse
import json
import math
from pathlib import Path
import subprocess
import sys
import tempfile

from structured_cases import cases


def write_input(stream, values, result, output):
    stream.write(f"{len(values)} {result} {len(output)}\n")
    for start in range(0, len(values), 4096):
        stream.write(" ".join(map(str, values[start:start + 4096])))
        stream.write("\n")
    if output:
        for start in range(0, len(output), 65536):
            stream.write(output[start:start + 65536].hex())
        stream.write("\n")
    else:
        stream.write("-\n")
    stream.flush()
    stream.seek(0)


def run_case(args, case):
    name, values, result, output = case
    command = [str(args.harness), str(args.library_a), str(args.library_b),
               "symmetric_group_convolution_fft", str(args.rounds),
               str(args.batches), str(args.repetitions), "--stdin"]
    # Files avoid pipe backpressure while the harness consumes a large frame and
    # emits multiple timing rows. A failing harness cannot leave a partial case
    # presented as a successful comparison.
    with tempfile.TemporaryFile(mode="w+t", encoding="ascii") as source, \
         tempfile.TemporaryFile(mode="w+t", encoding="utf-8") as rows, \
         tempfile.TemporaryFile(mode="w+t", encoding="utf-8") as errors:
        write_input(source, values, result, output)
        completed = subprocess.run(command, stdin=source, stdout=rows, stderr=errors,
                                   timeout=args.timeout, check=False)
        errors.seek(0)
        diagnostic = errors.read()
        if completed.returncode:
            raise RuntimeError(f"{name}: paired harness exited {completed.returncode}: {diagnostic}")
        rows.seek(0)
        records = [json.loads(line) for line in rows]
    if len(records) != args.rounds:
        raise ValueError(f"{name}: unexpected number of timing rows")
    for index, row in enumerate(records):
        if (not isinstance(row, dict) or row.get("round") != index
                or any(type(row.get(key)) not in (int, float)
                       or not math.isfinite(row[key]) or row[key] < 0
                       for key in ("a_ns", "b_ns"))):
            raise ValueError(f"{name}: malformed timing row")
    for row in records:
        print(json.dumps({"case": name, **row}, allow_nan=False), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--harness", type=Path, required=True)
    parser.add_argument("--library-a", type=Path, required=True)
    parser.add_argument("--library-b", type=Path, required=True)
    parser.add_argument("--case", action="append", required=True,
                        help="Exact structured-case name; may be repeated")
    parser.add_argument("--rounds", type=int, default=3)
    parser.add_argument("--batches", type=int, default=1)
    parser.add_argument("--repetitions", type=int, default=1)
    parser.add_argument("--timeout", type=float, default=3600)
    args = parser.parse_args()
    if (not 1 <= args.rounds <= 10000 or not 1 <= args.batches <= 100000
            or not 1 <= args.repetitions <= 1000000000
            or not math.isfinite(args.timeout) or args.timeout <= 0):
        parser.error("invalid harness limits or timeout")
    args.harness = args.harness.resolve()
    args.library_a = args.library_a.resolve()
    args.library_b = args.library_b.resolve()
    requested = set(args.case)
    if len(requested) != len(args.case):
        parser.error("case names must be unique")
    known = {f"{prefix}_{n}" for n in range(1, 10)
             for prefix in ("left_identity", "right_identity", "constant_convolution")}
    known.update(f"{prefix}_{n}" for n in range(3, 10)
                 for prefix in ("noncommuting_left_first", "noncommuting_right_first",
                                "two_support_left", "two_support_right"))
    known.update(f"{prefix}_{n}" for n in range(2, 10)
                 for prefix in ("sign_character_left", "sign_character_right", "even_subgroup_left",
                                "coordinate_left_first", "coordinate_right_first"))
    known.update(f"{prefix}_{n}" for n in range(3, 6)
                 for prefix in ("three_support_left", "three_support_right"))
    known.add("maximum_frame_extra_word")
    if requested - known:
        parser.error("unknown case(s): " + ", ".join(sorted(requested - known)))
    degrees = {int(name.rsplit("_", 1)[1]) for name in requested
               if name != "maximum_frame_extra_word"}
    for case in cases(degrees=degrees, include_extra="maximum_frame_extra_word" in requested):
        if case[0] in requested:
            run_case(args, case)
            requested.remove(case[0])
            if not requested:
                break
    if requested:
        raise ValueError("case generator omitted: " + ", ".join(sorted(requested)))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, subprocess.TimeoutExpired, ValueError, RuntimeError) as error:
        print(f"paired comparison failed: {error}", file=sys.stderr)
        raise SystemExit(1)
