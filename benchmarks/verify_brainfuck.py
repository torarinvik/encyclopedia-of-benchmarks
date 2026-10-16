#!/usr/bin/env python3
"""Verify bounded Brainfuck ports against an independent bytecode interpreter."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from itertools import product
import json
from pathlib import Path
import random
import subprocess
import sys

from brainfuck_oracle import (
    MAX_INPUT_BYTES, MAX_INPUT_LENGTH, MAX_OUTPUT_BYTES, MAX_PROGRAM_LENGTH,
    MAX_STEPS, TAPE_RADIUS, expected_output as contract_oracle,
)
from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import expected_output as recorder_expected_output
from run_i64_array_bytes_output import fnv1a

ALGORITHM = "brainfuck"
WORKLOAD_PATH = ROOT / "benchmarks/b/brainfuck/workload.json"
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
STRAIGHT_COMMANDS = b"+-.,><"


def oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Independent interpreter using byte cells and a bidirectional bounded tape."""
    if (not isinstance(values, (tuple, list)) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -2, b""
    program_length = values[0]
    if not 0 <= program_length <= MAX_PROGRAM_LENGTH or len(values) < program_length + 2:
        return -2, b""
    program = values[1:program_length + 1]
    input_length_index = program_length + 1
    input_length = values[input_length_index]
    inputs = values[input_length_index + 1:]
    if (not 0 <= input_length <= MAX_INPUT_BYTES or len(inputs) != input_length
            or len(values) != input_length_index + input_length + 1
            or any(not 32 <= byte <= 126 for byte in program)
            or any(not 0 <= byte <= 255 for byte in inputs)):
        return -2, b""

    pairs: dict[int, int] = {}
    openings: list[int] = []
    for position, command in enumerate(program):
        if command == ord("["):
            openings.append(position)
        elif command == ord("]"):
            if not openings:
                return -2, b""
            opening = openings.pop()
            pairs[opening] = position
            pairs[position] = opening
    if openings:
        return -2, b""

    cells: dict[int, int] = {}
    pointer = 0
    input_cursor = 0
    instruction = 0
    steps = 0
    output = bytearray()
    while instruction < program_length:
        steps += 1
        if steps > MAX_STEPS:
            return -2, b""
        command = program[instruction]
        cell = cells.get(pointer, 0)
        if command == ord("."):
            output.append(cell)
            if len(output) > MAX_OUTPUT_BYTES:
                return -2, b""
        elif command == ord(","):
            cells[pointer] = inputs[input_cursor] if input_cursor < input_length else 0
            if input_cursor < input_length:
                input_cursor += 1
        elif command == ord(">"):
            pointer += 1
            if pointer > TAPE_RADIUS:
                return -2, b""
        elif command == ord("<"):
            pointer -= 1
            if pointer < -TAPE_RADIUS:
                return -2, b""
        elif command == ord("+"):
            cells[pointer] = (cell + 1) & 255
        elif command == ord("-"):
            cells[pointer] = (cell - 1) & 255
        elif command == ord("[") and cell == 0:
            instruction = pairs[instruction]
        elif command == ord("]") and cell != 0:
            instruction = pairs[instruction]
        instruction += 1
    return len(output), bytes(output)


def corpus(workload: dict) -> tuple[str, int, dict[tuple[tuple[int, ...], int], tuple[int, bytes]]]:
    cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
    default_capacity = workload["workspace"]["bytes"]

    def add(values: tuple[int, ...] | list[int], capacity: int = default_capacity) -> None:
        packed = tuple(values)
        reference = oracle(packed)
        if contract_oracle(list(packed)) != reference:
            raise ValueError(f"independent and recorder oracles disagree for {packed[:16]}")
        if not 0 <= capacity <= MAX_OUTPUT_BYTES:
            raise ValueError(f"invalid output capacity {capacity}")
        actual = (-2, b"") if reference[0] >= 0 and capacity < len(reference[1]) else reference
        cases[(packed, capacity)] = actual

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        required = oracle(values)
        capacity = case.get("workspace_bytes", default_capacity)
        result, payload = (-2, b"") if required[0] >= 0 and capacity < len(required[1]) else required
        if (case.get("input_length") != len(values)
                or case.get("expected_result") != result
                or case.get("expected_output_hex") != payload.hex()):
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        add(values, capacity)

    # Exhaust every short straight-line combination. Loops are added below
    # using terminating templates so a corpus case cannot dominate runtime.
    for length in range(6):
        for commands in product(STRAIGHT_COMMANDS, repeat=length):
            program = bytes(commands)
            add((len(program), *program, 0))

    loop_programs = (
        b"+[-].", b"---[+] .", b"+++[.-]", b"+[>+<-]>.",
        b"++[>++[>+<-]<-]>>.", b"+++[>++[>+<-]<-]>>.",
        b"+[.-]", b"++[>+<-]>.", b"++++[>.<-]",
        b"[[]]", b"+[[]-]", b"++[>[-]<-]",
    )
    for program in loop_programs:
        add((len(program), *program, 0))
    for program, inputs in (
        (b",.,.,.", (0, 1, 255)), (b",.,.", (65,)),
        (b"+.", ()), (b"-.", ()), (b"ignored", ()),
    ):
        add((len(program), *program, len(inputs), *inputs))

    rng = random.Random(20261015)
    for _ in range(768):
        program = bytes(rng.choice(STRAIGHT_COMMANDS) for _ in range(rng.randrange(129)))
        inputs = [rng.randrange(256) for _ in range(rng.randrange(17))]
        add((len(program), *program, len(inputs), *inputs))

    sample_output = (2, ord("+"), ord("."), 0)
    for capacity in (0, 1, 2, 8192):
        add(sample_output, capacity)
    invalid_inputs = (
        (), (-1, 0), (MAX_PROGRAM_LENGTH + 1, 0),
        (0,), (0, 0), (1, ord("+"), -1),
        (1, ord("+"), MAX_INPUT_BYTES + 1),
        (1, ord("+"), 1), (1, ord("+"), 0, 7),
        (1, 31, 0), (1, 127, 0),
        (1, ord("+"), 1, -1), (1, ord("+"), 1, 256),
        (1, ord("]"), 0), (1, ord("["), 0),
        (2, ord("["), ord("]"), 0, 0),
        (MAX_PROGRAM_LENGTH + 1, *([ord("+")] * (MAX_PROGRAM_LENGTH + 1)), 0),
    )
    for values in invalid_inputs:
        add(values)
    for program in (b"<", b">"):
        add((1, *program, 0), default_capacity)
    add((3, ord("+"), ord("["), ord("]"), 0), default_capacity)
    add((37, ord("-"), ord("["), *([ord(".")] * 33), ord("-"), ord("]"), 0),
        default_capacity)

    records = sorted(cases.items(), key=lambda item: (len(item[0][0]), item[0][0], item[0][1]))
    lines = [f"{len(records)}\n"]
    for (values, capacity), (result, payload) in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {result} {len(payload)} {capacity}{suffix} {payload.hex() or '-'}\n")
    return "".join(lines), len(records), cases


def verify(language: str, directory: Path, elisa_compiler: str | None,
           checker_input: str, case_count: int, cases: dict, workload: dict) -> dict:
    shims = ((ROOT / "benchmarks/harness/elisa_empty_stack_arena_free.c",)
             if language == "elisa" else ())
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output",
                     extra_link_sources=shims)
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=checker_input, capture_output=True,
                             text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"byte-output ABI check failed: {checked.stdout}\n{checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete Brainfuck oracle corpus")

    output_path = directory / "verification-records.jsonl"
    output_path.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output_path),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = tuple(case["input_values"])
        required = oracle(values)
        capacity = case.get("workspace_bytes", len(required[1]))
        expected = (-2, b"") if required[0] >= 0 and capacity < len(required[1]) else required
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != list(values)
                or record["workload"]["output_capacity"] != capacity
                or record["workload"]["expected_result"] != expected[0]
                or record["measurement"]["observed_result"] != expected[0]
                or record["measurement"]["result_checksum"] != fnv1a(expected[1])):
            raise RuntimeError(f"recorder provenance/result mismatch: {case['id']}")
    return {
        "algorithm": ALGORITHM, "language": language, "status": "passed",
        "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
        "workload_records": len(records), "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(output_path), "recorder_output_sha256": sha256_file(output_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_bytes_output/b/brainfuck")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    checker_input, case_count, cases = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / "brainfuck-corpus.txt"
    corpus_path.write_text(checker_input, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language,
                                args.elisa_compiler, checker_input, case_count, cases, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                result = {"algorithm": ALGORITHM, "language": language,
                          "status": "failed", "error": str(error)}
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
            else:
                print(f"PASS {ALGORITHM}/{language}: {case_count} cases", flush=True)
            results.append(result)
    report = {"algorithm": ALGORITHM, "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(report_path)
    return 0 if all(item["status"] == "passed" for item in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
