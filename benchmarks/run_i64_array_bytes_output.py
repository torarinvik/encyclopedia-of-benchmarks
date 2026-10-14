#!/usr/bin/env python3
"""Record a byte-output benchmark over a signed 64-bit input array."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import platform
import shlex
import subprocess
import sys

from build_abi import ROOT, sha256_file

MAX_INPUT_LENGTH = 66
KEYPAD = {2: b"abc", 3: b"def", 4: b"ghi", 5: b"jkl", 6: b"mno",
          7: b"pqrs", 8: b"tuv", 9: b"wxyz"}


def expected_output(values: list[int], algorithm: str = "letter_combinations_of_phone_number") -> tuple[int, bytes]:
    if algorithm in {"rot13", "theoretical_rot13"}:
        if (len(values) > MAX_INPUT_LENGTH
                or any(type(value) is not int or not 1 <= value <= 127 for value in values)):
            return -1, b""
        output = bytearray(values)
        for index, value in enumerate(output):
            if algorithm == "rot13" and ord("A") <= value <= ord("Z"):
                output[index] = ord("A") + (value - ord("A") + 13) % 26
            elif ord("a") <= value <= ord("z"):
                output[index] = ord("a") + (value - ord("a") + 13) % 26
        return len(output), bytes(output)

    if algorithm == "tower_of_hanoi":
        if (len(values) != 4 or any(type(value) is not int for value in values)
                or not 0 <= values[0] <= 12
                or any(not 0 <= peg <= 2 for peg in values[1:])
                or len(set(values[1:])) != 3):
            return -1, b""
        disks, source, destination, auxiliary = values
        moves = bytearray()

        def emit(count: int, origin: int, target: int, spare: int) -> None:
            if count == 0:
                return
            emit(count - 1, origin, spare, target)
            moves.extend((origin, target))
            emit(count - 1, spare, target, origin)

        emit(disks, source, destination, auxiliary)
        return len(moves) // 2, bytes(moves)

    if algorithm in {"breadth_first_search", "depth_first_search"}:
        if (not 2 <= len(values) <= MAX_INPUT_LENGTH
                or any(type(value) is not int for value in values)
                or not 0 <= values[0] <= 64
                or (len(values) - 2) % 2 != 0):
            return -2, b""
        vertices, start = values[:2]
        if vertices == 0:
            return (0, b"") if start == -1 and len(values) == 2 else (-2, b"")
        if not 0 <= start < vertices:
            return -2, b""
        adjacency = [set() for _ in range(vertices)]
        for offset in range(2, len(values), 2):
            origin, destination = values[offset:offset + 2]
            if not 0 <= origin < vertices or not 0 <= destination < vertices:
                return -2, b""
            adjacency[origin].add(destination)
        order = []
        visited = {start}
        if algorithm == "breadth_first_search":
            queue = [start]
            head = 0
            while head < len(queue):
                origin = queue[head]
                head += 1
                order.append(origin)
                for destination in sorted(adjacency[origin]):
                    if destination not in visited:
                        visited.add(destination)
                        queue.append(destination)
        else:
            order.append(start)
            frames = [(start, iter(sorted(adjacency[start])))]
            while frames:
                origin, neighbors = frames[-1]
                destination = next(neighbors, None)
                if destination is None:
                    frames.pop()
                elif destination not in visited:
                    visited.add(destination)
                    order.append(destination)
                    frames.append((destination, iter(sorted(adjacency[destination]))))
        return len(order), bytes(order)

    if algorithm == "topological_sort":
        if (not 1 <= len(values) <= MAX_INPUT_LENGTH
                or any(type(value) is not int for value in values)
                or not 0 <= values[0] <= 64
                or (len(values) - 1) % 2 != 0):
            return -2, b""
        vertices = values[0]
        adjacency = [set() for _ in range(vertices)]
        indegree = [0] * vertices
        for offset in range(1, len(values), 2):
            origin, destination = values[offset:offset + 2]
            if not 0 <= origin < vertices or not 0 <= destination < vertices:
                return -2, b""
            if destination not in adjacency[origin]:
                adjacency[origin].add(destination)
                indegree[destination] += 1
        queue = [vertex for vertex, degree in enumerate(indegree) if degree == 0]
        order = []
        head = 0
        while head < len(queue):
            origin = queue[head]
            head += 1
            order.append(origin)
            for destination in range(vertices):
                if destination in adjacency[origin]:
                    indegree[destination] -= 1
                    if indegree[destination] == 0:
                        queue.append(destination)
        if len(order) != vertices:
            return -1, b""
        return vertices, bytes(order)

    if algorithm == "letter_combinations_of_phone_number":
        if len(values) == 0:
            return 0, b""
        if len(values) > 6 or any(value not in KEYPAD for value in values):
            return -1, b""
        rows = [b""]
        for value in values:
            rows = [prefix + bytes((letter,)) for prefix in rows for letter in KEYPAD[value]]
        output = b"".join(rows)
        return len(rows), output

    if algorithm in {"decimal_to_any_base", "decimal_to_any_using_stack"}:
        if (len(values) != 2 or any(type(value) is not int for value in values)):
            return -1, b""
        number, base = values
        maximum_base = 16 if algorithm == "decimal_to_any_using_stack" else 36
        if number < 0 or not 2 <= base <= maximum_base:
            return -1, b""
        alphabet = b"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        digits = bytearray()
        while number:
            number, digit = divmod(number, base)
            digits.append(alphabet[digit])
        if not digits:
            digits.append(ord("0"))
        digits.reverse()
        return len(digits), bytes(digits)

    if algorithm == "any_base_to_any_base":
        if (len(values) < 3 or len(values) > 65
                or any(type(value) is not int for value in values)):
            return -1, b""
        source_base, target_base = values[:2]
        if not 2 <= source_base <= 36 or not 2 <= target_base <= 36:
            return -1, b""
        number = 0
        for digit in values[2:]:
            if not 0 <= digit < source_base:
                return -1, b""
            number = number * source_base + digit
            if number > 2**63 - 1:
                return -1, b""
        alphabet = b"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        digits = bytearray()
        while number:
            number, digit = divmod(number, target_base)
            digits.append(alphabet[digit])
        if not digits:
            digits.append(ord("0"))
        digits.reverse()
        return len(digits), bytes(digits)

    if algorithm == "base_neg2_conversion":
        if (len(values) != 1 or type(values[0]) is not int
                or not -(2**63) <= values[0] < 2**63):
            return -1, b""
        number = values[0]
        digits = bytearray()
        while number:
            digit = number % 2
            digits.append(ord("0") + digit)
            number = (number - digit) // -2
        if not digits:
            digits.append(ord("0"))
        digits.reverse()
        return len(digits), bytes(digits)

    if algorithm == "base16":
        if (not 1 <= len(values) <= 65
                or any(type(value) is not int for value in values)):
            return -1, b""
        mode, payload = values[0], values[1:]
        if mode == 0:
            if any(not 0 <= value <= 255 for value in payload):
                return -1, b""
            encoded = bytes(payload).hex().upper().encode("ascii")
            return len(encoded), encoded
        if mode == 1:
            if (len(payload) % 2 != 0
                    or any(value not in b"0123456789ABCDEF" for value in payload)):
                return -1, b""
            encoded = bytes(payload).decode("ascii")
            decoded = bytes.fromhex(encoded)
            return len(decoded), decoded
        return -1, b""

    if algorithm == "base32":
        if (not 1 <= len(values) <= 66
                or any(type(value) is not int for value in values)):
            return -1, b""
        mode, payload = values[0], values[1:]
        alphabet = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        if mode == 0:
            if any(not 0 <= value <= 255 for value in payload):
                return -1, b""
            source = bytes(payload)
            if not source:
                return 0, b""
            output = bytearray()
            for offset in range(0, len(source), 5):
                block = source[offset:offset + 5]
                bits = len(block) * 8
                for symbol in range((bits + 4) // 5):
                    value = 0
                    for bit in range(symbol * 5, symbol * 5 + 5):
                        value <<= 1
                        if bit < bits:
                            value |= (block[bit // 8] >> (7 - bit % 8)) & 1
                    output.append(alphabet[value])
                while len(output) % 8:
                    output.append(ord("="))
            return len(output), bytes(output)
        if mode != 1:
            return -1, b""

        encoded = payload
        first_padding = next((index for index, value in enumerate(encoded) if value == ord("=")), len(encoded))
        content_length = first_padding
        padding_length = len(encoded) - content_length
        content = encoded[:content_length]
        if any(value not in alphabet for value in content) or any(value != ord("=") for value in encoded[content_length:]):
            return -1, b""
        remainder = content_length % 8
        expected_padding = {0: 0, 2: 6, 4: 4, 5: 3, 7: 1}.get(remainder)
        if expected_padding is None:
            return -1, b""
        if padding_length and (len(encoded) % 8 != 0 or padding_length != expected_padding):
            return -1, b""
        if content_length and remainder:
            final_value = alphabet.index(content[-1])
            unused_bits = {2: 2, 4: 4, 5: 1, 7: 3}[remainder]
            if final_value & ((1 << unused_bits) - 1):
                return -1, b""
        output_length = content_length * 5 // 8
        output = bytearray(output_length)
        for bit in range(output_length * 8):
            symbol_value = alphabet.index(content[bit // 5])
            output[bit // 8] |= ((symbol_value >> (4 - bit % 5)) & 1) << (7 - bit % 8)
        return output_length, bytes(output)

    if algorithm == "base64":
        if (not 1 <= len(values) <= 66
                or any(type(value) is not int for value in values)):
            return -1, b""
        mode, payload = values[0], values[1:]
        alphabet = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        if mode == 0:
            if any(not 0 <= value <= 255 for value in payload):
                return -1, b""
            source = bytes(payload)
            if not source:
                return 0, b""
            output = bytearray()
            symbols = (len(source) * 8 + 5) // 6
            output_length = ((len(source) + 2) // 3) * 4
            for symbol in range(output_length):
                if symbol >= symbols:
                    output.append(ord("="))
                    continue
                value = 0
                for bit in range(symbol * 6, symbol * 6 + 6):
                    value <<= 1
                    if bit < len(source) * 8:
                        value |= (source[bit // 8] >> (7 - bit % 8)) & 1
                output.append(alphabet[value])
            return output_length, bytes(output)
        if mode != 1:
            return -1, b""

        encoded = payload
        content_length = next((index for index, value in enumerate(encoded) if value == ord("=")), len(encoded))
        padding_length = len(encoded) - content_length
        content = encoded[:content_length]
        if any(value not in alphabet for value in content) or any(value != ord("=") for value in encoded[content_length:]):
            return -1, b""
        remainder = content_length % 4
        expected_padding = {0: 0, 2: 2, 3: 1}.get(remainder)
        if expected_padding is None:
            return -1, b""
        if padding_length and (len(encoded) % 4 != 0 or padding_length != expected_padding):
            return -1, b""
        if content_length and remainder:
            final_value = alphabet.index(content[-1])
            unused_bits = 4 if remainder == 2 else 2
            if final_value & ((1 << unused_bits) - 1):
                return -1, b""
        output_length = content_length * 6 // 8
        output = bytearray(output_length)
        for bit in range(output_length * 8):
            symbol_value = alphabet.index(content[bit // 6])
            output[bit // 8] |= ((symbol_value >> (5 - bit % 6)) & 1) << (7 - bit % 8)
        return output_length, bytes(output)

    if algorithm in {"binary_to_octal", "binary_to_hexadecimal"}:
        if (not 1 <= len(values) <= 63
                or any(type(value) is not int or value not in (0, 1) for value in values)):
            return -1, b""
        number = 0
        for bit in values:
            number = number * 2 + bit
        encoded = format(number, "o" if algorithm == "binary_to_octal" else "x").encode("ascii")
        return len(encoded), encoded

    if algorithm in {"octal_to_binary", "octal_to_hexadecimal"}:
        if (not 1 <= len(values) <= 21
                or any(type(value) is not int or value not in range(8) for value in values)):
            return -1, b""
        number = 0
        for digit in values:
            number = number * 8 + digit
        encoded = format(number, "b" if algorithm == "octal_to_binary" else "x").encode("ascii")
        return len(encoded), encoded

    if algorithm in {"hexadecimal_to_binary", "hexadecimal_to_octal"}:
        if (not 1 <= len(values) <= 16
                or any(type(value) is not int or value not in range(16) for value in values)):
            return -1, b""
        number = 0
        for digit in values:
            number = number * 16 + digit
        if number > 2**63 - 1:
            return -1, b""
        encoded = format(number, "b" if algorithm == "hexadecimal_to_binary" else "o").encode("ascii")
        return len(encoded), encoded

    raise ValueError(f"no byte-output oracle for {algorithm}")


def fnv1a(data: bytes) -> int:
    result = 14695981039346656037
    for value in data:
        result = ((result ^ value) * 1099511628211) & ((1 << 64) - 1)
    return result


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
    if manifest.get("family") != "i64_array_bytes_output":
        parser.error("build manifest must declare the i64_array_bytes_output ABI family")
    algorithm, language = manifest["algorithm"], manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["i64_array_bytes_output_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/i64_array_bytes_output_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call"):
        parser.error("workload does not match the built byte-output algorithm")
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
        values = case.get("input_values")
        if (not isinstance(values, list) or len(values) > MAX_INPUT_LENGTH
                or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
            raise ValueError(f"invalid signed 64-bit digit array in {case['id']}")
        if case.get("input_length") not in (None, len(values)):
            raise ValueError(f"declared input length differs for {case['id']}")
        expected_count, expected = expected_output(values, algorithm)
        if case.get("expected_result") != expected_count:
            raise ValueError(f"workload oracle mismatch for {case['id']}")
        output_hex = expected.hex() if expected else "-"
        command = [str(executable), str(len(values)), *map(str, values), str(expected_count),
                   output_hex, str(samples), str(warmups), str(repetitions)]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"byte-output runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        expected_checksum = (fnv1a(expected) * repetitions * samples) & ((1 << 64) - 1)
        if (raw["observed_result"] != expected_count or len(raw["samples_ns"]) != samples
                or raw["result_checksum"] != expected_checksum):
            raise ValueError(f"byte-output runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": len(values), "input_values": values,
                                     "case": case["id"], "target": None,
                                     "expected_result": expected_count},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "i64_array_bytes_output_call",
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
