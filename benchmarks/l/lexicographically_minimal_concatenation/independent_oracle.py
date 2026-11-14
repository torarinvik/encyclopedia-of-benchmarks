"""Exhaustive reference for small sets of byte strings."""
from itertools import permutations
from functools import cmp_to_key


def expected(words):
    if len(words) > 8:
        raise ValueError("exhaustive reference accepts at most eight words")
    return min((b"".join(order) for order in permutations(words)), default=b"")


def evaluate(values, capacity, output_is_null=False):
    if values is None or not values or not 0 <= values[0] <= 16384:
        return -1, b""
    count = values[0]
    offset = 1
    total = 0
    words = []
    for _ in range(count):
        if offset >= len(values) or not 1 <= values[offset] <= 65536:
            return -1, b""
        size = values[offset]
        offset += 1
        if size > 65536 - total or size > len(values) - offset:
            return -1, b""
        part = values[offset:offset + size]
        if any(not 97 <= value <= 122 for value in part):
            return -1, b""
        words.append(bytes(part))
        offset += size
        total += size
    if offset != len(values):
        return -1, b""
    if output_is_null or capacity < total:
        return -2, b""
    if count <= 8:
        result = expected(words)
    else:
        def compare(a, b):
            return (a + b > b + a) - (a + b < b + a)
        result = b"".join(sorted(words, key=cmp_to_key(compare)))
    return len(result), result


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or type(output_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    return evaluate(values, 65536 if capacity is None else capacity, output_is_null)
