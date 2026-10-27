"""Primary clean-room oracle for the bounded DOI 49 Sum-of-Squares rule."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 66
MAX_OUTPUT_BYTES = 520


def _parse(values: Sequence[int] | None) -> tuple[int, list[int]] | None:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    capacity, count = values[0], values[1]
    if not 1 <= capacity <= 64 or not 0 <= count <= 64 or len(values) != count + 2:
        return None
    sizes = list(values[2:])
    if any(not 1 <= size <= capacity for size in sizes):
        return None
    return capacity, sizes


def _score(loads: Sequence[int], capacity: int) -> int:
    counts = [0] * (capacity + 1)
    for load in loads:
        if load < capacity:
            counts[load] += 1
    return sum(counts[load] * counts[load] for load in range(1, capacity))


def evaluate(values: Sequence[int] | None) -> tuple[int, bytes]:
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    capacity, sizes = parsed
    loads: list[int] = []
    assignments: list[int] = []
    for size in sizes:
        options: list[tuple[int, int]] = []
        for bin_id, load in enumerate(loads):
            if load + size <= capacity:
                candidate = loads.copy()
                candidate[bin_id] += size
                options.append((_score(candidate, capacity), bin_id))
        new_candidate = loads + [size]
        options.append((_score(new_candidate, capacity), len(loads)))
        # The tie refinement minimizes score first and then preserves the
        # lowest existing bin ID; a new bin follows every existing bin.
        _, selected = min(options, key=lambda pair: (pair[0], pair[1]))
        if selected == len(loads):
            loads.append(size)
        else:
            loads[selected] += size
        assignments.append(selected)
    words = [len(loads), *assignments]
    raw = b"".join(word.to_bytes(8, "little", signed=True) for word in words)
    return len(raw), raw


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    result, raw = evaluate(values)
    if result < 0:
        return result, raw
    if output_is_null or capacity is not None and capacity < len(raw):
        return -2, b""
    return result, raw
