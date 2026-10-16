"""Oracle for bounded dotted IPv4 decimal/binary text conversion."""

from __future__ import annotations

MAX_PAYLOAD_LENGTH = 35
MAX_INPUT_LENGTH = 2 + MAX_PAYLOAD_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_LENGTH = 35
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    mode, payload_length = values[0], values[1]
    if mode not in (0, 1) or not 0 <= payload_length <= MAX_PAYLOAD_LENGTH:
        return -1, b""
    if len(values) != payload_length + 2:
        return -1, b""
    payload_values = values[2:]
    if any(not 0 <= value <= 127 for value in payload_values):
        return -1, b""
    try:
        payload = bytes(payload_values).decode("ascii")
    except (ValueError, UnicodeDecodeError):
        return -1, b""

    if mode == 0:
        if not 7 <= payload_length <= 15:
            return -1, b""
        groups = payload.split(".")
        if len(groups) != 4 or any(not 1 <= len(group) <= 3 or not group.isascii() or not group.isdigit()
                                   for group in groups):
            return -1, b""
        octets = [int(group, 10) for group in groups]
        if any(not 0 <= value <= 255 for value in octets):
            return -1, b""
        output = ".".join(f"{value:08b}" for value in octets).encode("ascii")
    else:
        if payload_length != 35:
            return -1, b""
        groups = payload.split(".")
        if (len(groups) != 4 or any(len(group) != 8 or any(bit not in "01" for bit in group)
                                    for group in groups)):
            return -1, b""
        output = ".".join(str(int(group, 2)) for group in groups).encode("ascii")

    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
