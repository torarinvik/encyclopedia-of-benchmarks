"""Independent oracle for Parboil's bounded saturating histogram profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_BINS = 256
MAX_SAMPLES = 1024
MAX_INPUT_LENGTH = 3 + MAX_SAMPLES
MAX_ITERATIONS = 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: Sequence[int] | None) -> tuple[int, bytes]:
    """Return the flattened byte histogram, or the ABI error and no bytes."""
    if values is None or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int for value in values):
        return INVALID_RESULT, b""
    iterations, bins, sample_count = values[:3]
    if not (0 <= iterations <= MAX_ITERATIONS and 1 <= bins <= MAX_BINS and
            0 <= sample_count <= MAX_SAMPLES and len(values) == 3 + sample_count):
        return INVALID_RESULT, b""
    samples = values[3:]
    if any(value < 0 or value >= bins for value in samples):
        return INVALID_RESULT, b""

    # Counting each bin independently keeps the oracle distinct from the
    # ports' source-shaped clear-and-increment loop. Positive iteration counts
    # all produce the same final histogram because the source clears then
    # reprocesses the unchanged image on each pass.
    counts = [min(255, sum(1 for value in samples if value == bin_id))
              for bin_id in range(bins)]
    if iterations == 0:
        counts = [0] * bins
    return bins, bytes(counts)


oracle = expected_output
