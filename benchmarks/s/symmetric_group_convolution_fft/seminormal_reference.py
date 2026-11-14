"""Unexecuted Young-tableau and sparse-generator research scaffold.

This is not the benchmark transform. It constructs small representation
matrices so later work can compare generator relations and block orientation.
"""
from collections import defaultdict

P = 998244353


def tableaux(n):
    """Return shape -> tableaux, each tableau a tuple of (row, column) cells."""
    if type(n) is not int or not 1 <= n <= 9:
        raise ValueError("degree must be in 1..9")
    groups = defaultdict(list)

    def extend(shape, positions):
        if len(positions) == n:
            groups[tuple(shape)].append(tuple(positions))
            return
        for row in range(len(shape) + 1):
            if row == len(shape):
                extend([*shape, 1], [*positions, (row, 0)])
            elif row == 0 or shape[row] < shape[row - 1]:
                updated = list(shape)
                column = updated[row]
                updated[row] += 1
                extend(updated, [*positions, (row, column)])

    extend([], [])
    # Last-cell-first ordering groups each restriction to S_(n-1), and the
    # same rule recursively groups the remaining subgroup chain.
    return {shape: tuple(sorted(group, key=lambda tableau: tuple(reversed(tableau))))
            for shape, group in groups.items()}


def generator_columns(basis, adjacent):
    """Return sparse columns for the swap of zero-based labels i and i+1.

    For a pair of standard tableaux choose the member with positive content
    difference as the first basis vector. Matrix columns describe images of
    vectors; all coefficients are canonical field elements.
    """
    if not basis or not 0 <= adjacent < len(basis[0]) - 1:
        raise ValueError("invalid basis or generator")
    lookup = {tableau: i for i, tableau in enumerate(basis)}
    if len(lookup) != len(basis):
        raise ValueError("duplicate tableaux")
    columns = []
    for index, tableau in enumerate(basis):
        row1, col1 = tableau[adjacent]
        row2, col2 = tableau[adjacent + 1]
        distance = (col2-row2) - (col1-row1)
        if distance == 0:
            raise ValueError("equal adjacent contents in a purported tableau")
        diagonal = pow(distance % P, P-2, P)
        if abs(distance) == 1:
            columns.append(((index, diagonal),))
            continue
        swapped = list(tableau)
        swapped[adjacent], swapped[adjacent + 1] = swapped[adjacent + 1], swapped[adjacent]
        partner = lookup.get(tuple(swapped))
        if partner is None:
            raise ValueError("swapped tableau is missing")
        off_diagonal = 1 if distance > 0 else (1-diagonal*diagonal) % P
        columns.append(((index, diagonal), (partner, off_diagonal)))
    return tuple(columns)
