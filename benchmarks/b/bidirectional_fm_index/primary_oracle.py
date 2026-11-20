"""Primary paired-BWT reference for exact left/right pattern extension."""

from __future__ import annotations

from collections.abc import Sequence

MIN_TEXT_LENGTH = 0
MAX_TEXT_LENGTH = 64
MAX_OPERATIONS = 64
ALPHABET_SIZE = 4
ALPHABET_WITH_SENTINEL = 5
MAX_VALID_INPUT_LENGTH = 194
MAX_PARSEABLE_INPUT_LENGTH = 195
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[list[int], list[tuple[int, int]]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 2
            or input_length > MAX_PARSEABLE_INPUT_LENGTH or input_length != len(values)):
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63) for word in values):
        return None
    n, q = values[0], values[1]
    if not MIN_TEXT_LENGTH <= n <= MAX_TEXT_LENGTH or not 0 <= q <= MAX_OPERATIONS:
        return None
    if input_length < 2 + n:
        return None
    text = list(values[2:2 + n])
    if any(symbol < 1 or symbol > ALPHABET_SIZE for symbol in text):
        return None
    if input_length != 2 + n + 2 * q:
        return None
    operations: list[tuple[int, int]] = []
    cursor = 2 + n
    for _ in range(q):
        side, symbol = values[cursor], values[cursor + 1]
        cursor += 2
        if side not in (0, 1) or not 1 <= symbol <= ALPHABET_SIZE:
            return None
        operations.append((side, symbol))
    return text, operations


def _suffix_array(text_with_sentinel: list[int]) -> list[int]:
    return sorted(range(len(text_with_sentinel)), key=lambda start: text_with_sentinel[start:])


def _build_index(text: list[int]) -> tuple[list[int], list[int]]:
    terminated = [*text, 0]
    total = len(terminated)
    suffixes = _suffix_array(terminated)
    bwt = [terminated[(start + total - 1) % total] for start in suffixes]
    cumulative = [0] * ALPHABET_WITH_SENTINEL
    seen = 0
    for symbol in range(ALPHABET_WITH_SENTINEL):
        cumulative[symbol] = seen
        seen += terminated.count(symbol)
    return bwt, cumulative


def _rank(bwt: list[int], symbol: int, end: int) -> int:
    return sum(value == symbol for value in bwt[:end])


def _backward_extend(index: tuple[list[int], list[int]],
                     interval: tuple[int, int], symbol: int) -> tuple[int, int]:
    bwt, cumulative = index
    left, right = interval
    return (cumulative[symbol] + _rank(bwt, symbol, left),
            cumulative[symbol] + _rank(bwt, symbol, right))


def _synchronized_extend(index: tuple[list[int], list[int]],
                         source_interval: tuple[int, int], target_start: int,
                         symbol: int) -> tuple[int, int]:
    bwt, _ = index
    left, right = source_interval
    start = target_start
    for smaller in range(symbol):
        start += _rank(bwt, smaller, right) - _rank(bwt, smaller, left)
    count = _rank(bwt, symbol, right) - _rank(bwt, symbol, left)
    return start, start + count


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    text, operations = parsed
    forward = _build_index(text)
    reverse = _build_index(list(reversed(text)))
    total = len(text) + 1
    forward_interval = (0, total)
    reverse_interval = (0, total)
    checksum = 0
    for operation_index, (side, symbol) in enumerate(operations, start=1):
        old_forward = forward_interval
        old_reverse = reverse_interval
        if side == 0:
            forward_interval = _backward_extend(forward, old_forward, symbol)
            reverse_interval = _synchronized_extend(forward, old_forward, old_reverse[0], symbol)
        else:
            reverse_interval = _backward_extend(reverse, old_reverse, symbol)
            forward_interval = _synchronized_extend(reverse, old_reverse, old_forward[0], symbol)
        checksum += operation_index * (forward_interval[1] - forward_interval[0])
    return checksum
