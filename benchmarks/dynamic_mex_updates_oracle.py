"""Frequency-segment-tree oracle for batched dynamic MEX updates."""

from __future__ import annotations

import struct

MAX_N = 32
MAX_Q = 32
MIN_VALUE = -1000
MAX_VALUE = 1000
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + 2 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_Q


def _parse(values, input_length=None, input_is_null=False):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 2
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return None
    if input_length != 2 + n + 2 * q:
        return None
    initial = list(values[2:2 + n])
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in initial):
        return None
    operations = []
    cursor = 2 + n
    for _ in range(q):
        index, value = values[cursor], values[cursor + 1]
        cursor += 2
        if not 0 <= index < n or not MIN_VALUE <= value <= MAX_VALUE:
            return None
        operations.append((index, value))
    return n, initial, operations


class _PresenceTree:
    def __init__(self, domain_size: int) -> None:
        self.domain_size = domain_size
        self.base = 1
        while self.base < domain_size:
            self.base <<= 1
        self.counts = [0] * (2 * self.base)

    def set_present(self, value: int, present: bool) -> None:
        node = self.base + value
        self.counts[node] = int(present)
        node >>= 1
        while node:
            self.counts[node] = self.counts[2 * node] + self.counts[2 * node + 1]
            node >>= 1

    def mex(self) -> int:
        node = 1
        start = 0
        span = self.base
        while span > 1:
            half = span // 2
            left_width = max(0, min(half, self.domain_size - start))
            if self.counts[2 * node] < left_width:
                node *= 2
                span = half
            else:
                node = 2 * node + 1
                start += half
                span = half
        return start


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return status and little-endian MEX values after each point update."""
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    n, current, operations = parsed
    required = 8 * len(operations)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if required > 0 and (output_is_null or effective_capacity < required):
        return -2, b""

    tree = _PresenceTree(n + 1)
    frequencies = [0] * (n + 1)
    for value in current:
        if 0 <= value <= n:
            frequencies[value] += 1
    for value, frequency in enumerate(frequencies):
        if frequency:
            tree.set_present(value, True)

    answers = []
    for index, new_value in operations:
        old_value = current[index]
        if old_value != new_value:
            if 0 <= old_value <= n:
                frequencies[old_value] -= 1
                if frequencies[old_value] == 0:
                    tree.set_present(old_value, False)
            if 0 <= new_value <= n:
                if frequencies[new_value] == 0:
                    tree.set_present(new_value, True)
                frequencies[new_value] += 1
            current[index] = new_value
        answers.append(tree.mex())
    output = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(output), output


def expected_result(values, **kwargs):
    return expected_output(values, **kwargs)[0]
