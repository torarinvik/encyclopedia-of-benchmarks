"""Integer-arithmetic reference for the bounded BKP speed-selection trace."""
from __future__ import annotations

from collections.abc import Sequence
from math import gcd

MAX_JOBS = 4
MAX_SAMPLES = 8
MAX_TIME = 8
MAX_WORK = 8
E_NUM = 271_828
E_DEN = 100_000
EM1_NUM = E_NUM - E_DEN
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_JOBS + 2 * MAX_SAMPLES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    n, sample_count = values[:2]
    if not 1 <= n <= MAX_JOBS or not 1 <= sample_count <= MAX_SAMPLES:
        return None
    if len(values) != 2 + 3 * n + 2 * sample_count:
        return None
    cursor = 2
    jobs = []
    for _ in range(n):
        release, deadline, work = values[cursor:cursor + 3]
        if not 0 <= release < deadline <= MAX_TIME or not 1 <= work <= MAX_WORK:
            return None
        jobs.append((release, deadline, work))
        cursor += 3
    samples = []
    for _ in range(sample_count):
        time, mask = values[cursor:cursor + 2]
        if not 0 <= time <= MAX_TIME or not 0 <= mask < (1 << n):
            return None
        if any(mask & (1 << j) and jobs[j][0] > time for j in range(n)):
            return None
        samples.append((time, mask))
        cursor += 2
    return jobs, samples


def _speed_at(jobs: list[tuple[int, int, int]], time: int, active: int) -> tuple[int, int]:
    if active == 0:
        return 0, 1
    best_num, best_den = 0, 1
    # Candidate endpoint is stored as num/den. Deadlines have denominator 1;
    # a release crossing has denominator e-1 after clearing the fixed scale.
    for release, deadline, _ in jobs:
        if release > time:
            continue
        candidates = []
        if deadline > time:
            candidates.append((deadline, 1))
        if release < time:
            candidates.append((E_NUM * time - E_DEN * release, EM1_NUM))
        for endpoint_num, endpoint_den in candidates:
            delta_num = endpoint_num - time * endpoint_den
            if delta_num <= 0:
                continue
            t1_scaled = E_NUM * time * endpoint_den - EM1_NUM * endpoint_num
            work_sum = 0
            for r2, d2, w2 in jobs:
                if (r2 <= time
                        and t1_scaled <= E_DEN * endpoint_den * r2
                        and d2 * endpoint_den <= endpoint_num):
                    work_sum += w2
            candidate_num = work_sum * endpoint_den
            candidate_den = delta_num
            if candidate_num * best_den > best_num * candidate_den:
                best_num, best_den = candidate_num, candidate_den
    divisor = gcd(best_num, best_den)
    return best_num // divisor, best_den // divisor


def expected_values(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> list[int] | int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    jobs, samples = parsed
    result = [len(samples)]
    for time, mask in samples:
        speed_num, speed_den = _speed_at(jobs, time, mask)
        result.extend((speed_num, speed_den))
    return result
