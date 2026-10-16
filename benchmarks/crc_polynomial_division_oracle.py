"""Reference for CRC generator-polynomial division over bounded binary arrays."""

from __future__ import annotations

MAX_MESSAGE_BITS = 64
MAX_POLYNOMIAL_BITS = 16
MAX_CODEWORD_BITS = MAX_MESSAGE_BITS + MAX_POLYNOMIAL_BITS - 1
MAX_INPUT_LENGTH = 3 + MAX_CODEWORD_BITS + MAX_POLYNOMIAL_BITS
MAX_OUTPUT_BYTES = MAX_MESSAGE_BITS + MAX_POLYNOMIAL_BITS - 1


def expected_output(values: list[int] | tuple[int, ...],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    operation, raw_message_len, raw_polynomial_len = values[:3]
    maximum_bit_count = MAX_MESSAGE_BITS if operation == 0 else MAX_CODEWORD_BITS
    if (operation not in (0, 1) or not 1 <= raw_message_len <= maximum_bit_count
            or not 2 <= raw_polynomial_len <= MAX_POLYNOMIAL_BITS):
        return -1, b""
    message_len, polynomial_len = raw_message_len, raw_polynomial_len
    if len(values) != 3 + message_len + polynomial_len:
        return -1, b""
    message = list(values[3:3 + message_len])
    polynomial = list(values[3 + message_len:])
    if any(bit not in (0, 1) for bit in message + polynomial):
        return -1, b""
    if polynomial[0] != 1 or polynomial[-1] != 1:
        return -1, b""

    dividend = message.copy()
    if operation == 0:
        dividend.extend([0] * (polynomial_len - 1))
    work = dividend.copy()
    last_division_start = len(work) - polynomial_len
    for offset in range(last_division_start + 1):
        if work[offset] == 1:
            for index, polynomial_bit in enumerate(polynomial):
                work[offset + index] ^= polynomial_bit

    if operation == 0:
        degree = polynomial_len - 1
        remainder = work[-degree:]
        result_bits = message + remainder
    else:
        result_bits = [int(any(work))]
    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return -1, b""
        if output_capacity < len(result_bits):
            return -2, b""
    output = bytes(result_bits)
    return len(output), output
