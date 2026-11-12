"""Clean-room Hirschberg LCS reconstruction oracle."""

from __future__ import annotations

from collections.abc import Sequence

MAX_SEQUENCE_LENGTH = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_SEQUENCE_LENGTH
MAX_PARSEABLE_LENGTH = MAX_INPUT_LENGTH + 2
MAX_OUTPUT_BYTES = MAX_SEQUENCE_LENGTH
WORKSPACE_BYTES = 2048


def _row(
    a: Sequence[int], a0: int, a1: int,
    b: Sequence[int], b0: int, b1: int,
    reverse_a: bool, reverse_b: bool, row: list[int],
) -> None:
    width = b1 - b0
    for j in range(width + 1):
        row[j] = 0
    for i in range(a1 - a0):
        ai = a[a1 - 1 - i] if reverse_a else a[a0 + i]
        diagonal = 0
        for j in range(1, width + 1):
            above = row[j]
            bj = b[b1 - j] if reverse_b else b[b0 + j - 1]
            if ai == bj:
                row[j] = diagonal + 1
            elif row[j - 1] > row[j]:
                row[j] = row[j - 1]
            diagonal = above


def _recover(a: Sequence[int], a0: int, a1: int,
             b: Sequence[int], b0: int, b1: int,
             forward: list[int], backward: list[int], result: list[int]) -> None:
    a_length = a1 - a0
    b_length = b1 - b0
    if a_length == 0 or b_length == 0:
        return
    if a_length == 1:
        target = a[a0]
        for j in range(b0, b1):
            if b[j] == target:
                result.append(target)
                return
        return

    middle = a0 + a_length // 2
    _row(a, a0, middle, b, b0, b1, False, False, forward)
    _row(a, middle, a1, b, b0, b1, True, True, backward)
    best_score = -1
    split = 0
    for j in range(b_length + 1):
        score = forward[j] + backward[b_length - j]
        if score > best_score:
            best_score = score
            split = j
    _recover(a, a0, middle, b, b0, b0 + split, forward, backward, result)
    _recover(a, middle, a1, b, b0 + split, b1, forward, backward, result)


def _hirschberg(first: Sequence[int], second: Sequence[int]) -> bytes:
    # The longer sequence is the recursion axis; ties preserve input order.
    if len(first) < len(second):
        a, b = second, first
    else:
        a, b = first, second
    result: list[int] = []
    _recover(a, 0, len(a), b, 0, len(b), [0] * (len(b) + 1),
             [0] * (len(b) + 1), result)
    return bytes(result)


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
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if not 2 <= len(values) <= MAX_PARSEABLE_LENGTH:
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""
    first_length, second_length = values[:2]
    if not 0 <= first_length <= MAX_SEQUENCE_LENGTH or not 0 <= second_length <= MAX_SEQUENCE_LENGTH:
        return -1, b""
    if len(values) != 2 + first_length + second_length:
        return -1, b""
    first = values[2:2 + first_length]
    second = values[2 + first_length:]
    if any(not 0 <= symbol <= 127 for symbol in (*first, *second)):
        return -1, b""
    payload = _hirschberg(first, second)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
