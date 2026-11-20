"""Independent interval-bucket reference for the finite dice tape."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_DRAWS,
    MAX_OUTPUT_BYTES,
    OUTPUT_ERROR_RESULT,
)


def expected_output(values: Sequence[int] | None,
                    capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Partition each available interval into seven-face buckets."""
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_DRAWS + 2
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return INVALID_RESULT, b""
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT, b""
    draw_count = values[0]
    if (not 0 <= draw_count <= MAX_DRAWS or len(values) != draw_count + 1
            or any(not 0 <= draw <= 4 for draw in values[1:])):
        return INVALID_RESULT, b""
    if (type(output_is_null) is not bool or type(capacity) is not int
            or output_is_null or capacity < 0):
        return OUTPUT_ERROR_RESULT, b""

    residue = 0
    possibilities = 1
    faces = bytearray()
    for draw in values[1:]:
        residue = residue * 5 + draw
        possibilities *= 5
        while possibilities >= 7:
            bucket_count, tail_size = divmod(possibilities, 7)
            accepted_size = bucket_count * 7
            if residue < accepted_size:
                bucket, face_offset = divmod(residue, 7)
                faces.append(face_offset + 1)
                residue = bucket
                possibilities = bucket_count
            else:
                residue -= accepted_size
                possibilities = tail_size

    if capacity < len(faces):
        return OUTPUT_ERROR_RESULT, b""
    return len(faces), bytes(faces)
