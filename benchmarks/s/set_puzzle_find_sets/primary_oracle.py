"""Complement-index reference for bounded Set triple enumeration."""

from __future__ import annotations

MAX_PARSEABLE_INPUT_LENGTH = 14
MAX_OUTPUT_BYTES = 536
WORKSPACE_BYTES = 93
DECK_SIZE = 81
MAX_CARDS = 12


def _i64(value: int) -> bytes:
    return value.to_bytes(8, "little", signed=True)


def _complement(a: int, b: int) -> int:
    result = 0
    place = 1
    for _ in range(4):
        digit_sum = (a // place) % 3 + (b // place) % 3
        result += ((3 - digit_sum % 3) % 3) * place
        place *= 3
    return result


def expected_output(
    input_values: list[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    length = len(input_values) if input_length is None else input_length
    if input_is_null or length != len(input_values) or not 1 <= length <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    count = input_values[0]
    if not 0 <= count <= MAX_CARDS or length != count + 1:
        return -1, b""
    codes = input_values[1:]
    if any(not 0 <= code < DECK_SIZE for code in codes) or len(set(codes)) != count:
        return -1, b""

    index_by_code = [-1] * DECK_SIZE
    for index, code in enumerate(codes):
        index_by_code[code] = index

    triples: list[tuple[int, int, int]] = []
    for i in range(count):
        for j in range(i + 1, count):
            k = index_by_code[_complement(codes[i], codes[j])]
            if k > j:
                triples.append((i, j, k))

    output = _i64(len(triples)) + b"".join(_i64(index) for triple in triples for index in triple)
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return -2, b""
    return len(output), output
