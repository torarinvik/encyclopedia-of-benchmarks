"""Direct suffix-slice sorting oracle for the suffix balanced tree package."""

from __future__ import annotations

from collections.abc import Sequence
import struct

try:
    from .primary_oracle import INVALID, OUTPUT_ERROR, parse_input
except ImportError:  # Direct import from this package directory.
    from primary_oracle import INVALID, OUTPUT_ERROR, parse_input


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0)):
        return INVALID, b""
    text = parse_input(values, input_is_null, input_length)
    if text is None:
        return INVALID, b""
    required = 8 * len(text)
    if output_is_null or output_capacity is not None and output_capacity < required:
        return OUTPUT_ERROR, b""
    suffixes = sorted(range(len(text)), key=lambda start: tuple(text[start:]))
    payload = b"".join(struct.pack("<q", suffix) for suffix in suffixes)
    return len(payload), payload
