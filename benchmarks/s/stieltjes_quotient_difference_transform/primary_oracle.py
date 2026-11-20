"""Direct finite-field quotient-difference rhombus reference."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 998_244_353
MIN_N = 2
MAX_N = 9
MAX_VALID_INPUT_LENGTH = MAX_N + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_N + 1)
WORKSPACE_BYTES = 2 * 5 * 9 * 8


def _encode_i64(value: int) -> bytes:
    return int(value).to_bytes(8, "little", signed=True)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[int]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int for value in values):
        return None
    count = values[0]
    if not MIN_N <= count <= MAX_N or len(values) != count + 1:
        return None
    coefficients = list(values[1:])
    if any(not 1 <= value < MODULUS for value in coefficients):
        return None
    return count, coefficients


def _qd(coefficients: list[int]) -> list[int] | None:
    count = len(coefficients)
    q = [[0] * 9 for _ in range(5)]
    e = [[0] * 9 for _ in range(5)]

    for k in range(count - 1):
        q[1][k] = coefficients[k + 1] * pow(coefficients[k], MODULUS - 2, MODULUS) % MODULUS

    for j in range(1, 5):
        last_e = count - 2 * j - 1
        if last_e < 0:
            break
        for k in range(last_e + 1):
            e[j][k] = (e[j - 1][k + 1] + q[j][k + 1] - q[j][k]) % MODULUS

        last_q = count - 2 * j - 2
        if last_q >= 0:
            for k in range(last_q + 1):
                divisor = e[j][k]
                if divisor == 0:
                    return None
                product = q[j][k + 1] * e[j][k + 1] % MODULUS
                q[j + 1][k] = product * pow(divisor, MODULUS - 2, MODULUS) % MODULUS

    output = [count, coefficients[0]]
    for index in range(1, count):
        if index & 1:
            row = (index + 1) // 2
            output.append(q[row][0])
        else:
            row = index // 2
            output.append(e[row][0])
    return output


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (
            type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if input_length is not None and (
            type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    count, coefficients = parsed
    converted = _qd(coefficients)
    if converted is None:
        return -1, b""
    required = 8 * len(converted)
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return -2, b""
    return required, b"".join(_encode_i64(value) for value in converted)
