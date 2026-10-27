"""Primary bounded FM-index display profile using sampled ISA plus LF walks."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT = 32
MAX_INPUT_LENGTH = 36
MAX_OUTPUT_BYTES = 32


def _parse(values: Sequence[int] | None) -> tuple[list[int], int, int, int] | None:
    if (not isinstance(values, (list, tuple)) or not 5 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_TEXT or len(values) != n + 4:
        return None
    text = list(values[1:n + 1])
    left, right, stride = values[n + 1:n + 4]
    if (any(not 1 <= x <= 4 for x in text) or not 0 <= left <= right < n
            or not 1 <= stride <= n):
        return None
    return text, left, right, stride


def _display_from_sample(text: list[int], left: int, right: int, stride: int) -> bytes:
    # The terminal sentinel position is retained as a sample even when n is not
    # divisible by stride, so every display endpoint has a sample strictly after it.
    terminated = text + [0]
    size = len(terminated)
    suffix_array = sorted(range(size), key=lambda pos: terminated[pos:])
    inverse = [0] * size
    for row, pos in enumerate(suffix_array):
        inverse[pos] = row
    bwt = [terminated[(pos - 1) % size] for pos in suffix_array]

    frequencies = [0] * 5
    for symbol in bwt:
        frequencies[symbol] += 1
    first = [0] * 5
    for symbol in range(1, 5):
        first[symbol] = first[symbol - 1] + frequencies[symbol - 1]
    seen = [0] * 5
    lf = [0] * size
    for row, symbol in enumerate(bwt):
        lf[row] = first[symbol] + seen[symbol]
        seen[symbol] += 1

    sample_positions = {pos for pos in range(len(text)) if (pos + 1) % stride == 0}
    sample_positions.add(len(text))
    sampled_isa = {pos: inverse[pos] for pos in sample_positions}
    sample = ((right + 1) // stride + 1) * stride - 1
    if sample > len(text):
        sample = len(text)
    if sample not in sampled_isa or sample <= right:
        raise AssertionError("bounded display sample is missing or not after the endpoint")
    row = sampled_isa[sample]
    current = sample
    while current > right + 1:
        row = lf[row]
        current -= 1

    reversed_symbols: list[int] = []
    while current > left:
        reversed_symbols.append(bwt[row])
        row = lf[row]
        current -= 1
    return bytes(reversed(reversed_symbols))


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    text, left, right, stride = parsed
    output = _display_from_sample(text, left, right, stride)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
