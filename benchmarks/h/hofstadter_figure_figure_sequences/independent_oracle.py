"""Independent verifier based on complement and recurrence properties."""
from __future__ import annotations

from struct import unpack


def _parse(values, input_is_null: bool, input_length: int | None):
    if values is None or input_is_null or len(values) != 1:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    if input_length is not None and input_length != 1:
        return None
    n = values[0]
    return n if 1 <= n <= 64 else None


def verify_result(values, result: int, payload: bytes, *,
                  output_capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False, input_length: int | None = None) -> bool:
    n = _parse(values, input_is_null, input_length)
    if n is None:
        return result == -1 and payload == b""
    output_bytes = (1 + 2 * n) * 8
    if output_is_null or (output_capacity is not None and output_capacity < output_bytes):
        return result == -2 and payload == b""
    if result != output_bytes or len(payload) != output_bytes:
        return False
    words = unpack("<" + "q" * (1 + 2 * n), payload)
    if words[0] != n:
        return False
    figure = list(words[1:1 + n])
    space = list(words[1 + n:])
    if figure[0] != 1 or space[0] != 2:
        return False
    if any(value <= 0 for value in figure + space):
        return False
    if any(figure[i] <= figure[i - 1] or space[i] <= space[i - 1]
           for i in range(1, n)):
        return False
    if set(figure).intersection(space):
        return False
    for index in range(1, n):
        if figure[index] != figure[index - 1] + space[index - 1]:
            return False
        candidate = space[index - 1] + 1
        while candidate < space[index]:
            if candidate not in figure[:index + 1]:
                return False
            candidate += 1
        if space[index] in figure[:index + 1]:
            return False
    return True
