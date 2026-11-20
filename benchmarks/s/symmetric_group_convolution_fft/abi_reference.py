"""Unexecuted small oracle for the proposed byte-output ABI.

Valid unstructured inputs above degree five raise NotImplementedError after
validation; they remain in scope and are not invalid inputs. Constant,
bounded-support, near-constant, and parity-derived functions have direct
full-range formulas.
"""
from itertools import permutations
from math import factorial
from .independent_oracle import P, convolve

MAX_VALID_WORDS = 725761
MAX_PARSEABLE_WORDS = 725762
MAX_OUTPUT_BYTES = 1451520


def sparse_support(values):
    """Return (index,value) for at most one nonzero, None otherwise."""
    support = None
    for i, value in enumerate(values):
        if value:
            if support is not None:
                return None
            support = (i, value)
    return support if support is not None else (-1, 0)


def lex_rank(permutation, facts):
    remaining = list(range(len(permutation)))
    rank = 0
    for index, value in enumerate(permutation):
        position = remaining.index(value)
        rank += position*facts[len(permutation)-index-1]
        remaining.pop(position)
    return rank


def bounded_sparse(n, a, b, limit=3):
    """Direct pair accumulation when at least one operand has small support."""
    def support(values):
        found = []
        for index, value in enumerate(values):
            if value:
                found.append((index, value))
                if len(found) > limit:
                    return None
        return found

    left, right = support(a), support(b)
    if left is None and right is None:
        return None
    sparse_left = right is None or (left is not None and len(left) <= len(right))
    selected = left if sparse_left else right
    wanted = {index for index, _ in selected}
    sparse_permutations = {index: p for index, p in enumerate(permutations(range(n)))
                           if index in wanted}
    facts = [factorial(i) for i in range(n+1)]
    result = [0] * factorial(n)
    other_values = b if sparse_left else a
    for index, other in enumerate(permutations(range(n))):
        if not other_values[index]:
            continue
        for sparse_index, coefficient in selected:
            permutation = sparse_permutations[sparse_index]
            target = (tuple(permutation[other[i]] for i in range(n)) if sparse_left
                      else tuple(other[permutation[i]] for i in range(n)))
            rank = lex_rank(target, facts)
            result[rank] = (result[rank] + coefficient*other_values[index]) % P
    return result


def near_constant_structured(n, a, b, limit=3):
    """Convolve a constant plus at most ``limit`` deviations with any operand."""
    def deviations(values):
        # A qualifying baseline is a strict majority for the large degrees
        # using this path. Find it without sorting the factorial-size array.
        candidate, balance = 0, 0
        for value in values:
            if balance == 0:
                candidate = value
                balance = 1
            elif value == candidate:
                balance += 1
            else:
                balance -= 1
        changes = [(value - candidate) % P for value in values]
        if sum(value != 0 for value in changes) > limit:
            return None
        return candidate, changes

    left = deviations(a)
    if left is not None:
        baseline, changes = left
        correction = bounded_sparse(n, changes, b, limit)
        constant = baseline * sum(b) % P
    else:
        right = deviations(b)
        if right is None:
            return None
        baseline, changes = right
        correction = bounded_sparse(n, a, changes, limit)
        constant = baseline * sum(a) % P
    return [(constant + value) % P for value in correction]


def parity_structured(n, a, b):
    """Convolve any function constant on each parity class with its partner.

    Parity is computed from permutation inversions, independently of the
    subgroup transform. A mismatch in either direction disqualifies a shape;
    other valid inputs remain outside this reference's full-range coverage.
    """
    matches = [True, True]
    class_values = [[None, None], [None, None]]
    parity = bytearray()
    for index, permutation in enumerate(permutations(range(n))):
        odd = sum(permutation[i] > permutation[j]
                  for i in range(n) for j in range(i+1, n)) & 1
        parity.append(odd)
        for side, value in enumerate((a[index], b[index])):
            if class_values[side][odd] is None:
                class_values[side][odd] = value
            elif class_values[side][odd] != value:
                matches[side] = False
        if not any(matches):
            return None
    side = 0 if matches[0] else 1
    even_value = class_values[side][0]
    odd_value = class_values[side][1] or 0  # S_1 has no odd permutations.
    other = b if side == 0 else a
    even_sum = sum(value for odd, value in zip(parity, other) if not odd) % P
    odd_sum = sum(value for odd, value in zip(parity, other) if odd) % P
    even_result = (even_value * even_sum + odd_value * odd_sum) % P
    odd_result = (even_value * odd_sum + odd_value * even_sum) % P
    return [odd_result if odd else even_result for odd in parity]


def coordinate_structured(n, a, b):
    """Recognize a(p)=p[i]+1 and b(p)=p[j]+1, for i,j in {0,1}."""
    if n < 2:
        return None
    matches_a = [True, True]
    matches_b = [True, True]
    coordinates = bytearray()
    for index, permutation in enumerate(permutations(range(n))):
        coordinates.extend((permutation[0], permutation[1]))
        for position in range(2):
            expected_value = permutation[position]+1
            matches_a[position] = matches_a[position] and a[index] == expected_value
            matches_b[position] = matches_b[position] and b[index] == expected_value
        if not any(matches_a) or not any(matches_b):
            return None
    left_index = matches_a.index(True)
    right_index = matches_b.index(True)
    total_images = n*(n+1)//2
    remaining_positions = total_images-(left_index+1)
    fixed_count, paired_count = factorial(n-1), factorial(n-2)
    return [
        (fixed_count*(coordinates[2*index+right_index]+1)*(left_index+1)
         + paired_count*(total_images-(coordinates[2*index+right_index]+1))
         * remaining_positions) % P
        for index in range(factorial(n))
    ]


def structured(n, a, b):
    """Return a closed-form convolution, or None for an unhandled shape."""
    count = factorial(n)
    left = sparse_support(a)
    right = sparse_support(b)
    if left == (-1, 0) or right == (-1, 0):
        return [0] * count
    if all(value == a[0] for value in a):
        return [(a[0]*sum(b)) % P] * count
    if all(value == b[0] for value in b):
        return [(b[0]*sum(a)) % P] * count
    if left is None and right is None:
        sparse_result = bounded_sparse(n, a, b)
        if sparse_result is not None:
            return sparse_result
        near_constant_result = near_constant_structured(n, a, b)
        if near_constant_result is not None:
            return near_constant_result
        parity_result = parity_structured(n, a, b)
        return parity_result if parity_result is not None else coordinate_structured(n, a, b)
    facts = [factorial(i) for i in range(n+1)]
    order = permutations(range(n))
    support_index = left[0] if left is not None else right[0]
    support = next(p for i, p in enumerate(order) if i == support_index)
    result = [0] * count
    for index, other in enumerate(permutations(range(n))):
        if left is not None:
            target = tuple(support[other[i]] for i in range(n))
            result[lex_rank(target, facts)] = left[1]*b[index] % P
        else:
            target = tuple(other[support[i]] for i in range(n))
            result[lex_rank(target, facts)] = right[1]*a[index] % P
    return result


def expected(values, output_capacity, *, input_is_null=False, output_is_null=False,
             input_length=None):
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        raise ValueError("null flags must be boolean")
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or not 1 <= len(values) <= MAX_PARSEABLE_WORDS
            or type(values[0]) is not int or not 1 <= values[0] <= 9):
        return -1, b""
    n = values[0]
    count = factorial(n)
    if (len(values) != 1+2*count
            or any(type(value) is not int or not 0 <= value < P for value in values[1:])):
        return -1, b""
    if output_is_null:
        return -2, b""
    if type(output_capacity) is not int or output_capacity < 0:
        raise ValueError("output capacity must be nonnegative")
    if output_capacity < 4*count:
        return -2, b""
    a, b = values[1:1+count], values[1+count:]
    if n > 5:
        coefficients = structured(n, a, b)
        if coefficients is None:
            raise NotImplementedError("large unstructured convolution has no independent reference")
    else:
        coefficients = convolve(n, a, b)
    return 4*count, b"".join(value.to_bytes(4, "little") for value in coefficients)
