"""Recursive endpoint-pruning reference for monotone constant intervals."""

from __future__ import annotations

from typing import Iterable

MAX_N = 256
MAX_VALID_INPUT_LENGTH = 4
MAX_PARSEABLE_INPUT_LENGTH = 5
MAX_OUTPUT_BYTES = MAX_N * 12
MAX_WORKSPACE_BYTES = MAX_OUTPUT_BYTES


def _parameters(values: list[int] | tuple[int, ...] | None,
                input_is_null: bool = False,
                input_length: int | None = None) -> tuple[int, int, int, int] | None:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or (input_length is not None
                and (type(input_length) is not int
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
                     or input_length != len(values)))
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    n, step, offset, divisor = values
    if (not 0 <= n <= MAX_N or not 0 <= step <= 65535
            or not 0 <= offset <= 65535 or not 1 <= divisor <= 65535):
        return None
    return n, step, offset, divisor


def value_at(index: int, step: int, offset: int, divisor: int) -> int:
    return (step * index + offset) // divisor


def constant_intervals(n: int, step: int, offset: int, divisor: int) -> list[tuple[int, int, int]]:
    """Partition [0,n) by recursively pruning equal-endpoint ranges."""
    if n <= 0:
        return []
    result: list[tuple[int, int, int]] = []

    def append(lo: int, hi: int, value: int) -> None:
        if result and result[-1][1] == lo and result[-1][2] == value:
            old_lo, _, old_value = result[-1]
            result[-1] = (old_lo, hi, old_value)
        else:
            result.append((lo, hi, value))

    def visit(lo: int, hi: int, first: int, last: int) -> None:
        if first == last or hi - lo <= 1:
            append(lo, hi, first)
            return
        mid = lo + (hi - lo) // 2
        visit(lo, mid, first, value_at(mid - 1, step, offset, divisor))
        visit(mid, hi, value_at(mid, step, offset, divisor), last)

    visit(0, n, value_at(0, step, offset, divisor), value_at(n - 1, step, offset, divisor))
    return result


def encode(records: Iterable[tuple[int, int, int]]) -> bytes:
    return b"".join(
        int(field).to_bytes(4, "little", signed=True)
        for record in records
        for field in record
    )


def expected_call(values: list[int] | tuple[int, ...] | None,
                  capacity: int | None = None,
                  output_is_null: bool = False,
                  input_is_null: bool = False,
                  input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, b""
    parameters = _parameters(values, input_is_null, input_length)
    if parameters is None:
        return -1, b""
    n, step, offset, divisor = parameters
    required_capacity = n * 12
    if ((n > 0 and output_is_null)
            or (capacity is not None and capacity < required_capacity)):
        return -2, b""
    records = constant_intervals(n, step, offset, divisor)
    output = encode(records)
    return len(records), output
