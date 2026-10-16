"""Oracle for the pinned Java MorseCodeConverter morseToText direction."""

from __future__ import annotations

MAX_INPUT_LENGTH = 512
MAX_PARSEABLE_INPUT_LENGTH = 513
MAX_OUTPUT_BYTES = 512
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MORSE = {'A': '.-', 'B': '-...', 'C': '-.-.', 'D': '-..', 'E': '.', 'F': '..-.', 'G': '--.', 'H': '....', 'I': '..', 'J': '.---', 'K': '-.-', 'L': '.-..', 'M': '--', 'N': '-.', 'O': '---', 'P': '.--.', 'Q': '--.-', 'R': '.-.', 'S': '...', 'T': '-', 'U': '..-', 'V': '...-', 'W': '.--', 'X': '-..-', 'Y': '-.--', 'Z': '--..'}
REVERSE_MORSE = {value: key for key, value in MORSE.items()}


def _java_split(text: str, delimiter: str) -> list[str]:
    if text == "":
        return [""]
    parts = text.split(delimiter)
    while parts and parts[-1] == "":
        parts.pop()
    return parts

def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX or not 0 <= value <= 127 for value in values)):
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    text = "".join(chr(value) for value in values)
    output_chars: list[str] = []
    words = _java_split(text, " | ")
    for index, word in enumerate(words):
        for code in _java_split(word, " "):
            output_chars.append(REVERSE_MORSE.get(code, "?"))
        if index < len(words) - 1:
            output_chars.append(" ")
    output = "".join(output_chars).encode("ascii")
    if capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
