"""Independent position-map verifier for the Comb hybrid list-update policy."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_REQUESTS = 32
MAX_INPUT_LENGTH = 82


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63) for value in values)):
        return None
    n, count = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= count <= MAX_REQUESTS or len(values) != 2 + 2 * n + 2 * count:
        return None
    order = list(values[2:2 + n])
    requests = tuple(values[2 + n:2 + n + count])
    bits = list(values[2 + n + count:2 + 2 * n + count])
    modes = tuple(values[2 + 2 * n + count:])
    if (sorted(order) != list(range(n)) or any(page < 0 or page >= n for page in requests)
            or any(bit not in (0, 1) for bit in bits) or any(mode < 0 or mode > 4 for mode in modes)):
        return None
    return order, requests, bits, modes


def _verify(order: list[int], requests: tuple[int, ...], bits: list[int], modes: tuple[int, ...]) -> list[int]:
    position_of = [0] * len(order)
    for position, page in enumerate(order):
        position_of[page] = position
    prior_occurrences: list[list[int]] = [[] for _ in order]
    positions: list[int] = []
    total = 0
    for time, page in enumerate(requests):
        position = position_of[page]
        positions.append(position + 1)
        total += position + 1
        if modes[time] < 4:
            bits[page] ^= 1
            if bits[page]:
                for shift in range(position, 0, -1):
                    displaced = order[shift - 1]
                    order[shift] = displaced
                    position_of[displaced] = shift
                order[0] = page
                position_of[page] = 0
        elif prior_occurrences[page]:
            previous_time = prior_occurrences[page][-1]
            for target in range(position):
                candidate = order[target]
                observed = sum(1 for occurrence in prior_occurrences[candidate]
                               if previous_time < occurrence < time)
                if observed <= 1:
                    for shift in range(position, target, -1):
                        displaced = order[shift - 1]
                        order[shift] = displaced
                        position_of[displaced] = shift
                    order[target] = page
                    position_of[page] = target
                    break
        prior_occurrences[page].append(time)
    return [total, *order, *positions, *bits]


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
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    order, requests, bits, modes = decoded
    words = _verify(order, requests, bits, modes)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
