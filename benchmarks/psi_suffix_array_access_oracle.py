"""Primary oracle for sampled-Ψ suffix-array access (Chapter 82)."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 32
MAX_INPUT_LENGTH = 3 + 2 * MAX_N
MAX_OUTPUT_BYTES = 16
MAX_WORKSPACE_BYTES = 1024


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple))
            or not 5 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, query, stride = values[:3]
    if not 1 <= n <= MAX_N or not 0 <= query < n or not 1 <= stride <= n:
        return None
    if len(values) != 3 + 2 * n:
        return None
    psi = values[3:3 + n]
    samples = values[3 + n:]
    if any(type(rank) is not int or not 0 <= rank < n for rank in psi):
        return None
    if len(set(psi)) != n or any(type(value) is not int or not 0 <= value <= n for value in samples):
        return None
    return n, query, stride, psi, samples


def _validate_cycle(n: int, stride: int, psi: Sequence[int], samples: Sequence[int]):
    # A suffix-array Ψ maps each row to the row whose suffix starts one text
    # position later, with the last text position wrapping to the first.
    anchor = next((rank for rank, value in enumerate(samples) if value != 0), None)
    if anchor is None:
        return None
    anchor_value = samples[anchor]
    if (anchor_value - 1) % stride != 0:
        return None
    full_sa = [0] * n
    seen = [False] * n
    rank = anchor
    value = anchor_value
    for _ in range(n):
        if seen[rank]:
            return None
        seen[rank] = True
        full_sa[rank] = value
        rank = psi[rank]
        value = 1 if value == n else value + 1
    if rank != anchor or not all(seen) or value != anchor_value:
        return None
    if sorted(full_sa) != list(range(1, n + 1)):
        return None
    for rank, value in enumerate(full_sa):
        expected_sample = value if (value - 1) % stride == 0 else 0
        if samples[rank] != expected_sample:
            return None
    return full_sa


def evaluate(values: Sequence[int] | None) -> tuple[int, bytes]:
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, query, stride, psi, samples = parsed
    if _validate_cycle(n, stride, psi, samples) is None:
        return -1, b""

    rank = query
    hops = 0
    while samples[rank] == 0:
        rank = psi[rank]
        hops += 1
        if hops >= stride:
            return -1, b""  # unreachable for the profile's periodic sample phase
    # Ψ increases A by one with wraparound, so reverse the hops from the
    # sampled text position to obtain A[query].
    suffix_position = ((samples[rank] - 1 - hops) % n) + 1
    raw = struct.pack("<QQ", suffix_position, hops)
    return len(raw), raw


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    result, raw = evaluate(values)
    if result < 0:
        return result, raw
    if output_is_null or capacity is not None and capacity < len(raw):
        return -2, b""
    return result, raw
