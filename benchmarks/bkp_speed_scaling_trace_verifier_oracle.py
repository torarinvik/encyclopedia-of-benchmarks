"""Independent Fraction-based byte reference for the bounded BKP trace."""
from __future__ import annotations

import struct
from collections.abc import Sequence

from b.bkp_speed_scaling_trace.independent_oracle import expected_values


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    fields = expected_values(values, input_is_null, input_length)
    if fields == -1:
        return -1, b""
    payload = struct.pack("<" + "q" * len(fields), *fields)
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < len(payload))):
        return -2, b""
    return len(payload), payload
