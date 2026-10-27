"""Independent sorted-order feasible-bin verifier for Best Fit Decreasing."""

from __future__ import annotations

from collections.abc import Sequence

CAPACITY = 1_000_000
MAX_INPUT_LENGTH = 65
MAX_OUTPUT_BYTES = 520


def _sizes(values: Sequence[int] | None) -> list[int] | None:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return None
    n = values[0]
    if not 0 <= n <= 64 or len(values) != n + 1:
        return None
    result = list(values[1:])
    return result if all(1 <= size <= CAPACITY for size in result) else None


def verify(values: Sequence[int] | None) -> tuple[int, bytes]:
    sizes = _sizes(values)
    if sizes is None:
        return -1, b""
    ordered = sorted(enumerate(sizes), key=lambda pair: (-pair[1], pair[0]))
    loads: list[int] = []
    assignment = [-1] * len(sizes)
    for original_index, size in ordered:
        candidates = [(CAPACITY - load - size, bin_id)
                      for bin_id, load in enumerate(loads) if load + size <= CAPACITY]
        if not candidates:
            selected = len(loads)
            loads.append(size)
        else:
            _, selected = min(candidates, key=lambda candidate: (candidate[0], candidate[1]))
            loads[selected] += size
        assignment[original_index] = selected
    words = [len(loads), *assignment]
    raw = b"".join(int(word).to_bytes(8, "little", signed=True) for word in words)
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
    result, raw = verify(values)
    if result < 0:
        return result, raw
    if output_is_null or capacity is not None and capacity < len(raw):
        return -2, b""
    return result, raw
