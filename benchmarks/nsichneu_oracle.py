"""Independent oracle for the bounded Embench NSicherNeu transition profile."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import permutations
import struct

INPUT_COUNT = 9
OUTPUT_COUNT = 17
OUTPUT_BYTES = OUTPUT_COUNT * 8
MAX_RUNS = 64
MARK_LIMIT = 1000
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _snapshot(values: Sequence[int]) -> bytes:
    runs = values[0]
    p1 = list(values[1:4])
    p2 = list(values[4:9])
    p3 = [0] * 6
    p1_count, p2_count, p3_count = 3, 5, 0

    for _ in range(runs):
        p1_count, p2_count, p3_count = 3, 5, 0

        # Source order visits all six permutations lexicographically.
        for first, second, third in permutations(range(3)):
            if p1_count >= 3 and p3_count + 3 <= 6 and p1[second] == p1[third]:
                x, y = p1[first], p1[second]
                if x < y:
                    p1_count -= 3
                    p3[p3_count : p3_count + 3] = (x, y, x - y)
                    p3_count += 3

        # The generated source orders four-slot subsets lexicographically,
        # followed by each subset's 24 lexicographic permutations.
        for omitted in (4, 3, 2, 1, 0):
            subset = [index for index in range(5) if index != omitted]
            for order in permutations(subset):
                if (
                    p2_count >= 4
                    and p3_count + 3 <= 6
                    and p2[order[1]] == p2[order[2]]
                    and p2[order[1]] == p2[order[3]]
                ):
                    x, y = p2[order[0]], p2[order[1]]
                    if y > x:
                        p2_count -= 4
                        p3[p3_count : p3_count + 3] = (x, y, x + y)
                        p3_count += 3

    state = [p1_count, *p1, p2_count, *p2, p3_count, *p3]
    return b"".join(struct.pack("<q", value) for value in state)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the verifier-visible counts and marking arrays in little endian."""
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or (output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0))
        or (input_length is not None and (type(input_length) is not int or input_length < 0))
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if (
        len(values) != INPUT_COUNT
        or any(type(value) is not int for value in values)
        or not 1 <= values[0] <= MAX_RUNS
        or any(not -MARK_LIMIT <= value <= MARK_LIMIT for value in values[1:])
    ):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < OUTPUT_BYTES):
        return OUTPUT_ERROR, b""
    snapshot = _snapshot(values)
    return len(snapshot), snapshot
