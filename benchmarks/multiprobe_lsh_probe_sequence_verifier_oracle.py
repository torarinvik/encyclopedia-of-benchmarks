"""Reference enumerating ternary perturbation vectors, without a heap."""

from collections.abc import Sequence
from itertools import product


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= 7)
            or input_is_null or values is None or not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)):
        return -1, b""
    if not 4 <= len(values) <= 7 or any(type(x) is not int for x in values):
        return -1, b""
    m, width, count = values[:3]
    if not 1 <= m <= 4 or not 1 <= width <= 1000 or not 0 <= count <= 3**m-1 or len(values) != 3+m:
        return -1, b""
    if any(not 0 <= distance <= width for distance in values[3:]):
        return -1, b""
    choices = sorted((d, i, sign) for i, lower in enumerate(values[3:])
                     for d, sign in ((lower, -1), (width-lower, 1)))
    position = {(i, sign): bit for bit, (_, i, sign) in enumerate(choices)}
    entries = []
    for vector in product((-1, 0, 1), repeat=m):
        if not any(vector):
            continue
        mask = sum(1 << position[(i, sign)] for i, sign in enumerate(vector) if sign)
        score = sum((values[3+i] if sign == -1 else width-values[3+i])**2
                    for i, sign in enumerate(vector) if sign)
        entries.append((score, sum(sign != 0 for sign in vector), mask))
    payload = bytes(mask for _, _, mask in sorted(entries)[:count])
    if output_is_null or capacity is not None and capacity < count:
        return -2, b""
    return count, payload
