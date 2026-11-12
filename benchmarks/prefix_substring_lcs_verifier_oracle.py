"""Independent per-query LCS verifier for prefix/substring queries."""

from p.prefix_substring_lcs.independent_oracle import (
    MAX_INPUT_LENGTH,
    MAX_OUTPUT_BYTES,
    expected_output,
)

__all__ = ["MAX_INPUT_LENGTH", "MAX_OUTPUT_BYTES", "expected_output"]
