"""Deterministic finite-discrete rejection-sampling reference."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_CATEGORIES = 8
MAX_SAMPLES = 8
MAX_ATTEMPTS = 32
MAX_WEIGHT = 20
DRAW_SCALE = 1 << 32
MAX_INPUT_LENGTH = 3 + 2 * MAX_CATEGORIES + 2 * MAX_ATTEMPTS
MAX_PARSEABLE_LENGTH = MAX_INPUT_LENGTH
MAX_OUTPUT_BYTES = 16 * MAX_SAMPLES
WORKSPACE_BYTES = 4096


def _parse(values: Sequence[int] | None) -> tuple[int, int, tuple[int, ...], tuple[int, ...], tuple[tuple[int, int], ...]] | None:
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_PARSEABLE_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    categories, samples, attempt_cap = values[:3]
    if not 1 <= categories <= MAX_CATEGORIES or not 1 <= samples <= MAX_SAMPLES:
        return None
    if not 1 <= attempt_cap <= MAX_ATTEMPTS:
        return None
    expected_length = 3 + 2 * categories + 2 * attempt_cap
    if len(values) != expected_length:
        return None
    target = tuple(values[3:3 + categories])
    proposal = tuple(values[3 + categories:3 + 2 * categories])
    if any(not 1 <= weight <= MAX_WEIGHT for weight in target + proposal):
        return None
    total_proposal = sum(proposal)
    records: list[tuple[int, int]] = []
    offset = 3 + 2 * categories
    for attempt in range(attempt_cap):
        proposal_draw, acceptance_draw = values[offset + 2 * attempt:offset + 2 * attempt + 2]
        if not 0 <= proposal_draw < total_proposal or not 0 <= acceptance_draw < DRAW_SCALE:
            return None
        records.append((proposal_draw, acceptance_draw))
    return categories, samples, target, proposal, tuple(records)


def _envelope(target: Sequence[int], proposal: Sequence[int]) -> int:
    target_total = sum(target)
    proposal_total = sum(proposal)
    return max(
        (weight * proposal_total + target_total * q_weight - 1)
        // (target_total * q_weight)
        for weight, q_weight in zip(target, proposal)
    )


def _run(
    categories: int,
    samples: int,
    target: Sequence[int],
    proposal: Sequence[int],
    records: Sequence[tuple[int, int]],
) -> tuple[int, ...] | None:
    target_total = sum(target)
    proposal_total = sum(proposal)
    envelope = _envelope(target, proposal)
    output: list[int] = []
    attempts_for_sample = 0
    for proposal_draw, acceptance_draw in records:
        attempts_for_sample += 1
        cumulative = 0
        category = 0
        for category, weight in enumerate(proposal):
            cumulative += weight
            if proposal_draw < cumulative:
                break
        numerator = target[category] * proposal_total
        denominator = target_total * proposal[category] * envelope
        if acceptance_draw * denominator < DRAW_SCALE * numerator:
            output.extend((category, attempts_for_sample))
            attempts_for_sample = 0
            if len(output) == 2 * samples:
                return tuple(output)
    return None


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
    categories, samples, target, proposal, records = parsed
    del categories
    output_bytes = 16 * samples
    if output_is_null or capacity is not None and capacity < output_bytes:
        return -2, b""
    result = _run(samples=samples, categories=len(target), target=target, proposal=proposal, records=records)
    if result is None:
        return -3, b""
    return output_bytes, struct.pack("<" + "q" * len(result), *result)
