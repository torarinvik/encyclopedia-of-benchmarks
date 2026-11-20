"""Direct two-candidate common-release schedule reference for OA."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_JOBS = 2
MAX_TIME = 4
MAX_WORK = 4
MAX_VALID_INPUT_LENGTH = 1 + 3 * MAX_JOBS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_SEGMENTS = 3
MAX_OUTPUT_VALUES = 3 + 4 * MAX_SEGMENTS + 2 * MAX_JOBS
MAX_OUTPUT = 8 * MAX_OUTPUT_VALUES


def _read(values: Sequence[int] | None) -> list[tuple[int, int, int]] | None:
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    count = values[0]
    if count < 1 or count > MAX_JOBS or len(values) != 1 + 3 * count:
        return None
    records = []
    for j in range(count):
        release, deadline, work = values[1 + 3 * j:4 + 3 * j]
        if not (0 <= release < deadline <= MAX_TIME and 1 <= work <= MAX_WORK):
            return None
        records.append((release, deadline, work))
    return records


def _fixed_release_candidates(now: int, remaining: list[Fraction],
                              jobs: list[tuple[int, int, int]]):
    ids = [j for j, value in enumerate(remaining)
           if value > 0 and jobs[j][1] > now]
    ids.sort(key=lambda j: (jobs[j][1], j))
    if not ids:
        return []
    if len(ids) == 1:
        j = ids[0]
        return [(now, jobs[j][1], remaining[j] / (jobs[j][1] - now), (j,))]
    first, second = ids
    d_first, d_second = jobs[first][1], jobs[second][1]
    if d_first == d_second:
        total_rate = (remaining[first] + remaining[second]) / (d_first - now)
        return [(now, d_first, total_rate, (first, second))]

    common_rate = (remaining[first] + remaining[second]) / (d_second - now)
    early_work_capacity = common_rate * (d_first - now)
    if early_work_capacity >= remaining[first]:
        # Candidate A: one constant-speed block over the full available window.
        return [(now, d_second, common_rate, (first, second))]

    # Candidate B: the tight early-deadline job gets its own block; the other
    # job uses the remaining window. This is the only other feasible YDS form
    # for at most two common-release jobs.
    early_rate = remaining[first] / (d_first - now)
    late_rate = remaining[second] / (d_second - d_first)
    return [(now, d_first, early_rate, (first,)),
            (d_first, d_second, late_rate, (second,))]


def _encode(records: list[tuple[int, int, int]]) -> list[int]:
    left = [Fraction(0) for _ in records]
    done: list[Fraction | None] = [None] * len(records)
    schedule: list[list[int]] = []
    total_energy = Fraction(0)
    arrivals = sorted({record[0] for record in records})

    for event, time in enumerate(arrivals):
        for j, (release, _, work) in enumerate(records):
            if release == time:
                left[j] = Fraction(work)
        cutoff = arrivals[event + 1] if event + 1 < len(arrivals) else None
        for begin, finish, speed, order in _fixed_release_candidates(time, left, records):
            stop = finish if cutoff is None else min(finish, cutoff)
            if stop <= begin:
                break
            if schedule and schedule[-1][1] == begin and Fraction(
                    schedule[-1][2], schedule[-1][3]) == speed:
                schedule[-1][1] = stop
            else:
                schedule.append([begin, stop, speed.numerator, speed.denominator])
            total_energy += (stop - begin) * speed * speed * speed

            clock = Fraction(begin)
            for j in order:
                if left[j] <= 0:
                    continue
                job_time = left[j] / speed
                job_finish = clock + job_time
                if job_finish <= stop:
                    clock = job_finish
                    done[j] = clock
                    left[j] = Fraction(0)
                else:
                    left[j] -= speed * (Fraction(stop) - clock)
                    clock = Fraction(stop)
                    break
            if stop != finish:
                break

    if any(value is None for value in done):
        raise ValueError("two-candidate OA reference left valid work unfinished")
    out = [len(schedule), total_energy.numerator, total_energy.denominator]
    for item in schedule:
        out.extend(item)
    for value in done:
        assert value is not None
        out.extend((value.numerator, value.denominator))
    return out


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (
                type(input_length) is not int
                or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    jobs = _read(values)
    if jobs is None:
        return -1, b""
    payload = b"".join(struct.pack("<q", value) for value in _encode(jobs))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
