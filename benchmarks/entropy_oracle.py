"""Independent oracle for the bounded Python entropy benchmark contract."""

from __future__ import annotations

from collections import Counter
import math

MAX_TEXT_LENGTH = 512
ALPHABET = " abcdefghijklmnopqrstuvwxyz"


def expected_result(values: list[int]) -> tuple[int, bytes]:
    """Return the three source-formatted entropy lines, or the invalid sentinel."""
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_TEXT_LENGTH + 1
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return -1, b""

    text_length = values[0]
    codepoints = values[1:]
    if (not 1 <= text_length <= MAX_TEXT_LENGTH or len(codepoints) != text_length
            or any(not 0 <= codepoint <= 127 for codepoint in codepoints)):
        return -1, b""

    text = "".join(chr(codepoint) for codepoint in codepoints)
    single_counts = Counter(text)
    bigram_counts = Counter([" " + text[0],
                             *(text[index:index + 2]
                               for index in range(text_length - 1))])

    single_total = sum(single_counts.values())
    single_sum = 0.0
    for symbol in ALPHABET:
        count = single_counts[symbol]
        if count:
            probability = count / single_total
            single_sum += probability * math.log2(probability)

    bigram_total = sum(bigram_counts.values())
    bigram_sum = 0.0
    for first in ALPHABET:
        for second in ALPHABET:
            count = bigram_counts[first + second]
            if count:
                probability = count / bigram_total
                bigram_sum += probability * math.log2(probability)

    values_to_print = (-single_sum, -bigram_sum, (-bigram_sum) - (-single_sum))
    output = "".join(f"{round(value):.1f}\n" for value in values_to_print).encode("ascii")
    return len(output), output
