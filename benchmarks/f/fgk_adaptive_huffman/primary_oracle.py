"""Primary bounded FGK adaptive-Huffman reference."""

from __future__ import annotations

from collections.abc import Sequence

from adaptive_huffman_oracle import (
    ALPHABET, INVALID_RESULT, MAX_INPUT_LENGTH, MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH, MAX_SYMBOLS, MAX_WORKSPACE_BYTES,
    OUTPUT_ERROR, expected_output as _expected_output,
)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    return _expected_output(values, "fgk", capacity, output_is_null,
                            input_is_null, input_length)
