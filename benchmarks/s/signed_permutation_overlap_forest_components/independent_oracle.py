"""Package-local name for the explicit overlap-graph reference."""
from benchmarks.signed_permutation_overlap_forest_verifier_oracle import (
    MAX_CYCLES,
    MAX_N,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_output,
)

ALGORITHM = "signed_permutation_overlap_forest_components"

__all__ = [
    "ALGORITHM", "MAX_CYCLES", "MAX_N", "MAX_OUTPUT_BYTES",
    "MAX_PARSEABLE_INPUT_LENGTH", "MAX_VALID_INPUT_LENGTH", "WORKSPACE_BYTES",
    "expected_output",
]
