"""Shared-suite adapter for the semi-local prefix/substring LCS oracle."""

from p.prefix_substring_lcs.primary_oracle import (
    MAX_INPUT_LENGTH,
    MAX_OUTPUT_BYTES,
    expected_output,
)

__all__ = ["MAX_INPUT_LENGTH", "MAX_OUTPUT_BYTES", "expected_output"]
