"""Independent exhaustive-subset verifier for the doubling sequence profile."""

from __future__ import annotations

from collections.abc import Sequence


def _encode(words: list[int]) -> bytes:
    payload = bytearray()
    for word in words:
        payload.extend(word.to_bytes(8, "little", signed=True))
    return bytes(payload)


def _best_subset(processing: list[int], weights: list[int], bound: int) -> int:
    n = len(processing)
    best_processing = -1
    best_mask = 0
    for mask in range(1 << n):
        total_weight = 0
        total_processing = 0
        for job in range(n):
            if mask >> job & 1:
                total_weight += weights[job]
                total_processing += processing[job]
        if total_weight <= bound and (total_processing > best_processing or
                total_processing == best_processing and mask < best_mask):
            best_processing = total_processing
            best_mask = mask
    return best_mask


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or values is None or not isinstance(values, (list, tuple))
            or len(values) < 3 or len(values) > 25
            or input_length is not None and
                (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n = values[0]
    if not 1 <= n <= 12 or len(values) != 1 + 2 * n:
        return -1, b""
    processing = [values[1 + 2 * job] for job in range(n)]
    weights = [values[2 + 2 * job] for job in range(n)]
    if any(p < 1 or p > 255 for p in processing) or any(w < 1 or w > 32 for w in weights):
        return -1, b""
    total_weight = sum(weights)
    if total_weight > 32 or total_weight & (total_weight - 1):
        return -1, b""

    masks: list[int] = []
    bound = 1
    while bound <= total_weight:
        masks.append(_best_subset(processing, weights, bound))
        bound <<= 1
    ranks = [-1] * n
    for job in range(n):
        for level, mask in enumerate(masks):
            if mask >> job & 1:
                ranks[job] = level
                break
        if ranks[job] == -1:
            return -1, b""
    permutation = [job for level in range(len(masks) - 1, -1, -1)
                   for job in range(n) if ranks[job] == level]
    payload = _encode([n, *permutation])
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
