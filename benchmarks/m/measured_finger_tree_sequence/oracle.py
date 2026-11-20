"""Plain persistent-list oracle for the measured finger-tree operation profile."""
from __future__ import annotations

import struct

MAX_INITIAL = 32
MAX_Q = 32
MAX_LEN = 64
MAX_VALUE = 1_000_000
MAX_SUM = 64_000_000
MAX_VALID_INPUT = 194
MAX_PARSEABLE_INPUT = 195
MAX_OUTPUT_BYTES = 1792
MAX_WORKSPACE_BYTES = 1_048_576
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _decode(values, input_length=None, input_is_null=False):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))):
        return None
    n = values[0]
    if type(n) is not int or not 0 <= n <= MAX_INITIAL or len(values) < n + 2:
        return None
    initial = values[1:1+n]
    if any(not 0 <= x <= MAX_VALUE for x in initial):
        return None
    q = values[1+n]
    if type(q) is not int or not 1 <= q <= MAX_Q or len(values) != 2+n+5*q:
        return None
    return list(initial), [values[2+n+5*i:7+n+5*i] for i in range(q)]


def _simulate(values, input_length=None, input_is_null=False):
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return None
    initial, operations = decoded
    roots = [initial]
    words = []
    for tag, a, b, x, y in operations:
        if tag not in range(7) or a < 0 or a >= len(roots):
            return None
        left = roots[a]
        right_root = -1
        aux = -1
        if tag in (0, 1):
            if b != -1 or y != -1 or not 0 <= x <= MAX_VALUE or len(left) >= MAX_LEN:
                return None
            result = ([x] + left) if tag == 0 else (left + [x])
            if sum(result) > MAX_SUM:
                return None
            roots.append(result)
        elif tag in (2, 3):
            if b != -1 or x != -1 or y != -1 or not left:
                return None
            if tag == 2:
                aux, result = left[0], left[1:]
            else:
                aux, result = left[-1], left[:-1]
            roots.append(result)
        elif tag == 4:
            if b < 0 or b >= len(roots) or x != -1 or y != -1:
                return None
            result = left + roots[b]
            if len(result) > MAX_LEN or sum(result) > MAX_SUM:
                return None
            roots.append(result)
        elif tag == 5:
            if b != -1 or y != -1 or not 0 <= x <= len(left):
                return None
            result = left[:x]
            second = left[x:]
            roots.extend((result, second))
            right_root = len(roots) - 1
            aux = x
        else:
            if b != -1 or y != -1 or not 1 <= x <= MAX_SUM:
                return None
            split = next((i for i in range(1, len(left)+1)
                          if sum(left[:i]) >= x), None)
            if split is None:
                result, second = left[:], []
            else:
                result, second = left[:split], left[split:]
                aux = split
            roots.extend((result, second))
            right_root = len(roots) - 1
        left_id = len(roots) - 2 if right_root >= 0 else len(roots) - 1
        words.extend((left_id, len(roots[left_id]), sum(roots[left_id]),
                      right_root,
                      len(roots[right_root]) if right_root >= 0 else -1,
                      sum(roots[right_root]) if right_root >= 0 else -1,
                      aux))
    return words


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    words = _simulate(values, input_length, input_is_null)
    if words is None:
        return INVALID_RESULT, b""
    payload = b"".join(struct.pack("<q", word) for word in words)
    if (type(output_is_null) is not bool or output_is_null
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < len(payload))):
        return OUTPUT_ERROR, b""
    return len(payload), payload
