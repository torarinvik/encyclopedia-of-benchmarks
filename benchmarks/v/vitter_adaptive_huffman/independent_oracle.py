"""Independent object-tree reference for Vitter Algorithm A."""

from __future__ import annotations

from collections.abc import Sequence

from adaptive_huffman_independent import expected_output as _expected_output
from adaptive_huffman_oracle import INVALID_RESULT, OUTPUT_ERROR


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    return _expected_output(values, "vitter", capacity, output_is_null,
                            input_is_null, input_length)
