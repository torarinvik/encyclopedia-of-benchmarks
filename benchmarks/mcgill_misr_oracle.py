"""Independent oracle for the bounded McGill MISR benchmark."""

from __future__ import annotations

MIN_EXPERIMENTS = 1
MAX_EXPERIMENTS = 1_000
MAX_OUTPUT_BYTES = 123
INVALID_RESULT = -1
OUTPUT_ERROR = -2
MASK_48 = (1 << 48) - 1


def _next_lrand48(state: int) -> tuple[int, int]:
    state = (0x5DEECE66D * state + 0xB) & MASK_48
    return state, state >> 17


def _different_experiment(state: int, free: list[int]) -> tuple[int, list[int], bool]:
    faulty = free.copy()

    # The default structure is "1000000000". Its first tap contributes the
    # old head bit to the feedback value; the remaining nine positions do not.
    for _ in range(10):
        saved_free = free[0]
        saved_faulty = faulty[0]
        state, random_word = _next_lrand48(state)
        for cell in range(9):
            free[cell] = (free[cell + 1] + random_word) & 1
            state, random_probability = _next_lrand48(state)
            if random_probability % 1000 < 250:
                random_word ^= 1
            faulty[cell] = (faulty[cell + 1] + random_word) & 1
            random_word >>= 1

        state, random_word = _next_lrand48(state)
        free[9] = (saved_free + random_word) & 1
        state, random_probability = _next_lrand48(state)
        if random_probability % 10_000 < 2_500:
            random_word ^= 1
        faulty[9] = (saved_faulty + random_word) & 1

    return state, free, free != faulty


def _format_probability(same_count: int, experiments: int) -> str:
    # Match printf("%.8e") with integer rounding, independent of the ports'
    # floating-point formatting libraries.
    if same_count == 0:
        return "0.00000000e+00"

    scale = 1
    exponent = 0
    while same_count * scale < experiments:
        scale *= 10
        exponent -= 1

    numerator = same_count * scale * 100_000_000
    mantissa, remainder = divmod(numerator, experiments)
    doubled_remainder = 2 * remainder
    if doubled_remainder > experiments or (
        doubled_remainder == experiments and mantissa % 2 == 1
    ):
        mantissa += 1
    if mantissa == 1_000_000_000:
        mantissa = 100_000_000
        exponent += 1

    whole, fraction = divmod(mantissa, 100_000_000)
    sign = "+" if exponent >= 0 else "-"
    return f"{whole}.{fraction:08d}e{sign}{abs(exponent):02d}"


def expected_output(experiments: int) -> tuple[int, bytes]:
    """Return the source's two-line report for a bounded experiment count."""
    if type(experiments) is not int or not MIN_EXPERIMENTS <= experiments <= MAX_EXPERIMENTS:
        return INVALID_RESULT, b""

    state = 1  # seed48({1, 0, 0}) in the pinned POSIX build
    free = [0] + [1] * 9  # root cell is zeroed; allocated following cells are one
    different_count = 0
    for _ in range(experiments):
        state, free, different = _different_experiment(state, free)
        if different:
            different_count += 1

    same_probability = _format_probability(experiments - different_count, experiments)
    output = (
        "reg_len #_vect prob #_tms struct seed1 seed2 seed3 Prob same output\n "
        f"10 10 2.500e-01 {experiments} 1000000000 1 0 0 {same_probability}\n"
    ).encode("ascii")
    return len(output), output
