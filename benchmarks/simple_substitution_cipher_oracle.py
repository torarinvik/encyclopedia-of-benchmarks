"""Bounded ASCII oracle for TheAlgorithms/Python simple substitution cipher."""

from __future__ import annotations

MAX_MESSAGE_LENGTH = 256
MAX_INPUT_LENGTH = 28 + MAX_MESSAGE_LENGTH
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


def expected_output(
    values: list[int] | tuple[int, ...] | None,
    output_capacity: int | None = None,
) -> tuple[int, bytes]:
    """Return `(byte_count, bytes)` for `[mode,key[26],length,message...]`."""
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if (
        len(values) < 28
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""
    mode = values[0]
    key_values = values[1:27]
    message_length = values[27]
    if mode not in (0, 1) or not 0 <= message_length <= MAX_MESSAGE_LENGTH:
        return INVALID_RESULT, b""
    if len(values) != 28 + message_length:
        return INVALID_RESULT, b""
    if sorted(key_values) != list(range(ord("A"), ord("Z") + 1)):
        return INVALID_RESULT, b""
    message = values[28:]
    if any(not 0 <= byte <= 127 for byte in message):
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if output_capacity is not None and output_capacity < message_length:
        return INSUFFICIENT_CAPACITY_RESULT, b""

    key = "".join(chr(value) for value in key_values)
    source, target = (LETTERS, key) if mode == 0 else (key, LETTERS)
    transformed = bytearray()
    for byte in message:
        symbol = chr(byte)
        upper = symbol.upper()
        if upper not in source:
            transformed.append(byte)
            continue
        mapped = target[source.index(upper)]
        transformed.append(ord(mapped if symbol.isupper() else mapped.lower()))
    return len(transformed), bytes(transformed)
