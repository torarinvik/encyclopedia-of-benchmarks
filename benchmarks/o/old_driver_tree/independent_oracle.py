"""Direct-array oracle for Old Driver Tree operation traces."""

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
    parsed = parse_input(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    n, array, operations, output_count = parsed
    required = 8 * output_count
    if required and (output_is_null or output_capacity is not None and output_capacity < required):
        return OUTPUT_ERROR, b""
    answers: list[int] = []
    for kind, left, right, argument, *extra in operations:
        if kind == 0:
            for index in range(left, right + 1):
                array[index] = argument
        elif kind == 1:
            for index in range(left, right + 1):
                array[index] += argument
        elif kind == 2:
            ordered = sorted(array[left : right + 1])
            answers.append(ordered[argument - 1])
        else:
            exponent, modulus = argument, extra[0]
            answers.append(sum(pow(array[index], exponent, modulus)
                               for index in range(left, right + 1)) % modulus)
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload
