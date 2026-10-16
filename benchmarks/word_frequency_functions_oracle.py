"""Independent oracle for the four pinned Python word-frequency routines."""
from __future__ import annotations

import math
import struct

MAX_TERM = 128
MAX_TEXT = 4096
MAX_COUNT = 1_000_000
MAX_INPUT = 1 + 1 + MAX_TERM + 1 + MAX_TEXT
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT + 1
MAX_OUTPUT_BYTES = 20
PUNCTUATION = set(b"!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~")


def _pack(kind: int, *values: int) -> bytes:
    return struct.pack("<I", kind) + b"".join(struct.pack("<q", value) for value in values)


def expected_output(values: list[int], output_capacity: int = MAX_OUTPUT_BYTES) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 1 or len(values) > MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return -1, b""
    operation = values[0]
    if operation in (0, 1):
        if len(values) < 3:
            return -1, b""
        term_len = values[1]
        if term_len < 0 or term_len > MAX_TERM or len(values) < 3 + term_len:
            return -1, b""
        text_len_index = 2 + term_len
        text_len = values[text_len_index]
        if text_len < 0 or text_len > MAX_TEXT or len(values) != text_len_index + 1 + text_len:
            return -1, b""
        term_values = values[2:text_len_index]
        text_values = values[text_len_index + 1:]
        if any(not 0 <= b <= 127 for b in term_values + text_values):
            return -1, b""
        term = bytes(term_values).lower()
        text = bytes(text_values)
        if operation == 0:
            cleaned = bytes(b for b in text if b not in PUNCTUATION and b != 10)
            tokens = cleaned.split(b" ")
            answer = sum(token.lower() == term for token in tokens)
            encoded = _pack(0, answer)
        else:
            cleaned = bytes(b for b in text.lower() if b not in PUNCTUATION)
            documents = cleaned.split(b"\n")
            answer = sum(term in document for document in documents)
            encoded = _pack(1, answer, len(documents))
    elif operation == 2:
        if len(values) != 4:
            return -1, b""
        df, n, smoothing = values[1:]
        if not 0 <= df <= MAX_COUNT or not 0 <= n <= MAX_COUNT or smoothing not in (0, 1):
            return -1, b""
        if smoothing:
            if n == 0:
                encoded = _pack(4)
            else:
                result = 1 + math.log10(n / (1 + df))
                encoded = _pack(2, int(round(round(result, 3) * 1000)))
        elif df == 0:
            encoded = _pack(3)
        elif n == 0:
            encoded = _pack(4)
        else:
            result = math.log10(n / df)
            encoded = _pack(2, int(round(round(result, 3) * 1000)))
    elif operation == 3:
        if len(values) != 3:
            return -1, b""
        tf, idf_milli = values[1:]
        if not 0 <= tf <= MAX_COUNT or not -MAX_COUNT <= idf_milli <= MAX_COUNT:
            return -1, b""
        encoded = _pack(2, tf * idf_milli)
    else:
        return -1, b""
    if output_capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
