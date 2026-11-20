"""Primary mask-layer BFS reference for minimum parenthesis repair."""

from __future__ import annotations

MAX_TEXT_LENGTH = 16
MAX_PARENTHESIS_COUNT = 8
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 2 + (1 << MAX_PARENTHESIS_COUNT) * (MAX_TEXT_LENGTH + 1)
WORKSPACE_BYTES = 8192
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _decode(values, input_is_null: bool, input_length: int | None):
    if type(input_is_null) is not bool:
        return None
    if input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values):
        return None
    n = values[0]
    if type(n) is not int or not 0 <= n <= MAX_TEXT_LENGTH or len(values) != n + 1:
        return None
    text = bytearray()
    parens = 0
    for value in values[1:]:
        if value in (40, 41):
            parens += 1
        elif not 97 <= value <= 122:
            return None
        text.append(value)
    if parens > MAX_PARENTHESIS_COUNT:
        return None
    return bytes(text), parens


def _balanced(candidate: bytes) -> bool:
    depth = 0
    for byte in candidate:
        if byte == 40:
            depth += 1
        elif byte == 41:
            depth -= 1
            if depth < 0:
                return False
    return depth == 0


def _encode(results: list[bytes]) -> bytes:
    output = bytearray(len(results).to_bytes(2, "little"))
    for item in sorted(set(results)):
        output.append(len(item))
        output.extend(item)
    return bytes(output)


def _solve(text: bytes, paren_count: int) -> bytes:
    positions = [i for i, byte in enumerate(text) if byte in (40, 41)]
    limit = 1 << paren_count
    for removed_count in range(paren_count + 1):
        results: set[bytes] = set()
        for mask in range(limit):
            if mask.bit_count() != removed_count:
                continue
            removed = [False] * len(text)
            for ordinal, position in enumerate(positions):
                if mask & (1 << ordinal):
                    removed[position] = True
            candidate = bytes(byte for i, byte in enumerate(text) if not removed[i])
            if _balanced(candidate):
                results.add(candidate)
        if results:
            return _encode(list(results))
    return _encode([b""])


def expected_output(values: list[int] | tuple[int, ...] | None,
                    output_capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT, b""
    if (type(output_capacity) is not int or output_capacity < 0
            or type(output_is_null) is not bool):
        return INVALID_RESULT, b""
    output = _solve(*decoded)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or output_capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), output
