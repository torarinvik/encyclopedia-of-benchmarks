"""Independent fixed-count-array oracle for mergeable/splittable multisets."""

from __future__ import annotations

import struct
from collections.abc import Sequence

try:
    from .primary_oracle import (
        DOMAIN,
        INVALID_RESULT,
        MAX_NODES,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_Q,
        MAX_ROOTS,
        MAX_TOTAL_COUNT,
        OUTPUT_ERROR,
    )
except ImportError:  # Direct import while the benchmarks directory is on sys.path.
    from s.segment_tree_merge_split.primary_oracle import (
        DOMAIN,
        INVALID_RESULT,
        MAX_NODES,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_Q,
        MAX_ROOTS,
        MAX_TOTAL_COUNT,
        OUTPUT_ERROR,
    )


def _read(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None):
    if (input_is_null or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    if input_length is not None and (type(input_length) is not int
                                     or input_length != len(values)
                                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if values[0] != DOMAIN or not 0 <= values[1] <= MAX_Q or len(values) != 2 + 4 * values[1]:
        return None
    root_total = 1
    records = []
    for i in range(values[1]):
        op, x, y, z = values[2 + 4 * i:6 + 4 * i]
        if op == 0 and 0 <= x < root_total and 1 <= y <= DOMAIN and 1 <= z <= 10:
            pass
        elif op == 1 and 0 <= x < root_total and 1 <= y <= z <= DOMAIN and root_total < MAX_ROOTS:
            root_total += 1
        elif op == 2 and 0 <= x < root_total and 0 <= y < root_total and x != y and z == 0:
            pass
        elif op == 3 and 0 <= x < root_total and 1 <= y <= z <= DOMAIN:
            pass
        elif op == 4 and 0 <= x < root_total and 1 <= y <= MAX_TOTAL_COUNT and z == 0:
            pass
        else:
            return None
        records.append((op, x, y, z))
    return records


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    records = _read(values, input_is_null, input_length)
    if records is None:
        return INVALID_RESULT, b""
    bags: list[list[int]] = [[0] * (DOMAIN + 1)]
    answers: list[int] = []
    for op, x, y, z in records:
        if op == 0:
            bags[x][y] += z
        elif op == 1:
            moved = [0] * (DOMAIN + 1)
            for value in range(y, z + 1):
                moved[value] = bags[x][value]
                bags[x][value] = 0
            bags.append(moved)
        elif op == 2:
            for value in range(1, DOMAIN + 1):
                bags[x][value] += bags[y][value]
                bags[y][value] = 0
        elif op == 3:
            answers.append(sum(bags[x][y:z + 1]))
        else:
            remaining = y
            answer = -1
            for value in range(1, DOMAIN + 1):
                remaining -= bags[x][value]
                if remaining <= 0:
                    answer = value
                    break
            answers.append(answer)
    packed = b"".join(struct.pack("<q", answer) for answer in answers)
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(actual_capacity) is not int or actual_capacity < 0
            or output_is_null or actual_capacity < len(packed)):
        return OUTPUT_ERROR, b""
    return len(packed), packed
