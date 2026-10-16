"""Runtime oracle for bounded elementwise matrix addition and subtraction."""
import struct

MAX_INPUT_LENGTH = 517
MAX_OUTPUT_BYTES = 1024


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 5
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    operation, rows_a, cols_a = values[:3]
    if operation not in (0, 1) or not 1 <= rows_a <= 16 or not 0 <= cols_a <= 16 or rows_a * cols_a > 256:
        return -1, b""
    pos_b = 3 + rows_a * cols_a
    if len(values) < pos_b + 2:
        return -1, b""
    rows_b, cols_b = values[pos_b:pos_b + 2]
    if not 1 <= rows_b <= 16 or not 0 <= cols_b <= 16 or rows_b * cols_b > 256:
        return -1, b""
    if len(values) != pos_b + 2 + rows_b * cols_b:
        return -1, b""
    a = values[3:pos_b]
    b = values[pos_b + 2:]
    if any(not -1_000_000 <= x <= 1_000_000 for x in a + b):
        return -1, b""
    if (rows_a, cols_a) != (rows_b, cols_b):
        return -1, b""
    result = [x + y if operation == 0 else x - y for x, y in zip(a, b)]
    payload = b"".join(struct.pack("<i", x) for x in result)
    return len(result), payload
