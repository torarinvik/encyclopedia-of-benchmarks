"""Primary list-filter oracle for the bounded lucky-number sieve profile."""
from __future__ import annotations

from collections.abc import Sequence

MAX_BOUND = 4096
MAX_CANDIDATES = 2048
MAX_OUTPUT_BYTES = MAX_CANDIDATES * 8
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or len(values) != 2
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    mode, bound = values
    if mode not in (0, 1) or not 0 <= bound <= MAX_BOUND:
        return None
    return mode, bound


def _survivors(mode: int, bound: int) -> list[int]:
    first = 1 if mode == 0 else 2
    survivors = list(range(first, bound + 1, 2))
    selected = 1
    while selected < len(survivors):
        step = survivors[selected]
        if step > len(survivors):
            break
        survivors = [value for rank, value in enumerate(survivors, 1)
                     if rank % step != 0]
        selected += 1
    return survivors


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    payload = b"".join(value.to_bytes(8, "little", signed=True)
                       for value in _survivors(*parsed))
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null
            or effective_capacity < len(payload)):
        return OUTPUT_ERROR_RESULT, b""
    return len(payload), payload
