"""Independent oracle for the bounded Olden bisort tree workload."""

MIN_SIZE = 2
MAX_SIZE = 1_024
NODE_LIMIT = MAX_SIZE - 1
INVALID_RESULT = -1

_MODULUS = 10_000
_MULTIPLIER = 31_415_821
_RANGE = 100


def _multiply_modulus(p: int, q: int) -> int:
    """Reproduce Olden's overflow-avoiding split multiplication."""
    p_high, p_low = divmod(p, _MODULUS)
    q_high, q_low = divmod(q, _MODULUS)
    return (((p_low * q_high + p_high * q_low) % _MODULUS) * _MODULUS
            + p_low * q_low)


def _next_random(seed: int) -> int:
    return _multiply_modulus(seed, _MULTIPLIER) + 1


def _advance(seed: int, count: int) -> int:
    for _ in range(count):
        seed = _next_random(seed)
    return seed


def _tree_values(size: int, seed: int) -> list[int]:
    """Return generated node values; a leaf in the source is a null pointer."""
    if size <= 1:
        return []
    seed = _next_random(seed)
    values = [seed % _RANGE]
    values.extend(_tree_values(size // 2, seed))
    values.extend(_tree_values(size // 2, _advance(seed, size + 1)))
    return values


def expected_result(size: int) -> int:
    """Return the one-based weighted checksum after both bitonic passes.

    The source sorts the generated tree and its spill value ascending, then
    descending. The oracle uses a flat mathematical sort rather than the
    implementation's recursive tree merge, so it independently checks the
    resulting ordering while preserving the source's generator.
    """
    if type(size) is not int or not MIN_SIZE <= size <= MAX_SIZE:
        return INVALID_RESULT
    values = _tree_values(size, 12_345_768)
    values.append(_next_random(245_867) % _RANGE)
    values.sort(reverse=True)
    return sum(position * value for position, value in enumerate(values, 1))
