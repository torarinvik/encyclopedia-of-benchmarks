"""Unexecuted byte-ABI reference for quadratic forms over GF(2)."""
from .reduction_reference import reduce_form
from .result_validator import validate

MAX_VALID_INPUT = 201
MAX_PARSEABLE_INPUT = 202
MAX_OUTPUT_BYTES = 1303


def parse(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or not 1 <= input_length <= MAX_PARSEABLE_INPUT
            or any(type(value) is not int or not 0 <= value < (1 << 63)
                   for value in values)
            or not 1 <= values[0] <= 100):
        return None
    n = values[0]
    words = (n + 62) // 63
    if len(values) != 1 + n * words:
        return None
    rows = []
    for i in range(n):
        row = sum(values[1 + i * words + chunk] << (63 * chunk)
                  for chunk in range(words))
        if row >> n or row & ((1 << i) - 1):
            return None
        rows.append(row)
    return n, rows


def expected(values, capacity=MAX_OUTPUT_BYTES, output_is_null=False,
             input_is_null=False, input_length=None):
    parsed = parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    if type(capacity) is not int or capacity < 0 or type(output_is_null) is not bool:
        raise ValueError("invalid reference capacity or null flag")
    n, rows = parsed
    row_bytes = (n + 7) // 8
    needed = 3 + n * row_bytes
    if output_is_null or capacity < needed:
        return -2, b""
    transform, r, s, t = reduce_form(n, rows)
    if not validate(n, rows, transform, r, s, t):
        raise ValueError("constructed normal form failed independent validation")
    payload = bytes((r, s, t)) + b"".join(
        row.to_bytes(row_bytes, "little") for row in transform)
    return needed, payload
