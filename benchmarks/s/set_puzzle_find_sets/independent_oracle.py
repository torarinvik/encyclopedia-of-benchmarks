"""Triple-enumeration reference using direct coordinate comparisons."""

from __future__ import annotations

MAX_PARSEABLE_INPUT_LENGTH = 14
MAX_OUTPUT_BYTES = 536
WORKSPACE_BYTES = 93
MAX_CARDS = 12
DECK_SIZE = 81


def _i64(value: int) -> bytes:
    return value.to_bytes(8, "little", signed=True)


def _features(code: int) -> tuple[int, int, int, int]:
    digits = []
    for _ in range(4):
        digits.append(code % 3)
        code //= 3
    return tuple(digits)  # type: ignore[return-value]


def _forms_set(a: tuple[int, ...], b: tuple[int, ...], c: tuple[int, ...]) -> bool:
    for feature in range(4):
        values = {a[feature], b[feature], c[feature]}
        if len(values) not in (1, 3):
            return False
    return True


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

    features = [_features(code) for code in codes]
    triples = [
        (i, j, k)
        for i in range(count)
        for j in range(i + 1, count)
        for k in range(j + 1, count)
        if _forms_set(features[i], features[j], features[k])
    ]
    output = _i64(len(triples)) + b"".join(_i64(index) for triple in triples for index in triple)
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return -2, b""
    return len(output), output
