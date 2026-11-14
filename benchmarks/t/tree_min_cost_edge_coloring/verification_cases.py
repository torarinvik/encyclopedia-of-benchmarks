"""Unexecuted source-only cross-reference cases for edge-coloring drafts."""
from itertools import product

from .fast_reference import expected, matching_and_deletions
from .reference import brute_small, deletion_costs_brute, subset_reference


def check_small_references():
    # Separate matching oracle checks every deleted column, not merely the
    # ultimately selected root state. These matrices include ties.
    for d in range(1, 4):
        alphabet = (0, 1, 3) if d < 3 else (0, 2)
        for entries in product(alphabet, repeat=d*(d+1)):
            matrix = [entries[row*(d+1):(row+1)*(d+1)] for row in range(d)]
            _, observed = matching_and_deletions(matrix)
            if observed != deletion_costs_brute(matrix):
                raise ValueError("matching deletion costs disagree")
    # Increasing-parent arrays enumerate rooted labeled trees in the profile.
    for n in range(1, 6):
        for parents in product(*(range(v) for v in range(1, n))):
            for k in range(1, 4):
                for prices in product((0, 1, 4), repeat=k):
                    values = (n, k, *parents, *prices)
                    result = brute_small(values)
                    if expected(values) != result or subset_reference(values) != result:
                        raise ValueError("edge-coloring constructions disagree")


def check_full_range_shapes():
    # A path alternates two colors; the cheaper color occurs 32 times.
    chain = (64, 2, *range(63), 1, 5)
    # A 16-edge star uses every color once; prices are intentionally reversed.
    star = (17, 16, *([0] * 16), *range(15, -1, -1))
    # Exceeding the available palette is invalid for any proper edge coloring.
    oversized_star = (64, 16, *([0] * 63), *range(16))
    for values, result in ((chain, 187), (star, 120), (oversized_star, -2)):
        if expected(values) != result:
            raise ValueError("full-range structured edge coloring differs")
