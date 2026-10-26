"""Independent bounded oracle for IJG JPEG optimal Huffman table generation."""

from collections.abc import Sequence

MAX_SYMBOLS = 20
MAX_FREQUENCY = 1_000_000
MAX_INPUT_LENGTH = 1 + 2 * MAX_SYMBOLS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_OUTPUT_BYTES = 17 + MAX_SYMBOLS
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _table(values: Sequence[int], input_length: int | None = None) -> tuple[int, ...] | None:
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int for value in values):
        return None
    count = values[0]
    if not 1 <= count <= MAX_SYMBOLS or len(values) != 1 + 2 * count:
        return None
    records = [(values[1 + 2 * i], values[2 + 2 * i]) for i in range(count)]
    symbols = [symbol for symbol, _ in records]
    if (len(set(symbols)) != count or any(not 0 <= s <= 255 for s in symbols)
            or any(not 1 <= frequency <= MAX_FREQUENCY for _, frequency in records)):
        return None

    # A tree-of-leaf-lists formulation, separate from the source's `others`
    # linked branch representation, reproduces its source-order tie rule.
    active: list[tuple[int, int, list[int]]] = [(frequency, symbol, [symbol])
                                                for symbol, frequency in records]
    active.append((1, 256, [256]))
    code_size = [0] * 257
    while len(active) > 1:
        active.sort(key=lambda item: (item[0], -item[1]))
        f1, root1, leaves1 = active.pop(0)
        f2, root2, leaves2 = active.pop(0)
        for symbol in leaves1:
            code_size[symbol] += 1
        for symbol in leaves2:
            code_size[symbol] += 1
        active.append((f1 + f2, root1, leaves1 + leaves2))

    counts = [0] * 33
    for size in code_size:
        if size:
            if size > 32:
                return None
            counts[size] += 1
    for length in range(32, 16, -1):
        while counts[length] > 0:
            shorter = length - 2
            while shorter >= 0 and counts[shorter] == 0:
                shorter -= 1
            if shorter < 0:
                return None
            counts[length] -= 2
            counts[length - 1] += 1
            counts[shorter + 1] += 2
            counts[shorter] -= 1
    longest = 16
    while longest > 0 and counts[longest] == 0:
        longest -= 1
    if longest == 0:
        return None
    counts[longest] -= 1  # remove pseudo-symbol 256

    # IJG emits symbols in ascending symbol order within their original tree
    # code-size category, after adjusting only the length-count histogram.
    symbols_by_size = [symbol for size in range(1, 33)
                       for symbol in range(256) if code_size[symbol] == size]
    if len(symbols_by_size) != count:
        return None
    return (count, *counts[1:17], *symbols_by_size)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or values is not None and not isinstance(values, (list, tuple))
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None
            and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    result = _table(values, input_length)
    if result is None:
        return INVALID_RESULT, b""
    payload = bytes(result)
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return OUTPUT_ERROR, b""
    return len(payload), payload
