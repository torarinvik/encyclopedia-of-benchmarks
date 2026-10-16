"""Independent oracle for the bounded MATLAB binary-digit complement."""

from __future__ import annotations

MAX_BINARY_DIGIT_NUMERAL = 1_111_111_111_111_111
INVALID_RESULT = -1


def expected_result(value: int) -> int:
    """Return the decimal numeral for the fixed-width two's-complement bits."""
    if type(value) is not int or not 0 <= value <= MAX_BINARY_DIGIT_NUMERAL:
        return INVALID_RESULT
    bits = str(value)
    if any(bit not in "01" for bit in bits):
        return INVALID_RESULT
    if value == 0:
        return 0

    least_significant_one = bits.rfind("1")
    complemented_prefix = "".join("1" if bit == "0" else "0"
                                  for bit in bits[:least_significant_one])
    return int(complemented_prefix + bits[least_significant_one:])
