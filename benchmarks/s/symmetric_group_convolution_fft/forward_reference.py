"""Unexecuted subgroup-chain forward-transform research draft.

This draft is for deriving and checking the transform, not a production port.
The inverse transform, suite ABI, and complete resource bounds remain open.
"""
from functools import lru_cache
from itertools import permutations
from math import factorial

from .seminormal_reference import P, generator_columns, tableaux


@lru_cache(maxsize=None)
def plan(n):
    """Cache tableaux, subgroup block embeddings and adjacent generators."""
    bases = tableaux(n)
    previous = tableaux(n-1) if n > 1 else {}
    result = {}
    for shape, basis in bases.items():
        generators = tuple(generator_columns(basis, i) for i in range(n-1))
        groups = {}
        for index, tableau in enumerate(basis):
            groups.setdefault(tableau[-1], []).append((index, tableau[:-1]))
        embeddings = []
        for cell, entries in groups.items():
            smaller = list(shape)
            smaller[cell[0]] -= 1
            if smaller[-1] == 0:
                smaller.pop()
            child_shape = tuple(smaller)
            if n > 1:
                # Ordering is part of the restriction convention, not merely
                # a promise that matching tableaux occur somewhere in a block.
                if tuple(prefix for _, prefix in entries) != previous[child_shape]:
                    raise ValueError("tableau restriction order is inconsistent")
            embeddings.append((child_shape, tuple(index for index, _ in entries)))
        result[shape] = (len(basis), generators, tuple(embeddings))
    return result


def left_generator(matrix, columns):
    """Multiply a dense row-major block on the left by a sparse generator."""
    dimension = len(columns)
    out = [0] * (dimension * dimension)
    for source, column in enumerate(columns):
        for target, coefficient in column:
            for j in range(dimension):
                slot = target*dimension+j
                out[slot] = (out[slot]+coefficient*matrix[source*dimension+j]) % P
    return out


def forward(n, values):
    """Compute all representation blocks, with lexicographic input order."""
    if type(n) is not int or not 1 <= n <= 9:
        raise ValueError("degree must be in 1..9")
    if (not isinstance(values, (tuple, list)) or len(values) != factorial(n)
            or any(type(x) is not int or not 0 <= x < P for x in values)):
        raise ValueError("invalid function coefficients")
    return _forward(n, values)


def _forward(n, values):
    if n == 1:
        return {(1,): [values[0]]}
    indices = {permutation: i for i, permutation in enumerate(permutations(range(n)))}
    subgroup = tuple(permutations(range(n-1)))
    shape_plan = plan(n)
    output = {shape: [0] * (dimension*dimension)
              for shape, (dimension, _, _) in shape_plan.items()}
    for j in range(n):
        # g = t_j h, where h fixes n-1 and t_j swaps j and n-1.
        restricted = []
        for h in subgroup:
            extended = (*h, n-1)
            g = tuple(n-1 if value == j else j if value == n-1 else value
                      for value in extended)
            restricted.append(values[indices[g]])
        children = _forward(n-1, restricted)
        for shape, (dimension, generators, embeddings) in shape_plan.items():
            embedded = [0] * (dimension*dimension)
            for child_shape, slots in embeddings:
                child = children[child_shape]
                width = len(slots)
                for r, row in enumerate(slots):
                    for c, col in enumerate(slots):
                        embedded[row*dimension+col] = child[r*width+c]
            # (j,n-1) is the palindromic word s_j ... s_(n-2) ... s_j.
            word = (*range(j, n-1), *range(n-3, j-1, -1))
            for adjacent in word:
                embedded = left_generator(embedded, generators[adjacent])
            block = output[shape]
            for i in range(len(block)):
                block[i] = (block[i]+embedded[i]) % P
    return output
