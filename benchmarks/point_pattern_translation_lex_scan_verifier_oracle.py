"""Independent verifier using candidate offsets and direct set membership."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_PATTERN = 6
MAX_TARGET = 8
MAX_COORD = 16
MAX_INPUT_LENGTH = 31


def _parse(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(x) is not int or x < -(1 << 63) or x >= (1 << 63) for x in values):
        return None
    m, n = values[:2]
    if not (1 <= m <= MAX_PATTERN and 1 <= n <= MAX_TARGET and m <= n):
        return None
    if len(values) != 2 + 2 * (m + n):
        return None
    pos = 2
    pattern = [tuple(values[pos + 2 * i:pos + 2 * i + 2]) for i in range(m)]
    pos += 2 * m
    target = [tuple(values[pos + 2 * i:pos + 2 * i + 2]) for i in range(n)]
    if any(abs(v) > MAX_COORD for p in pattern + target for v in p):
        return None
    if pattern != sorted(set(pattern)) or target != sorted(set(target)):
        return None
    return pattern, target


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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    pattern, target = parsed
    target_set = set(target)
    translations = []
    for tx, ty in target:
        dx, dy = tx - pattern[0][0], ty - pattern[0][1]
        if all((px + dx, py + dy) in target_set for px, py in pattern):
            translations.append((dx, dy))
    if translations:
        found, dx, dy = 1, *min(translations)
    else:
        found, dx, dy = 0, 0, 0
    payload = struct.pack("<qqq", found, dx, dy)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
