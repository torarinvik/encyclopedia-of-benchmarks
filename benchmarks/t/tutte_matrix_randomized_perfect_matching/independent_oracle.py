"""Package-local name for the cofactor-expansion reference."""

from benchmarks.tutte_matrix_randomized_perfect_matching_verifier_oracle import (
    FIELD_PRIME,
    MAX_EDGES,
    MAX_N,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_output,
)

ALGORITHM = "tutte_matrix_randomized_perfect_matching"

__all__ = [
    "ALGORITHM", "FIELD_PRIME", "MAX_EDGES", "MAX_N", "MAX_OUTPUT_BYTES",
    "MAX_PARSEABLE_INPUT_LENGTH", "MAX_VALID_INPUT_LENGTH", "WORKSPACE_BYTES",
    "expected_output",
]
