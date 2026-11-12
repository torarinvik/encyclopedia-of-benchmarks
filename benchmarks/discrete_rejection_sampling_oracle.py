"""Shared-suite entry point for the finite discrete rejection sampler."""

from d.discrete_rejection_sampling.primary_oracle import (
    MAX_INPUT_LENGTH,
    MAX_PARSEABLE_LENGTH,
    MAX_OUTPUT_BYTES,
    WORKSPACE_BYTES,
    expected_output,
)

__all__ = ["MAX_INPUT_LENGTH", "MAX_PARSEABLE_LENGTH", "MAX_OUTPUT_BYTES", "WORKSPACE_BYTES", "expected_output"]
