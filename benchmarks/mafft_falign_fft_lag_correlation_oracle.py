"""Independent direct oracle for MAFFT's bounded Falign lag profile."""
from __future__ import annotations

import math
from collections.abc import Sequence

MAX_SEQUENCE = 32
MAX_INPUT_LENGTH = 2 + 2 * MAX_SEQUENCE
MAX_OUTPUT_ELEMENTS = 64
INVALID_RESULT = -1
OUTPUT_ERROR = -2
ALPHABET = "ARNDCQEGHILKMFPSTWYV"
ASCII_CODES = {ord(letter): index for index, letter in enumerate(ALPHABET)}
POLARITY = (8.1, 10.5, 11.6, 13.0, 5.5, 10.5, 12.3, 9.0, 10.4, 5.2,
            4.9, 11.3, 5.7, 5.2, 8.0, 9.2, 8.6, 5.4, 6.2, 5.9)
VOLUME = (31.0, 124.0, 56.0, 54.0, 55.0, 85.0, 83.0, 3.0, 96.0, 111.0,
          111.0, 119.0, 105.0, 132.0, 32.5, 32.0, 61.0, 170.0, 136.0, 84.0)


def _payload(values: Sequence[float] | None,
             input_length: int | None) -> tuple[list[int], list[int]] | None:
    if not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) not in (int, float) or not math.isfinite(value)
           or value != math.trunc(value) for value in values):
        return None
    n1, n2 = int(values[0]), int(values[1])
    if not 1 <= n1 <= MAX_SEQUENCE or not 1 <= n2 <= MAX_SEQUENCE:
        return None
    if len(values) != 2 + n1 + n2:
        return None
    codes = [int(value) for value in values[2:]]
    if any(code not in ASCII_CODES for code in codes):
        return None
    return codes[:n1], codes[n1:]


def expected_output(values: Sequence[float] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    """Return the ABI result and output; the direct lag sum is not an FFT."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None
            and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return INVALID_RESULT, []
    if input_is_null:
        if values not in (None, [], ()):
            return INVALID_RESULT, []
        return INVALID_RESULT, []
    if values is None:
        return INVALID_RESULT, []
    sequences = _payload(values, input_length)
    if sequences is None:
        return INVALID_RESULT, []
    if output_is_null:
        return OUTPUT_ERROR, []
    first_codes, second_codes = sequences
    n1, n2 = len(first_codes), len(second_codes)
    n = 1
    while n <= max(n1, n2):
        n *= 2
    if output_capacity is not None and output_capacity < n:
        return OUTPUT_ERROR, []

    mean_p = math.fsum(POLARITY) / len(POLARITY)
    mean_v = math.fsum(VOLUME) / len(VOLUME)
    sd_p = math.sqrt(math.fsum((value - mean_p) ** 2 for value in POLARITY) / len(POLARITY))
    sd_v = math.sqrt(math.fsum((value - mean_v) ** 2 for value in VOLUME) / len(VOLUME))
    features = [((POLARITY[q] - mean_p) / sd_p, (VOLUME[q] - mean_v) / sd_v)
                for q in range(len(ALPHABET))]
    first = [features[ASCII_CODES[code]] for code in first_codes]
    second = [features[ASCII_CODES[code]] for code in second_codes]

    profile: list[float] = []
    for q in range(n):
        lag = q - n // 2
        total = 0.0
        for p in range(n1):
            other = (p + lag) % n
            if other < n2:
                ax, ay = first[p]
                bx, by = second[other]
                total += ax * bx + ay * by
        profile.append(total / n)
    return n, profile


def expected_result(values: Sequence[float] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    return expected_output(values, output_capacity, output_is_null,
                           input_is_null, input_length)[0]
