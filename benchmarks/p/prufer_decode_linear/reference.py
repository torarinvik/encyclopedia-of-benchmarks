"""Unexecuted references for largest-leaf Prüfer decoding."""

import struct


def parse(values):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= 4096
            or any(type(value) is not int for value in values)):
        return None
    n = values[0]
    if not 2 <= n <= 4096 or len(values) != n-1:
        return None
    code = values[1:]
    if any(not 0 <= value < n for value in code):
        return None
    return n, code


def edges(values):
    parsed = parse(values)
    if parsed is None:
        return None
    n, code = parsed
    count = [0]*n
    for v in code:
        count[v] += 1
    cursor = n-1
    while count[cursor] != 0:
        cursor -= 1
    leaf = cursor
    result = []
    for v in code:
        result.append((leaf, v))
        count[leaf] = -1
        count[v] -= 1
        if count[v] == 0 and v > cursor:
            leaf = v
        else:
            cursor -= 1
            while count[cursor] != 0:
                cursor -= 1
            leaf = cursor
    remaining = next(v for v in range(n) if v != leaf and count[v] == 0)
    result.append((leaf, remaining))
    return result


def scan_edges(values):
    parsed = parse(values)
    if parsed is None:
        return None
    n, code = parsed
    remaining = list(code)
    active = set(range(n))
    result = []
    for v in code:
        leaf = max(active.difference(remaining))
        result.append((leaf, v))
        active.remove(leaf)
        remaining.pop(0)
    result.append(tuple(sorted(active, reverse=True)))
    return result


def expected_output(values, capacity=65520, output_is_null=False, input_is_null=False, input_length=None):
    if input_is_null or (input_length is not None and input_length != len(values)):
        return -1, b""
    result = edges(values)
    if result is None:
        return -1, b""
    payload = b"".join(struct.pack("<qq", u, v) for u, v in result)
    if output_is_null or capacity < len(payload):
        return -2, b""
    return len(payload), payload


def independent_output(values, capacity=65520, output_is_null=False, input_is_null=False, input_length=None):
    if input_is_null or (input_length is not None and input_length != len(values)):
        return -1, b""
    result = scan_edges(values)
    if result is None:
        return -1, b""
    payload = b"".join(struct.pack("<qq", u, v) for u, v in result)
    if output_is_null or capacity < len(payload):
        return -2, b""
    return len(payload), payload
