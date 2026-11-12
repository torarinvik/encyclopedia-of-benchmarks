"""Independent threshold-table oracle for finite discrete rejection sampling."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction
from bisect import bisect_right

MAX_CATEGORIES = 8
MAX_SAMPLES = 8
MAX_ATTEMPTS = 32
MAX_WEIGHT = 20
DRAW_SCALE = 1 << 32
MAX_PARSEABLE_LENGTH = 3 + 2 * MAX_CATEGORIES + 2 * MAX_ATTEMPTS
MAX_OUTPUT_BYTES = 16 * MAX_SAMPLES


def _parse(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_PARSEABLE_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, wanted, attempts = values[:3]
    if not 1 <= n <= MAX_CATEGORIES or not 1 <= wanted <= MAX_SAMPLES or not 1 <= attempts <= MAX_ATTEMPTS:
        return None
    if len(values) != 3 + 2 * n + 2 * attempts:
        return None
    target = values[3:3 + n]
    proposal = values[3 + n:3 + 2 * n]
    if any(not 1 <= weight <= MAX_WEIGHT for weight in (*target, *proposal)):
        return None
    proposal_total = sum(proposal)
    records = []
    start = 3 + 2 * n
    for pos in range(start, start + 2 * attempts, 2):
        candidate, accept = values[pos:pos + 2]
        if not 0 <= candidate < proposal_total or not 0 <= accept < DRAW_SCALE:
            return None
        records.append((candidate, accept))
    return wanted, target, proposal, records


def _ceil_fraction(value: Fraction) -> int:
    return (value.numerator + value.denominator - 1) // value.denominator


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or capacity is not None and (type(capacity) is not int or capacity < 0)
        or input_length is not None
        and (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_LENGTH)
        or input_is_null and values not in (None, [], ())
        or not input_is_null and values is not None and input_length is not None
        and input_length != len(values)
    ):
        return -1, b""
    if input_is_null:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    wanted, target, proposal, records = parsed
    output_bytes = 16 * wanted
    if output_is_null or capacity is not None and capacity < output_bytes:
        return -2, b""

    target_total, proposal_total = sum(target), sum(proposal)
    envelope = max(
        _ceil_fraction(Fraction(target[i] * proposal_total, target_total * proposal[i]))
        for i in range(len(target))
    )
    cumulative = []
    running = 0
    for weight in proposal:
        running += weight
        cumulative.append(running)
    thresholds = [
        _ceil_fraction(Fraction(DRAW_SCALE * target[i] * proposal_total,
                                target_total * proposal[i] * envelope))
        for i in range(len(target))
    ]

    answer: list[int] = []
    pending_attempts = 0
    for proposal_draw, accept_draw in records:
        pending_attempts += 1
        category = bisect_right(cumulative, proposal_draw)
        if accept_draw < thresholds[category]:
            answer.extend((category, pending_attempts))
            pending_attempts = 0
            if len(answer) == 2 * wanted:
                return output_bytes, struct.pack("<" + "q" * len(answer), *answer)
    return -3, b""
