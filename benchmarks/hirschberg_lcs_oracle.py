"""Shared-suite entry point for the Hirschberg package's primary oracle."""

from h.hirschberg_lcs.primary_oracle import (
    MAX_INPUT_LENGTH,
    MAX_PARSEABLE_LENGTH,
    MAX_OUTPUT_BYTES,
    MAX_SEQUENCE_LENGTH,
    WORKSPACE_BYTES,
    expected_output,
)

__all__ = [
    "MAX_INPUT_LENGTH", "MAX_PARSEABLE_LENGTH", "MAX_OUTPUT_BYTES",
    "MAX_SEQUENCE_LENGTH", "WORKSPACE_BYTES", "expected_output",
]
