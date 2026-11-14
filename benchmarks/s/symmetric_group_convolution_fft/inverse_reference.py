"""Unexecuted transpose-recursion inverse-transform research draft."""
from itertools import permutations
from math import factorial

from .forward_reference import P, plan


def invariant_diagonal(dimension, generators):
    """Construct a diagonal form D satisfying S^T D = D S for generators."""
    weights = [None] * dimension
    for start in range(dimension):
        if weights[start] is not None:
            continue
        weights[start] = 1
        queue = [start]
        for source in queue:
            for generator in generators:
                for target, forward in generator[source]:
                    if source == target:
                        continue
                    backward = next((coefficient for row, coefficient in generator[target]
                                     if row == source), None)
                    if backward is None or forward == 0 or backward == 0:
                        raise ValueError("noninvertible seminormal pair")
                    candidate = weights[source] * backward * pow(forward, P-2, P) % P
                    if weights[target] is None:
                        weights[target] = candidate
                        queue.append(target)
                    elif weights[target] != candidate:
                        raise ValueError("seminormal invariant form is inconsistent")
    return weights


def left_generator_transpose(matrix, columns):
    """Adjoint of left_generator under entrywise matrix pairing."""
    dimension = len(columns)
    out = [0] * (dimension*dimension)
    for source, column in enumerate(columns):
        for target, coefficient in column:
            for j in range(dimension):
                slot = source*dimension+j
                out[slot] = (out[slot]+coefficient*matrix[target*dimension+j]) % P
    return out


def inverse(n, blocks):
    """Recover lexicographic coefficients through a transposed forward map."""
    if type(n) is not int or not 1 <= n <= 9 or not isinstance(blocks, dict):
        raise ValueError("invalid degree or blocks")
    if n == 1:
        if set(blocks) != {(1,)} or len(blocks[(1,)]) != 1:
            raise ValueError("invalid degree-one block")
        return [blocks[(1,)][0] % P]
    shape_plan = plan(n)
    if blocks.keys() != shape_plan.keys():
        raise ValueError("incorrect representation shapes")
    inverse_order = pow(factorial(n), P-2, P)
    weighted = {}
    for shape, (dimension, generators, _) in shape_plan.items():
        block = blocks[shape]
        if len(block) != dimension*dimension or any(type(x) is not int or not 0 <= x < P for x in block):
            raise ValueError("invalid Fourier block")
        diagonal = invariant_diagonal(dimension, generators)
        reciprocal = [pow(value, P-2, P) for value in diagonal]
        weighted[shape] = [block[row*dimension+col] * dimension * inverse_order
                           * diagonal[row] * reciprocal[col] % P
                           for row in range(dimension) for col in range(dimension)]
    return transpose_forward(n, weighted)


def transpose_forward(n, gradients):
    """Apply the transpose of the recursive forward map to block gradients."""
    if n == 1:
        return [gradients[(1,)][0]]
    shape_plan = plan(n)
    child_plan = plan(n-1) if n > 2 else {(1,): (1, (), ())}
    indices = {permutation: i for i, permutation in enumerate(permutations(range(n)))}
    subgroup = tuple(permutations(range(n-1)))
    output = [0] * factorial(n)
    for j in range(n):
        child_gradients = {shape: [0] * (dimension*dimension)
                           for shape, (dimension, _, _) in child_plan.items()}
        for shape, (dimension, generators, embeddings) in shape_plan.items():
            block = gradients[shape]
            word = (*range(j, n-1), *range(n-3, j-1, -1))
            for adjacent in reversed(word):
                block = left_generator_transpose(block, generators[adjacent])
            for child_shape, slots in embeddings:
                child = child_gradients[child_shape]
                width = len(slots)
                for r, row in enumerate(slots):
                    for c, col in enumerate(slots):
                        slot = r*width+c
                        child[slot] = (child[slot]+block[row*dimension+col]) % P
        restricted = transpose_forward(n-1, child_gradients)
        for i, h in enumerate(subgroup):
            extended = (*h, n-1)
            g = tuple(n-1 if value == j else j if value == n-1 else value
                      for value in extended)
            output[indices[g]] = restricted[i]
    return output
