#!/usr/bin/env python3
"""Check polygon-area batches against an exact integer shoelace oracle."""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import hashlib
import itertools
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "area_of_polygon"
MAX_POLYGONS = 32
MAX_VERTICES_PER_POLYGON = 128
MAX_TOTAL_VERTICES = 512
MAX_INPUT_VALUES = 1057
COORDINATE_LIMIT = 1_000_000
AREA_OFFSET = 1_000_000_007


def oracle(values: list[int] | tuple[int, ...]) -> int:
    if not 1 <= len(values) <= MAX_INPUT_VALUES:
        return -1
    polygon_count = values[0]
    if not 0 <= polygon_count <= MAX_POLYGONS:
        return -1
    cursor = 1
    total_vertices = 0
    checksum = 0
    for polygon in range(polygon_count):
        if cursor >= len(values):
            return -1
        vertex_count = values[cursor]
        cursor += 1
        if not 3 <= vertex_count <= MAX_VERTICES_PER_POLYGON:
            return -1
        if total_vertices + vertex_count > MAX_TOTAL_VERTICES:
            return -1
        if cursor + 2 * vertex_count > len(values):
            return -1
        points = []
        for vertex in range(vertex_count):
            x, y = values[cursor + 2 * vertex:cursor + 2 * vertex + 2]
            if not -COORDINATE_LIMIT <= x <= COORDINATE_LIMIT:
                return -1
            if not -COORDINATE_LIMIT <= y <= COORDINATE_LIMIT:
                return -1
            points.append((x, y))
        cursor += 2 * vertex_count
        total_vertices += vertex_count
        cross_sum = sum(
            points[index][0] * points[(index + 1) % vertex_count][1]
            - points[(index + 1) % vertex_count][0] * points[index][1]
            for index in range(vertex_count)
        )
        checksum += (polygon + 1) * (abs(cross_sum) + AREA_OFFSET)
    return checksum if cursor == len(values) else -1


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}

    def include(values: list[int] | tuple[int, ...]) -> None:
        packed = tuple(values)
        cases[packed] = oracle(packed)

    # All ordered triangles on the 5-by-5 integer grid exercise orientation,
    # degeneracy, repeated vertices, and exact half-unit areas.
    grid = tuple(itertools.product(range(-2, 3), repeat=2))
    for points in itertools.product(grid, repeat=3):
        include((1, 3, *(coordinate for point in points for coordinate in point)))

    rng = random.Random(20261014)
    for _ in range(768):
        polygon_count = rng.randrange(MAX_POLYGONS + 1)
        packed = [polygon_count]
        remaining = MAX_TOTAL_VERTICES
        for polygon in range(polygon_count):
            largest_count = min(MAX_VERTICES_PER_POLYGON,
                                remaining - 3 * (polygon_count - polygon - 1))
            vertex_count = rng.randrange(3, largest_count + 1)
            packed.append(vertex_count)
            for _vertex in range(vertex_count):
                packed.extend((rng.randrange(-COORDINATE_LIMIT, COORDINATE_LIMIT + 1),
                               rng.randrange(-COORDINATE_LIMIT, COORDINATE_LIMIT + 1)))
            remaining -= vertex_count
        include(packed)

    include((1, 128, *(coordinate for index in range(128)
                       for coordinate in ((index % 16) * 10, (index // 16) * 10))))
    too_many_vertices = [5]
    for _ in range(5):
        too_many_vertices.extend((104, *(0 for _ in range(208))))
    malformed = [
        (), (-1,), (MAX_POLYGONS + 1,), (1,), (1, 2, 0, 0, 1, 0),
        (1, MAX_VERTICES_PER_POLYGON + 1, *(0 for _ in range(2 * (MAX_VERTICES_PER_POLYGON + 1)))),
        (1, 3, 0, 0, COORDINATE_LIMIT + 1, 0, 0, 1),
        (1, 3, 0, 0, 0, -COORDINATE_LIMIT - 1, 1, 1),
        (1, 3, 0, 0, 1, 0), (0, 1), tuple(too_many_vertices),
        tuple([1, 3, 0, 0, 1, 0, 0, 1] + [0] * (MAX_INPUT_VALUES + 1)),
    ]
    for values in malformed:
        include(values)
    for _ in range(512):
        size = rng.randrange(0, 65)
        include(tuple(rng.choice((-1, 0, 1, 2, 3, MAX_POLYGONS,
                                  MAX_POLYGONS + 1, COORDINATE_LIMIT + 1))
                      for _ in range(size)))

    for case in workload["cases"]:
        values = encode_case(case, algorithm=ALGORITHM)
        expected = oracle(values)
        if expected != case["expected_result"]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        include(values)

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for values, expected in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"array-scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(records_path)],
        cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, algorithm=ALGORITHM)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result or provenance mismatch: {case['id']}")
    return {
        "algorithm": ALGORITHM,
        "language": language,
        "status": "passed",
        "oracle_cases": case_count,
        "source_sha256": manifest["source_sha256"],
        "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
        "workload_records": len(records),
        "workload_sha256": sha256_file(ROOT / "benchmarks/a/area_of_polygon/workload.json"),
        "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(records_path),
        "recorder_output_sha256": sha256_file(records_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler", help="Custom Elisa compiler executable path")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_scalar/a/area_of_polygon")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages must be unique")

    workload = json.loads((ROOT / "benchmarks/a/area_of_polygon/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    results: list[dict] = []
    failures: list[dict] = []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        jobs = {pool.submit(verify, language, directory / language, args.elisa_compiler,
                            data, case_count, workload): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as exc:
                failures.append({"language": language, "error": str(exc)})
                print(f"FAIL {language}: {exc}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {language}: {case_count} oracle polygons, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures,
              "oracle_cases": case_count, "results": sorted(results, key=lambda item: item["language"]),
              "failures": failures}
    (directory / "verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {directory / 'verification.json'}")
    return 0 if not failures and len(results) == len(args.languages) else 1


if __name__ == "__main__":
    raise SystemExit(main())
