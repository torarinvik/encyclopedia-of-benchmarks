"""Reference that recomputes each window using bitwise polynomial division."""

from collections.abc import Sequence


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= 65)
            or input_is_null or values is None or not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)):
        return -1, b""
    if not 1 <= len(values) <= 65 or any(type(x) is not int for x in values):
        return -1, b""
    n = values[0]
    if not 0 <= n <= 64 or len(values) != n + 1 or any(not 0 <= x <= 255 for x in values[1:]):
        return -1, b""
    data = values[1:]
    boundaries = []
    for end in range(1, n + 1):
        bits = 0
        for byte in data[max(0, end - 4):end]:
            bits = (bits << 8) | byte
        for degree in range(31, 15, -1):
            if bits & (1 << degree):
                bits ^= 0x1100B << (degree - 16)
        if bits & 7 == 0:
            boundaries.append(end)
    if n and (not boundaries or boundaries[-1] != n):
        boundaries.append(n)
    payload = bytes(boundaries)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
