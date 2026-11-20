"""Independent sequential running-sum reference for exclusive prefixes."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 64
VALUE_LIMIT = 1_000_000
PARSE_LIMIT = MAX_N + 2
OUTPUT_LIMIT = MAX_N * 8
WORKSPACE_LIMIT = 2048


def _read_frame(frame: Sequence[int] | None, supplied_length: int | None,
                is_null: bool) -> list[int] | None:
    if is_null or frame is None or not isinstance(frame, (list, tuple)):
        return None
    if supplied_length is not None and (
        type(supplied_length) is not int or supplied_length != len(frame)
        or supplied_length < 0 or supplied_length > PARSE_LIMIT
    ):
        return None
    if not 2 <= len(frame) <= PARSE_LIMIT:
        return None
    for value in frame:
        if type(value) is not int or not -(1 << 63) <= value < (1 << 63):
            return None
    n = frame[0]
    if n < 1 or n > MAX_N or len(frame) != n + 1:
        return None
    values = list(frame[1:])
    if any(value < -VALUE_LIMIT or value > VALUE_LIMIT for value in values):
        return None
    return values


def _encode(values: list[int]) -> bytes:
    prefix: list[int] = []
    running = 0
    for value in values:
        prefix.append(running)
        running += value
    return b"".join(item.to_bytes(8, "little", signed=True) for item in prefix)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    data = _read_frame(values, input_length, input_is_null)
    if data is None:
        return -1, b""
    result = _encode(data)
    if output_is_null or capacity is not None and capacity < len(result):
        return -2, b""
    return len(result), result
