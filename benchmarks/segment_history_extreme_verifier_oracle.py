"""Independent prefix-replay verifier for historical-maximum segment queries."""

from __future__ import annotations

from collections.abc import Sequence
import struct

from segment_history_extreme_oracle import (
    INVALID_RESULT,
    MAX_N,
    MAX_OUTPUT_BYTES,
    MAX_Q,
    MAX_VALUE,
    OUTPUT_ERROR_RESULT,
)


def _read_frame(values: Sequence[int] | None, input_is_null: bool,
                input_length: int | None):
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= 2 + MAX_N + 4 * MAX_Q:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 2 + n + 4 * q:
        return None
    initial = list(values[2:2 + n])
    if any(not -MAX_VALUE <= value <= MAX_VALUE for value in initial):
        return None
    records = []
    start = 2 + n
    for index in range(q):
        op, left, right, arg = values[start + 4 * index:start + 4 * index + 4]
        if op not in (0, 1, 2, 3) or not 0 <= left < right <= n:
            return None
        if (op < 2 and not -MAX_VALUE <= arg <= MAX_VALUE) or (op >= 2 and arg != 0):
            return None
        records.append((op, left, right, arg))
    return initial, records


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    frame = _read_frame(values, input_is_null, input_length)
    if frame is None:
        return INVALID_RESULT, b""
    initial, records = frame
    answers: list[int] = []
    for query_at, (op, left, right, _) in enumerate(records):
        if op < 2:
            continue
        current = initial.copy()
        history = initial.copy()
        for replay_op, replay_left, replay_right, replay_arg in records[:query_at]:
            if replay_op == 0:
                for position in range(replay_left, replay_right):
                    current[position] = replay_arg
                    history[position] = max(history[position], replay_arg)
            elif replay_op == 1:
                for position in range(replay_left, replay_right):
                    current[position] += replay_arg
                    history[position] = max(history[position], current[position])
        if op == 2:
            answers.append(max(current[left:right]))
        else:
            answers.append(max(history[left:right]))

    payload = struct.pack("<" + "q" * len(answers), *answers) if answers else b""
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null or effective_capacity < len(payload)):
        return OUTPUT_ERROR_RESULT, b""
    return len(payload), payload


def verify_output(values: Sequence[int] | None, result: int, output: bytes,
                  capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False,
                  input_length: int | None = None) -> bool:
    expected_result, expected = expected_output(
        values, capacity, output_is_null, input_is_null, input_length
    )
    return result == expected_result and output == expected
