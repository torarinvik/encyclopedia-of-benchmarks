"""Package-local name for the source-faithful modified-KMP reference."""

from benchmarks.parameterized_pattern_matching_kmp_oracle import (
    MAX_ALPHABET,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_PATTERN,
    MAX_TEXT,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_output,
)

ALGORITHM = "parameterized_pattern_matching_kmp"

__all__ = [
    "ALGORITHM", "MAX_ALPHABET", "MAX_OUTPUT_BYTES",
    "MAX_PARSEABLE_INPUT_LENGTH", "MAX_PATTERN", "MAX_TEXT",
    "MAX_VALID_INPUT_LENGTH", "WORKSPACE_BYTES", "expected_output",
]
