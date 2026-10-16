"""Independent oracle for the bounded combination-sum output contract."""

from __future__ import annotations

import struct

MAX_CANDIDATES = 8
MAX_TARGET = 20
MAX_CANDIDATE = 24
MAX_PACKED_INPUT_LENGTH = MAX_CANDIDATES + 2
MAX_OUTPUT_WORDS = 4096
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: tuple[int, ...] | list[int],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or not 3 <= len(values) <= MAX_PACKED_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    candidate_count, target = values[:2]
    candidates = values[2:]
    if (not 1 <= candidate_count <= MAX_CANDIDATES or not 0 <= target <= MAX_TARGET
            or len(candidates) != candidate_count
            or any(not 1 <= value <= MAX_CANDIDATE for value in candidates)
            or any(left >= right for left, right in zip(candidates, candidates[1:]))):
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""

    combinations: list[tuple[int, ...]] = []

    def choose(index: int, remaining: int, path: list[int]) -> None:
        if remaining == 0:
            combinations.append(tuple(path))
            return
        if index == candidate_count:
            return
        candidate = candidates[index]
        for copies in range(remaining // candidate, -1, -1):
            path.extend([candidate] * copies)
            choose(index + 1, remaining - copies * candidate, path)
            if copies:
                del path[-copies:]

    choose(0, target, [])
    packed = [len(combinations)]
    for combination in combinations:
        packed.append(len(combination))
        packed.extend(combination)
    if len(packed) > MAX_OUTPUT_WORDS:
        return -1, b""
    encoded = b"".join(struct.pack("<q", value) for value in packed)
    if output_capacity is not None and output_capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
