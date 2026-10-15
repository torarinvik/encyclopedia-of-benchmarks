#!/usr/bin/env python3
"""Record a built read-only i64-array scalar benchmark."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import platform
import shlex
import subprocess
import sys
from functools import lru_cache

from build_abi import ROOT, sha256_file

I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def encode_case(case: dict, algorithm: str) -> list[int]:
    values, expected = case.get("input_values"), case.get("expected_result")
    if (not isinstance(values, list) or len(values) > 100001
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
            or type(expected) is not int):
        raise ValueError("array scalar cases require up to 100001 signed 64-bit values")
    if algorithm == "count_vowels_consonants":
        if len(values) > 100_000 or any(not 0 <= value <= 127 for value in values):
            raise ValueError("count_vowels_consonants requires at most 100000 ASCII code points")
        vowels = consonants = 0
        for codepoint in values:
            if 65 <= codepoint <= 90 or 97 <= codepoint <= 122:
                letter = codepoint | 32
                if letter in (97, 101, 105, 111, 117):
                    vowels += 1
                else:
                    consonants += 1
        expected_from_source = vowels * (2**32) + consonants
        if expected != expected_from_source:
            raise ValueError("count_vowels_consonants expected_result must match the packed ASCII counts")
    elif algorithm == "count_islands_in_matrix":
        valid_shape = (
            len(values) >= 2
            and 1 <= values[0] <= 16
            and 1 <= values[1] <= 16
            and len(values) == 2 + values[0] * values[1]
            and all(value in (0, 1) for value in values[2:])
        )
        if not valid_shape:
            if expected != -1:
                raise ValueError("invalid count_islands_in_matrix inputs must return -1")
        else:
            rows, columns = values[:2]
            cells = values[2:]
            visited: set[int] = set()
            island_count = 0
            for start, cell in enumerate(cells):
                if cell != 1 or start in visited:
                    continue
                island_count += 1
                visited.add(start)
                stack = [start]
                while stack:
                    current = stack.pop()
                    row, column = divmod(current, columns)
                    for next_row in range(max(0, row - 1), min(rows, row + 2)):
                        for next_column in range(max(0, column - 1), min(columns, column + 2)):
                            neighbor = next_row * columns + next_column
                            if cells[neighbor] == 1 and neighbor not in visited:
                                visited.add(neighbor)
                                stack.append(neighbor)
            if expected != island_count:
                raise ValueError("count_islands_in_matrix expected_result must match eight-neighbor connectivity")
    elif algorithm == "number_of_islands":
        valid_shape = (
            len(values) >= 2
            and 1 <= values[0] <= 16
            and 1 <= values[1] <= 16
            and len(values) == 2 + values[0] * values[1]
            and all(value in (0, 1) for value in values[2:])
        )
        if not valid_shape:
            if expected != -1:
                raise ValueError("invalid number_of_islands inputs must return -1")
        else:
            rows, columns = values[:2]
            cells = values[2:]
            visited: set[int] = set()
            island_count = 0
            for start, cell in enumerate(cells):
                if cell != 1 or start in visited:
                    continue
                island_count += 1
                visited.add(start)
                stack = [start]
                while stack:
                    current = stack.pop()
                    row, column = divmod(current, columns)
                    for next_row, next_column in ((row - 1, column), (row + 1, column),
                                                  (row, column - 1), (row, column + 1)):
                        if 0 <= next_row < rows and 0 <= next_column < columns:
                            neighbor = next_row * columns + next_column
                            if cells[neighbor] == 1 and neighbor not in visited:
                                visited.add(neighbor)
                                stack.append(neighbor)
            if expected != island_count:
                raise ValueError("number_of_islands expected_result must match four-neighbor connectivity")
    elif algorithm == "equilibrium_index_in_array":
        valid_shape = (len(values) >= 1 and 0 <= values[0] <= 1024 and len(values) == values[0] + 1
                       and all(-(2**31) <= value <= 2**31 - 1 for value in values[1:]))
        if not valid_shape:
            expected_from_source = -2
        else:
            items = values[1:]
            remaining_sum = sum(items)
            left_sum = 0
            expected_from_source = -1
            for index, value in enumerate(items):
                remaining_sum -= value
                if left_sum == remaining_sum:
                    expected_from_source = index
                    break
                left_sum += value
        if expected != expected_from_source:
            raise ValueError("equilibrium_index_in_array expected_result must be the first index with equal side sums")
    elif algorithm == "check_snake_case":
        if len(values) > 4096 or any(not 32 <= value <= 126 for value in values):
            expected_from_source = -2
        else:
            expected_from_source = int(95 in values)
        if expected != expected_from_source:
            raise ValueError("check_snake_case expected_result must match the printable-ASCII underscore predicate")
    elif algorithm == "check_kebab_case":
        if len(values) > 4096 or any(not 32 <= value <= 126 for value in values):
            expected_from_source = -2
        elif 95 in values:
            expected_from_source = 0
        else:
            def ascii_word(value: int) -> bool:
                return 48 <= value <= 57 or 65 <= value <= 90 or 97 <= value <= 122

            expected_from_source = int(any(
                value == 45 and ascii_word(values[index - 1]) and ascii_word(values[index + 1])
                for index, value in enumerate(values[1:-1], start=1)
            ))
        if expected != expected_from_source:
            raise ValueError("check_kebab_case expected_result must match the printable-ASCII hyphen predicate")
    elif algorithm == "is_lower":
        if len(values) > 4096 or any(not 32 <= value <= 126 for value in values):
            expected_from_source = -1
        else:
            expected_from_source = int(not any(65 <= value <= 90 for value in values))
        if expected != expected_from_source:
            raise ValueError("is_lower expected_result must be 1 exactly when no ASCII uppercase letter occurs")
    elif algorithm == "alphabetical":
        valid = len(values) <= 256 and all(0 <= value <= 127 for value in values)
        if not valid:
            expected_from_source = -1
        else:
            letters = []
            for value in values:
                if 65 <= value <= 90:
                    letters.append(value + 32)
                elif 97 <= value <= 122:
                    letters.append(value)
                else:
                    break
            expected_from_source = int(bool(values) and len(letters) == len(values)
                                       and all(left <= right for left, right in zip(letters, letters[1:])))
        if expected != expected_from_source:
            raise ValueError("alphabetical expected_result must match the ASCII case-insensitive order predicate")
    elif algorithm == "indian_phone_validator":
        import re

        if not 1 <= len(values) <= 18 or any(not 0 <= value <= 127 for value in values):
            expected_from_source = -1
        else:
            text = bytes(values).decode("ascii")
            pattern = r"^(\+91[\-\s]?)?[0]?(91)?[789]\d{9}$"
            expected_from_source = int(re.search(pattern, text) is not None)
        if expected != expected_from_source:
            raise ValueError("indian_phone_validator expected_result must match the bounded source regular expression")
    elif algorithm == "count_nice_subarrays":
        valid = (len(values) >= 2 and 0 <= values[0] <= 4096
                 and 1 <= values[1] <= 4096 and len(values) == values[0] + 2
                 and all(-(2**31) <= value <= 2**31 - 1 for value in values[2:]))
        if not valid:
            expected_from_source = -1
        else:
            n, target = values[:2]
            prefix_counts = {0: 1}
            odd_prefix = answer = 0
            for value in values[2:]:
                odd_prefix += value & 1
                answer += prefix_counts.get(odd_prefix - target, 0)
                prefix_counts[odd_prefix] = prefix_counts.get(odd_prefix, 0) + 1
            expected_from_source = answer
        if expected != expected_from_source:
            raise ValueError("count_nice_subarrays expected_result must match the exact odd-count prefix oracle")
    elif algorithm == "count_substrings":
        valid = (len(values) >= 2 and 0 <= values[0] <= 4096 and 0 <= values[1] <= 4096
                 and len(values) == 2 + values[0] + values[1]
                 and all(0 <= value <= 127 for value in values[2:]))
        if not valid:
            expected_from_source = -1
        else:
            text_length, pattern_length = values[:2]
            text = values[2:2 + text_length]
            pattern = values[2 + text_length:]
            if pattern_length == 0:
                expected_from_source = text_length + 1
            else:
                expected_from_source = sum(
                    text[start:start + pattern_length] == pattern
                    for start in range(text_length - pattern_length + 1)
                )
        if expected != expected_from_source:
            raise ValueError("count_substrings expected_result must count overlapping ASCII matches")
    elif algorithm == "count_consonants":
        valid = (1 <= len(values) <= 4096 and all(32 <= value <= 126 for value in values)
                 and values != [48])
        if not valid:
            expected_from_source = -1
        else:
            expected_from_source = sum(
                1 for value in values
                if (65 <= value <= 90 or 97 <= value <= 122)
                and (value | 32) not in (97, 101, 105, 111, 117)
            )
        if expected != expected_from_source:
            raise ValueError("count_consonants expected_result must match the ASCII consonant count")
    elif algorithm == "count_char":
        valid = len(values) <= 4096 and all(0 <= value <= 127 for value in values)
        if not valid:
            expected_from_source = -1
        else:
            java_regex_whitespace = {9, 10, 11, 12, 13, 32}
            expected_from_source = sum(value not in java_regex_whitespace for value in values)
        if expected != expected_from_source:
            raise ValueError("count_char expected_result must count ASCII values outside Java regex whitespace")
    elif algorithm == "parity_outlier":
        valid = (len(values) >= 1 and 3 <= values[0] <= 65 and values[0] % 2 == 1
                 and len(values) == values[0] + 1
                 and all(0 <= value <= 2**31 - 1 for value in values[1:]))
        if not valid:
            expected_from_source = -1
        else:
            evens = [value for value in values[1:] if value % 2 == 0]
            odds = [value for value in values[1:] if value % 2 == 1]
            if len(evens) == 1 and len(odds) >= 2:
                expected_from_source = evens[0]
            elif len(odds) == 1 and len(evens) >= 2:
                expected_from_source = odds[0]
            else:
                expected_from_source = -1
        if expected != expected_from_source:
            raise ValueError("parity_outlier expected_result must match the unique parity singleton")
    elif algorithm == "is_contains_unique_chars":
        valid = len(values) <= 4096 and all(0 <= value <= 127 for value in values)
        if not valid:
            expected_from_source = -1
        else:
            expected_from_source = int(len(values) == len(set(values)))
        if expected != expected_from_source:
            raise ValueError("is_contains_unique_chars expected_result must match exact ASCII uniqueness")
    elif algorithm == "is_pangram":
        valid = len(values) <= 4096 and all(0 <= value <= 127 for value in values)
        if not valid:
            expected_from_source = -1
        else:
            letters = {value | 32 for value in values if 65 <= value <= 90 or 97 <= value <= 122}
            expected_from_source = int(len(letters) == 26)
        if expected != expected_from_source:
            raise ValueError("is_pangram expected_result must match the case-insensitive ASCII alphabet predicate")
    elif algorithm == "is_uppercase":
        valid = len(values) <= 4096 and all(32 <= value <= 126 for value in values)
        if not valid:
            expected_from_source = -1
        else:
            expected_from_source = int(not any(97 <= value <= 122 for value in values))
        if expected != expected_from_source:
            raise ValueError("is_uppercase expected_result must be 1 exactly when no ASCII lowercase letter occurs")
    elif algorithm == "percentage_of_letters":
        valid = (2 <= len(values) <= 4097 and 0 <= values[0] <= 127
                 and (65 <= values[0] <= 90 or 97 <= values[0] <= 122)
                 and all(0 <= value <= 127 for value in values[1:]))
        if not valid:
            expected_from_source = -1
        else:
            target = values[0] | 32
            matches = sum(1 for value in values[1:]
                          if (65 <= value <= 90 or 97 <= value <= 122) and (value | 32) == target)
            expected_from_source = 100 * matches // (len(values) - 1)
        if expected != expected_from_source:
            raise ValueError("percentage_of_letters expected_result must match the floored ASCII percentage")
    elif algorithm == "is_sorted":
        valid = len(values) <= 4096 and all(-(2**31) <= value <= 2**31 - 1 for value in values)
        if not valid:
            expected_from_source = -1
        else:
            expected_from_source = int(all(left <= right for left, right in zip(values, values[1:])))
        if expected != expected_from_source:
            raise ValueError("is_sorted expected_result must match the Lua nondecreasing numeric predicate")
    elif algorithm == "validate_subsequence":
        valid = (len(values) >= 2 and 0 <= values[0] <= 4096 and 0 <= values[1] <= 4096
                 and len(values) == 2 + values[0] + values[1]
                 and all(-(2**31) <= value <= 2**31 - 1 for value in values[2:]))
        if not valid:
            expected_from_source = -1
        else:
            array_length, sequence_length = values[:2]
            array = values[2:2 + array_length]
            sequence = values[2 + array_length:]
            if not array:
                expected_from_source = 0
            else:
                sequence_index = 0
                for value in array:
                    if sequence_index < sequence_length and value == sequence[sequence_index]:
                        sequence_index += 1
                expected_from_source = int(sequence_index == sequence_length)
        if expected != expected_from_source:
            raise ValueError("validate_subsequence expected_result must match the packed greedy scan")
    elif algorithm == "binary_tree_is_sorted_local":
        missing = -(2**31) - 1
        valid = (1 <= len(values) <= 255 and values[0] != missing
                 and all(value == missing or -(2**31) <= value <= 2**31 - 1 for value in values))
        if valid:
            for index in range(1, len(values)):
                if values[index] != missing and values[(index - 1) // 2] == missing:
                    valid = False
                    break
        if not valid:
            expected_from_source = -1
        else:
            ordered = True
            for index, value in enumerate(values):
                if value == missing:
                    continue
                left, right = 2 * index + 1, 2 * index + 2
                if left < len(values) and values[left] != missing and values[left] > value:
                    ordered = False
                    break
                if right < len(values) and values[right] != missing and values[right] < value:
                    ordered = False
                    break
            expected_from_source = int(ordered)
        if expected != expected_from_source:
            raise ValueError("binary_tree_is_sorted_local expected_result must match direct child ordering")
    elif algorithm == "kth_smallest":
        valid = (len(values) >= 2 and 1 <= values[0] <= 256 and 1 <= values[1] <= values[0]
                 and len(values) == 2 + values[0]
                 and all(-(2**31) <= value <= 2**31 - 1 for value in values[2:]))
        expected_from_source = sorted(values[2:])[values[1] - 1] if valid else I64_MIN
        if expected != expected_from_source:
            raise ValueError("kth_smallest expected_result must match the bounded one-based order statistic")
    elif algorithm in {"polynomial_evaluation", "polynomial_evaluation_direct"}:
        valid = (len(values) >= 2 and 0 <= values[0] <= 8 and len(values) == 2 + values[0]
                 and -10 <= values[1] <= 10
                 and all(-1000 <= coefficient <= 1000 for coefficient in values[2:]))
        if not valid:
            expected_from_source = I64_MIN
        else:
            x = values[1]
            if algorithm == "polynomial_evaluation_direct":
                expected_from_source = sum(coefficient * (x ** index)
                                           for index, coefficient in enumerate(values[2:]))
            else:
                expected_from_source = 0
                for coefficient in reversed(values[2:]):
                    expected_from_source = expected_from_source * x + coefficient
        if expected != expected_from_source:
            method = "direct power summation" if algorithm == "polynomial_evaluation_direct" else "Horner evaluation"
            raise ValueError(f"{algorithm} expected_result must match bounded {method}")
    elif algorithm == "subset_sum_dynamic":
        valid = (1 <= len(values) <= 17 and -80 <= values[0] <= 80
                 and all(-20 <= value <= 20 for value in values[1:]))
        if not valid:
            expected_from_source = -1
        else:
            target, items = values[0], tuple(values[1:])

            @lru_cache(maxsize=None)
            def has_subset(index: int, remaining: int) -> bool:
                if remaining == 0:
                    return True
                if index == len(items):
                    return False
                return has_subset(index + 1, remaining - items[index]) or has_subset(index + 1, remaining)

            expected_from_source = int(has_subset(0, target))
        if expected != expected_from_source:
            raise ValueError("subset_sum_dynamic expected_result does not match memoized subset existence")
    elif algorithm == "hash_sdbm":
        valid = 1 <= len(values) <= 64 and all(1 <= byte <= 127 for byte in values)
        if not valid:
            expected_from_source = -1
        else:
            hash_value = 0
            for byte in values:
                hash_value = (byte + (hash_value << 6) + (hash_value << 16) - hash_value) & (2**64 - 1)
            expected_from_source = hash_value if hash_value < 2**63 else hash_value - 2**64
        if expected != expected_from_source:
            raise ValueError("hash_sdbm expected_result must be the signed i64 interpretation of the SDBM hash")
    elif algorithm == "average_mode":
        valid = 1 <= len(values) <= 64 and all(0 <= value <= 1000 for value in values)
        if not valid:
            expected_from_source = -1
        else:
            frequencies: dict[int, int] = {}
            for value in values:
                frequencies[value] = frequencies.get(value, 0) + 1
            maximum = max(frequencies.values())
            leaders = [value for value, count in frequencies.items() if count == maximum]
            expected_from_source = leaders[0] if len(leaders) == 1 else -1
        if expected != expected_from_source:
            raise ValueError("average_mode expected_result must match the unique mode in the bounded input")
    return values


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-manifest", required=True, type=Path)
    parser.add_argument("--workload", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--samples", type=int)
    parser.add_argument("--warmups", type=int)
    parser.add_argument("--repetitions", type=int)
    args = parser.parse_args()
    manifest = json.loads(args.build_manifest.read_text(encoding="utf-8"))
    if manifest.get("family") != "i64_array_scalar":
        parser.error("build manifest must declare the i64_array_scalar ABI family")
    algorithm, language = manifest["algorithm"], manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["i64_array_scalar_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/i64_array_scalar_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        parser.error("workload does not match the built array scalar algorithm")
    timing = workload["measurement"]
    samples = args.samples if args.samples is not None else timing["sample_count"]
    warmups = args.warmups if args.warmups is not None else timing["warmup_rounds"]
    repetitions = args.repetitions if args.repetitions is not None else timing["repetitions_per_sample"]
    if not 1 <= samples <= 10000 or not 0 <= warmups <= 100000 or not 1 <= repetitions <= 1000000000:
        parser.error("sample/warmup/repetition counts exceed the runner limits")
    if len({case["id"] for case in workload["cases"]}) != len(workload["cases"]):
        parser.error("workload case IDs must be unique")
    run_id = dt.datetime.now(dt.timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")
    implementation = {key: manifest[key] for key in (
        "language", "source_path", "source_sha256", "compiler", "compiler_version", "build_flags")}
    implementation.update({"runner_source_sha256": binary["harness_sha256"],
                           "binary_sha256": binary["sha256"],
                           "build_command": "\n".join(shlex.join(command) for command in manifest["commands"])})
    environment = {"os": platform.system(), "os_release": platform.release(),
                   "architecture": platform.machine(), "cpu_model": platform.processor().strip() or None,
                   "logical_cpu_count": os.cpu_count(), "python_version": platform.python_version()}
    records = []
    for case in workload["cases"]:
        values = encode_case(case, algorithm)
        if case.get("input_length") not in (None, len(values)):
            raise ValueError(f"declared input length differs for {case['id']}")
        if len(values) > 1024:
            command = [str(executable), "--stdin", str(len(values)), str(case["expected_result"]),
                       str(samples), str(warmups), str(repetitions)]
            streamed_values = " ".join(map(str, values)) + "\n"
        else:
            command = [str(executable), str(len(values)), *map(str, values), str(case["expected_result"]),
                       str(samples), str(warmups), str(repetitions)]
            streamed_values = None
        completed = subprocess.run(command, input=streamed_values, capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"array scalar runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        if raw["observed_result"] != case["expected_result"] or len(raw["samples_ns"]) != samples:
            raise ValueError(f"array scalar runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": len(values), "input_values": values,
                                     "case": case["id"], "target": None,
                                     "expected_result": case["expected_result"]},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "i64_array_scalar_call",
                                        "target_comparisons_per_sample": None,
                                        "warmup_rounds": warmups, "repetitions_per_sample": repetitions,
                                        "samples_ns": raw["samples_ns"],
                                        "observed_result": raw["observed_result"],
                                        "result_checksum": raw["result_checksum"]}})
    output = args.output or ROOT / "results" / letter / algorithm / f"{language}.jsonl"
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("a", encoding="utf-8", newline="\n") as destination:
        for record in records:
            destination.write(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n")
    print(f"appended {len(records)} result records to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
