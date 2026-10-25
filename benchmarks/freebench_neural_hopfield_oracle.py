"""Independent oracle for the bounded FreeBench Hopfield benchmark profile."""

from __future__ import annotations

from collections.abc import Sequence

PATTERN_COUNT = 10
MAX_NEURONS = 8
MAX_DIMENSION = 8
MAX_INPUT_LENGTH = 3 + PATTERN_COUNT * (1 + MAX_NEURONS)
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
INVALID_RESULT = -1


def expected_result(values: Sequence[int]) -> int:
    """Return the number of stored patterns for the convergence-proven domain.

    For ten identical bipolar vectors p with N >= 2, the off-diagonal Hebbian
    matrix gives each neuron a field 10*(N-1)*p[i]. Its magnitude is at least
    10, so the continuous recall has the same sign on its first update. Every
    delta correction is therefore zero and the source's training loop exits
    after one pass. This oracle checks the contract and derives the result from
    that invariant rather than running the ports' matrix/activation loops.
    """
    if (not isinstance(values, (list, tuple))
            or len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    width, height, pattern_count = values[:3]
    if (width < 1 or width > MAX_DIMENSION or height < 1 or height > MAX_DIMENSION
            or pattern_count != PATTERN_COUNT):
        return INVALID_RESULT
    neurons = width * height
    if neurons < 2 or neurons > MAX_NEURONS:
        return INVALID_RESULT
    record_length = 1 + neurons
    if len(values) != 3 + PATTERN_COUNT * record_length:
        return INVALID_RESULT

    reference: tuple[int, ...] | None = None
    offset = 3
    for _ in range(PATTERN_COUNT):
        label = values[offset]
        if label < 65 or label > 90:
            return INVALID_RESULT
        pattern = tuple(values[offset + 1:offset + record_length])
        if len(pattern) != neurons or any(cell not in (-1, 1) for cell in pattern):
            return INVALID_RESULT
        if reference is None:
            reference = pattern
        elif pattern != reference:
            return INVALID_RESULT
        offset += record_length
    return PATTERN_COUNT
