"""Bit-mask verifier for the bounded balanced-parentheses generator."""

from __future__ import annotations

import struct

MAX_INPUT_LENGTH = 1
MAX_PAIRS = 6


def verify(values):
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not 0 <= values[0] <= MAX_PAIRS):
        return -1, b""
    pairs = values[0]
    bit_count = 2 * pairs
    encoded = bytearray()
    count = 0
    for code in range((1 << bit_count) - 1, -1, -1):
        balance = 0
        sequence = bytearray()
        valid = True
        for shift in range(bit_count - 1, -1, -1):
            if (code >> shift) & 1:
                balance += 1
                sequence.append(ord("("))
            else:
                balance -= 1
                sequence.append(ord(")"))
                if balance < 0:
                    valid = False
                    break
        if valid and balance == 0:
            encoded.extend(sequence)
            count += 1
    output = struct.pack("<H", count) + bytes(encoded)
    return len(output), output
