"""Independent oracle for the bounded BEEBS FASTA generator profile."""

from __future__ import annotations

import struct

MAX_SEQUENCE_COUNT = 1_000
MAX_LCG_STATE = 139_967
LCG_MODULUS = 139_968
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 10_245
INVALID_RESULT = -1
OUTPUT_ERROR = -2

ALU = (
    "GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG"
    "GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA"
    "CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT"
    "ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA"
    "GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG"
    "AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC"
    "AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA"
)

IUB = ((0.27, "a"), (0.12, "c"), (0.12, "g"), (0.27, "t"),
       (0.02, "B"), (0.02, "D"), (0.02, "H"), (0.02, "K"),
       (0.02, "M"), (0.02, "N"), (0.02, "R"), (0.02, "S"),
       (0.02, "V"), (0.02, "W"), (0.02, "Y"))
HUMAN = ((0.3029549426680, "a"), (0.1979883004921, "c"),
         (0.1975473066391, "g"), (0.3015094502008, "t"))

HEADERS = (b">ONE Homo sapiens alu\n", b">TWO IUB ambiguity codes\n",
           b">THREE Homo sapiens frequency\n")


def _f32(value: float) -> float:
    return struct.unpack("!f", struct.pack("!f", value))[0]


def _weighted_symbols(weights: tuple[tuple[float, str], ...]) -> tuple[tuple[float, str], ...]:
    cumulative = _f32(0.0)
    result = []
    for weight, symbol in weights:
        cumulative = _f32(cumulative + _f32(weight))
        result.append((cumulative, symbol))
    return tuple(result)


IUB_CUMULATIVE = _weighted_symbols(IUB)
HUMAN_CUMULATIVE = _weighted_symbols(HUMAN)


def _next_random(state: int) -> tuple[int, float]:
    state = (state * 3_877 + 29_573) % LCG_MODULUS
    return state, _f32(_f32(float(state)) / _f32(float(LCG_MODULUS)))


def _pick(cumulative: tuple[tuple[float, str], ...], random_value: float) -> str:
    for threshold, symbol in cumulative:
        if threshold >= random_value:
            return symbol
    return cumulative[-1][1]


def _wrapped_repeat(sequence: str, count: int) -> bytes:
    output = bytearray()
    for start in range(0, count, 60):
        line_length = min(60, count - start)
        for offset in range(line_length):
            output.append(ord(sequence[(start + offset) % len(sequence)]))
        output.append(10)
    return bytes(output)


def _wrapped_random(count: int, state: int,
                    cumulative: tuple[tuple[float, str], ...]) -> tuple[bytes, int]:
    output = bytearray()
    for start in range(0, count, 60):
        line_length = min(60, count - start)
        for _ in range(line_length):
            state, random_value = _next_random(state)
            output.append(ord(_pick(cumulative, random_value)))
        output.append(10)
    return bytes(output), state


def fasta_output_length(count: int) -> int:
    return (sum(map(len, HEADERS)) + 10 * count
            + (2 * count + 59) // 60
            + (3 * count + 59) // 60
            + (5 * count + 59) // 60)


def generate(count: int, initial_state: int) -> bytes:
    state = initial_state
    iub_body, state = _wrapped_random(3 * count, state, IUB_CUMULATIVE)
    human_body, _ = _wrapped_random(5 * count, state, HUMAN_CUMULATIVE)
    return (HEADERS[0] + _wrapped_repeat(ALU, 2 * count)
            + HEADERS[1] + iub_body + HEADERS[2] + human_body)


def expected_output(values: list[int] | tuple[int, ...], capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    """Return generated FASTA bytes, or the ABI error and no bytes."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if (not isinstance(values, (list, tuple))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or len(values) != 2):
        return INVALID_RESULT, b""
    count, initial_state = values
    if not 1 <= count <= MAX_SEQUENCE_COUNT or not 0 <= initial_state <= MAX_LCG_STATE:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    output_length = fasta_output_length(count)
    if output_is_null or (capacity is not None and capacity < output_length):
        return OUTPUT_ERROR, b""
    output = generate(count, initial_state)
    if len(output) != output_length or output_length > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    return output_length, output
