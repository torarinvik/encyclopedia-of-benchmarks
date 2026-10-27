"""Independent verifier using rank-and-retain open-bin maintenance."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 65


def evaluate(values: Sequence[int] | None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    count = values[0]
    if not 0 <= count <= 64 or len(values) != count + 1:
        return -1, b""
    sizes = list(values[1:])
    if any(size < 1 or size > 1_000_000 for size in sizes):
        return -1, b""
    loads: list[int] = []
    active: set[int] = set()
    result_ids: list[int] = []
    for item_size in sizes:
        feasible = [i for i in active if loads[i] + item_size <= 1_000_000]
        if feasible:
            # Best Fit; equal leftover resolves to the oldest global bin ID.
            target = min(feasible, key=lambda i: (1_000_000 - loads[i] - item_size, i))
            loads[target] += item_size
            if loads[target] == 1_000_000:
                active.remove(target)
        else:
            target = len(loads)
            loads.append(item_size)
            if item_size < 1_000_000:
                active.add(target)
        result_ids.append(target)
        # Keep the two fullest currently partial bins; equal loads keep the
        # smaller global ID. This deliberately differs from the primary
        # oracle's iterative weakest-bin deletion.
        keep = set(sorted(active, key=lambda i: (-loads[i], i))[:2])
        active = keep
    words = [len(loads), *result_ids]
    data = b"".join(word.to_bytes(8, "little", signed=True) for word in words)
    return len(data), data


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
    status, data = evaluate(values)
    if status < 0:
        return status, data
    if output_is_null or capacity is not None and capacity < len(data):
        return -2, b""
    return status, data
