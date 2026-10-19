"""Independent stdout oracle for the bounded Shootout heapsort benchmark."""

MAX_LENGTH = 8192
MIN_LENGTH = 2
MODULUS = 139968
MULTIPLIER = 3877
INCREMENT = 29573
MAX_OUTPUT_BYTES = 9
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _maximum_lcg_state(length: int) -> int:
    state = 42
    maximum = 0
    for _ in range(length):
        state = (state * MULTIPLIER + INCREMENT) % MODULUS
        if state > maximum:
            maximum = state
    return maximum


def expected_output(length: int) -> tuple[int, bytes]:
    """Return the C ``printf("%f\\n")`` line for the generated maximum.

    The source sorts positive values ``state / MODULUS`` and prints the last
    element. Since division by the same positive constant preserves order,
    the maximum LCG state gives the same live-out. Formatting uses integer
    rounding to millionths. After scaling by one million, each exact rational
    has a reduced denominator dividing 2187 (odd), so no generated value is
    exactly halfway between six-decimal outputs.
    """
    if type(length) is not int or not MIN_LENGTH <= length <= MAX_LENGTH:
        return INVALID_RESULT, b""

    maximum_state = _maximum_lcg_state(length)
    millionths = (maximum_state * 1_000_000 + MODULUS // 2) // MODULUS
    whole, fraction = divmod(millionths, 1_000_000)
    output = f"{whole}.{fraction:06d}\n".encode("ascii")
    return len(output), output
