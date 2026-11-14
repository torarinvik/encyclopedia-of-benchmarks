"""Small-input reference for Lyndon factor lengths by direct comparison.

This deliberately avoids Duval's scan. It is intended for exhaustive small
inputs only; its repeated substring comparisons are not a benchmark port.
"""


def factor_lengths(values):
    """Return the standard factor lengths for a sequence of at most 16 items."""
    if len(values) > 16:
        raise ValueError("direct reference is restricted to 16 items")
    remaining = tuple(values)
    factors = []
    while remaining:
        best = 0
        for length in range(1, len(remaining) + 1):
            prefix = remaining[:length]
            if all(prefix < prefix[split:] for split in range(1, length)):
                best = length
        factors.append(best)
        remaining = remaining[best:]
    return factors
