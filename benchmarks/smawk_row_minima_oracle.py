"""Shared-suite entry point for the SMAWK row-minimum primary oracle."""

from s.smawk_row_minima.primary_oracle import (
    MAX_INPUT_LENGTH,
    MAX_PARSEABLE_LENGTH,
    MAX_OUTPUT_BYTES,
    WORKSPACE_BYTES,
    expected_output,
)

__all__ = ["MAX_INPUT_LENGTH", "MAX_PARSEABLE_LENGTH", "MAX_OUTPUT_BYTES",
           "WORKSPACE_BYTES", "expected_output"]
