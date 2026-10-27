"""Primary Best Fit Decreasing oracle for DOI 49."""

from __future__ import annotations

from collections.abc import Sequence

CAPACITY = 1_000_000
MAX_INPUT_LENGTH = 65
MAX_OUTPUT_BYTES = 520


def _parse(values: Sequence[int] | None) -> list[int] | None:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return None
    n = values[0]
    if not 0 <= n <= 64 or len(values) != n + 1:
        return None
    sizes = list(values[1:])
    return sizes if all(1 <= size <= CAPACITY for size in sizes) else None


def evaluate(values: Sequence[int] | None) -> tuple[int, bytes]:
    sizes = _parse(values)
    if sizes is None:
        return -1, b""
    order = sorted(range(len(sizes)), key=lambda index: (-sizes[index], index))
    loads: list[int] = []
    assignments = [0] * len(sizes)
    for item in order:
        size = sizes[item]
        candidates = [(CAPACITY - load - size, bin_id)
                     for bin_id, load in enumerate(loads) if load + size <= CAPACITY]
        if candidates:
            _, selected = min(candidates)
            loads[selected] += size
        else:
            selected = len(loads)
            loads.append(size)
        assignments[item] = selected
    words = [len(loads), *assignments]
    raw = b"".join(word.to_bytes(8, "little", signed=True) for word in words)
    return len(raw), raw


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    result, raw = evaluate(values)
    if result < 0:
        return result, raw
    if output_is_null or capacity is not None and capacity < len(raw):
        return -2, b""
    return result, raw
