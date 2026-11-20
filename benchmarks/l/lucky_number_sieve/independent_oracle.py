"""Independent alive-bitmap verifier for lucky-number sieve outputs."""
from __future__ import annotations

from collections.abc import Sequence

MAX_BOUND = 4096
MAX_CANDIDATES = 2048
MAX_OUTPUT_BYTES = MAX_CANDIDATES * 8
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3


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
    return (mode, bound) if mode in (0, 1) and 0 <= bound <= MAX_BOUND else None


def _bitmap_survivors(mode: int, bound: int) -> list[int]:
    start = 1 if mode == 0 else 2
    count = max(0, (bound - start) // 2 + 1)
    alive = bytearray(b"\x01") * count
    rank_count = count
    selected_rank = 2
    while selected_rank <= rank_count:
        seen = 0
        step = 0
        for index, is_alive in enumerate(alive):
            if is_alive:
                seen += 1
                if seen == selected_rank:
                    step = start + 2 * index
                    break
        if seen < selected_rank or step > rank_count:
            break
        rank = 0
        for index, is_alive in enumerate(alive):
            if is_alive:
                rank += 1
                if rank % step == 0:
                    alive[index] = 0
                    rank_count -= 1
        selected_rank += 1
    return [start + 2 * index for index, is_alive in enumerate(alive) if is_alive]


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    expected = b"".join(value.to_bytes(8, "little", signed=True)
                        for value in _bitmap_survivors(*parsed))
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int or capacity < 0
            or output_is_null or capacity < len(expected)):
        return -2, b""
    return len(expected), expected


def verify_result(values: Sequence[int] | None, result: int, output: bytes,
                  output_capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False, input_length: int | None = None) -> bool:
    expected_result, expected = expected_output(
        values, output_capacity=output_capacity, output_is_null=output_is_null,
        input_is_null=input_is_null, input_length=input_length)
    if not isinstance(output, (bytes, bytearray)):
        return False
    return result == expected_result and bytes(output) == expected
