"""Heap/Fraction reference independent of the array-based primary oracle."""

from fractions import Fraction
from heapq import heappop, heappush

MIN_ALPHABET_SIZE = 2
MAX_ALPHABET_SIZE = 4
MIN_CODE_BITS = 2
MAX_CODE_BITS = 4
MAX_WEIGHT_SUM = 8
MAX_PARSEABLE_INPUT_LENGTH = 7
MAX_LEAVES = 16
MAX_S = 15 * (8**16)
RESULT_FACTOR = MAX_S + 1
MAX_RESULT = MAX_LEAVES * RESULT_FACTOR + MAX_S


def _decode(values):
    if values is None:
        return None
    try:
        size = len(values)
        if size < MIN_ALPHABET_SIZE + 2 or size > MAX_PARSEABLE_INPUT_LENGTH:
            return None
        alphabet_size, code_bits = values[0], values[1]
        if size != alphabet_size + 2:
            return None
        weights = list(values[2:])
    except (IndexError, KeyError, TypeError, ValueError, OverflowError):
        return None
    if isinstance(alphabet_size, bool) or not isinstance(alphabet_size, int):
        return None
    if isinstance(code_bits, bool) or not isinstance(code_bits, int):
        return None
    if not MIN_ALPHABET_SIZE <= alphabet_size <= MAX_ALPHABET_SIZE:
        return None
    if not MIN_CODE_BITS <= code_bits <= MAX_CODE_BITS:
        return None
    if len(weights) != alphabet_size:
        return None
    if any(isinstance(weight, bool) or not isinstance(weight, int) or weight <= 0 for weight in weights):
        return None
    if sum(weights) > MAX_WEIGHT_SUM:
        return None
    return alphabet_size, code_bits, weights


def _target(alphabet_size, code_bits):
    cap = 1 << code_bits
    return cap - ((cap - 1) % (alphabet_size - 1))


def _heap_construction(alphabet_size, code_bits, weights):
    total = sum(weights)
    target = _target(alphabet_size, code_bits)
    leaves = []
    for symbol, weight in enumerate(weights):
        heappush(leaves, (-Fraction(weight, total), (symbol,), weight))
    internals = [((), 1)]
    leaf_count = alphabet_size
    while leaf_count < target:
        _, phrase, product = heappop(leaves)
        internals.append((phrase, product))
        for symbol, weight in enumerate(weights):
            child_phrase = phrase + (symbol,)
            child_product = product * weight
            heappush(leaves, (-Fraction(child_product, total ** len(child_phrase)), child_phrase, child_product))
        leaf_count += alphabet_size - 1
    scaled_expectation = sum(
        product * total ** (16 - len(phrase))
        for phrase, product in internals
    )
    result = target * RESULT_FACTOR + scaled_expectation
    return result if scaled_expectation <= MAX_S and result <= MAX_RESULT else -1


def expected_result(values, input_is_null=False, input_length=None):
    if not isinstance(input_is_null, bool):
        return -1
    if input_length is not None and (isinstance(input_length, bool) or not isinstance(input_length, int)):
        return -1
    if input_is_null or values is None:
        return -1
    try:
        actual_length = len(values)
    except (TypeError, ValueError, OverflowError):
        return -1
    length = actual_length if input_length is None else input_length
    if length < 0 or length > MAX_PARSEABLE_INPUT_LENGTH or length != actual_length:
        return -1
    parsed = _decode(values)
    if parsed is None:
        return -1
    return _heap_construction(*parsed)


def expected(values):
    return expected_result(values)
