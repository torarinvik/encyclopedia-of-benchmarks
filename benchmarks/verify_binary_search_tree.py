#!/usr/bin/env python3
"""Check binary-search-tree traces against an independent ordered-set oracle."""
from __future__ import annotations
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import itertools
import json
from pathlib import Path
import platform
import random
import subprocess
import sys
from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = 'binary_search_tree'
INVALID = -1
CAPACITY = 256
MAX_OPERATIONS = 512
MIN_KEY = -1_000_000
MAX_KEY = 1_000_000


def oracle(values: list[int]) -> int:
    if len(values) > 2 * MAX_OPERATIONS or len(values) % 2:
        return INVALID
    keys: set[int] = set()
    checksum = 0
    operation_count = len(values) // 2
    for operation in range(operation_count):
        opcode, payload = values[2 * operation:2 * operation + 2]
        if opcode in (0, 1, 2):
            if not MIN_KEY <= payload <= MAX_KEY:
                return INVALID
            if opcode == 0:
                was_present = payload in keys
                if not was_present:
                    if len(keys) == CAPACITY:
                        return INVALID
                    keys.add(payload)
                observed = int(not was_present)
            elif opcode == 1:
                observed = int(payload in keys)
                keys.discard(payload)
            else:
                observed = int(payload in keys)
        elif opcode in (3, 4, 5):
            if payload != 0:
                return INVALID
            if opcode == 3:
                if not keys:
                    return INVALID
                observed = min(keys)
            elif opcode == 4:
                if not keys:
                    return INVALID
                observed = max(keys)
            else:
                observed = len(keys)
        else:
            return INVALID
        checksum += (operation + 1) * (observed + 1_000_000)
    for index, value in enumerate(sorted(keys)):
        checksum += (operation_count + index + 1) * (value + 1_000_000)
    return checksum


def checker_corpus(cases: dict[tuple[int, ...], int]) -> str:
    lines = [f'{len(cases)}\n']
    for values in sorted(cases):
        expected = oracle(list(values))
        suffix = '' if not values else ' ' + ' '.join(map(str, values))
        lines.append(f'{len(values)} {expected}{suffix}\n')
    return ''.join(lines)


def verify(language: str, directory: Path, elisa_compiler: str | None, data: str,
           case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == 'elisa' else None,
                     with_checker=True, family='i64_array_scalar')
    checker = manifest['binaries']['i64_array_scalar_check']['path']
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f'array scalar C ABI check failed: {checked.stderr}')
    if json.loads(checked.stdout)['cases_checked'] != case_count:
        raise RuntimeError('checker did not consume complete oracle corpus')
    records_path = directory / 'verification-records.jsonl'
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / 'benchmarks/run_i64_array_scalar.py'),
         '--build-manifest', str(directory / 'build.json'), '--samples', '1',
         '--warmups', '0', '--repetitions', '1', '--output', str(records_path)],
        cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f'workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}')
    records = [json.loads(line) for line in records_path.read_text().splitlines()]
    if len(records) != len(workload['cases']):
        raise RuntimeError('unexpected workload record count')
    for case, record in zip(workload['cases'], records):
        values = encode_case(case)
        expected = oracle(values)
        if (expected != case['expected_result'] or record['algorithm'] != ALGORITHM
                or record['implementation']['language'] != language
                or record['implementation']['source_sha256'] != manifest['source_sha256']
                or record['workload']['input_length'] != len(values)
                or record['workload']['input_values'] != values
                or record['workload']['expected_result'] != expected
                or record['measurement']['observed_result'] != expected
                or len(record['measurement']['samples_ns']) != 1):
            raise RuntimeError(f'recorded result/provenance mismatch: {case["id"]}')
    return {'algorithm': ALGORITHM, 'language': language, 'status': 'passed',
            'oracle_cases': case_count, 'source_sha256': manifest['source_sha256'],
            'workload_records': len(records), 'build_manifest': str(directory / 'build.json'),
            'build_manifest_sha256': sha256_file(directory / 'build.json'),
            'recorder_output': str(records_path), 'recorder_output_sha256': sha256_file(records_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--languages', nargs='+', choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument('--elisa-compiler')
    parser.add_argument('--jobs', type=int, default=3)
    parser.add_argument('--build-dir', type=Path, default=ROOT / 'build/i64_array_scalar/b/binary_search_tree')
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error('jobs must be positive and language selections unique')
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / 'benchmarks/b/binary_search_tree/workload.json').read_text())
    cases: dict[tuple[int, ...], int] = {}
    tokens = ((0, -1), (0, 0), (0, 1), (1, -1), (1, 0), (1, 1),
              (2, -1), (2, 0), (2, 1), (3, 0), (4, 0), (5, 0))
    for size in range(4):
        for sequence in itertools.product(tokens, repeat=size):
            packed = tuple(value for pair in sequence for value in pair)
            cases[packed] = oracle(list(packed))
    rng = random.Random(20261014)
    for _ in range(768):
        operation_count = rng.randrange(MAX_OPERATIONS + 1)
        active: set[int] = set()
        packed: list[int] = []
        for _step in range(operation_count):
            choices = [1, 2, 5]
            if len(active) < CAPACITY:
                choices.append(0)
            if active:
                choices.extend((3, 4))
            opcode = rng.choice(choices)
            if opcode in (0, 1, 2):
                value = rng.randint(MIN_KEY, MAX_KEY)
                packed.extend((opcode, value))
                if opcode == 0 and value not in active and len(active) < CAPACITY:
                    active.add(value)
                elif opcode == 1:
                    active.discard(value)
            else:
                packed.extend((opcode, 0))
        key = tuple(packed)
        cases[key] = oracle(list(key))
    for _ in range(512):
        size = rng.randrange(65)
        packed = tuple(rng.choice((-1, 0, 1, 2, 3, 4, 5, 6, 7, 1_000_001)) for _ in range(size))
        cases[packed] = oracle(list(packed))
    cases[tuple(v for i in range(CAPACITY) for v in (0, i))] = oracle([v for i in range(CAPACITY) for v in (0, i)])
    too_many = [v for i in range(MAX_OPERATIONS + 1) for v in (0, i)]
    cases[tuple(too_many)] = oracle(too_many)
    for case in workload['cases']:
        packed = tuple(encode_case(case))
        expected = oracle(list(packed))
        if expected != case['expected_result']:
            parser.error(f'workload oracle mismatch: {case["id"]}')
        cases[packed] = expected
    data = checker_corpus(cases)
    results: list[dict] = []
    failures: list[dict] = []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        jobs = {pool.submit(verify, language, directory / language, args.elisa_compiler,
                            data, len(cases), workload): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as exc:
                failures.append({'language': language, 'error': str(exc)})
                print(f'FAIL {language}: {exc}', file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f'PASS {language}: {len(cases)} oracle traces, {result["workload_records"]} workload records', flush=True)
    report = {'algorithm': ALGORITHM, 'verified_at': dt.datetime.now(dt.timezone.utc).isoformat(),
              'platform': platform.platform(), 'all_passed': not failures,
              'oracle_cases': len(cases), 'results': sorted(results, key=lambda row: row['language']),
              'failures': failures}
    report_path = directory / 'verification.json'
    report_path.write_text(json.dumps(report, indent=2) + '\n')
    print(f'verification report: {report_path}')
    return 0 if not failures and len(results) == len(args.languages) else 1


if __name__ == '__main__':
    raise SystemExit(main())
