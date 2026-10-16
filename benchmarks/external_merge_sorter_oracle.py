"""Reference output for the bounded external merge-sort benchmark."""

from __future__ import annotations

import struct

MAX_INPUT_LENGTH = 4096
MAX_OUTPUT_BYTES = MAX_INPUT_LENGTH * 8


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return -1, b""
    output = b"".join(struct.pack("<q", value) for value in sorted(values))
    return len(output), output
