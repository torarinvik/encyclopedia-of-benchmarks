"""Oracle for the pinned C# GallopingStrategy insertion-bound methods."""
MAX_INPUT_LENGTH = 69
MAX_VALUES = 64


def _bound_left_shift(value: int) -> int:
    shifted = (value << 1) & 0xFFFFFFFF
    if shifted & 0x80000000:
        return shifted - 0xFFFFFFFF
    return 0x7FFFFFFF


def _left_run(a, key, base, hint):
    max_offset = hint + 1
    offset, tmp = 1, 0
    while offset < max_offset and key < a[base + hint - offset]:
        tmp = offset
        offset = _bound_left_shift(offset)
    if offset > max_offset:
        offset = max_offset
    last = hint - offset
    offset = hint - tmp
    return offset, last


def _right_run(a, key, base, length, hint):
    offset, last = 1, 0
    max_offset = length - hint
    while offset < max_offset and key > a[base + hint + offset]:
        last = offset
        offset = _bound_left_shift(offset)
    if offset > max_offset:
        offset = max_offset
    return offset + hint, last + hint


def _final_offset(a, key, base, offset, last, lt):
    last += 1
    while last < offset:
        middle = last + ((offset - last) >> 1)
        if (key > a[base + middle]) - (key < a[base + middle]) < lt:
            offset = middle
        else:
            last = middle + 1
    return offset


def expected_result(values):
    if (not isinstance(values, (list, tuple)) or not 5 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1
    op, n, base, length, key = values[:5]
    if op not in (0, 1) or n < 0 or n > MAX_VALUES or len(values) != 5 + n:
        return -1
    if base < 0 or length < 0 or base > n or length > n - base:
        return -1
    a = values[5:]
    if any(x < -(2**31) or x > 2**31 - 1 for x in [key, *a]):
        return -1
    if any(a[i] > a[i + 1] for i in range(base, base + length - 1)):
        return -1
    if n == 0:
        return 0
    if length == 0 or base >= n:
        return -1
    if op == 0:
        offset, last = (_right_run(a, key, base, length, 0) if key > a[base]
                        else _left_run(a, key, base, 0))
        return _final_offset(a, key, base, offset, last, 1)
    offset, last = (_left_run(a, key, base, length) if key < a[base]
                    else _right_run(a, key, base, length, 0))
    return _final_offset(a, key, base, offset, last, 0)
