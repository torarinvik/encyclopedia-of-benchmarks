"""Bounded oracle for the EEMBC-derived numeric token FSM kernel."""

from __future__ import annotations

import struct
from typing import Sequence

START, INVALID, S1, S2, INT, FLOAT, EXPONENT, SCIENTIFIC = range(8)
STATES = 8
MAX_TEXT = 96
MAX_PARSEABLE_INPUT_LENGTH = MAX_TEXT + 3
MAX_OUTPUT_BYTES = 64
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _scan(text: bytes, transitions: list[int]) -> list[int]:
    finals = [0] * STATES
    pos = 0
    while pos < len(text):
        state = START
        while pos < len(text) and state != INVALID:
            ch = text[pos]
            if ch == ord(','):
                pos += 1
                break
            digit = ord('0') <= ch <= ord('9')
            if state == START:
                if digit: state = INT
                elif ch in (ord('+'), ord('-')): state = S1
                elif ch == ord('.'): state = FLOAT
                else: state = INVALID; transitions[INVALID] += 1
                transitions[START] += 1
            elif state == S1:
                if digit: state = INT
                elif ch == ord('.'): state = FLOAT
                else: state = INVALID
                transitions[S1] += 1
            elif state == INT:
                if ch == ord('.'): state = FLOAT; transitions[INT] += 1
                elif not digit: state = INVALID; transitions[INT] += 1
            elif state == FLOAT:
                if ch in (ord('e'), ord('E')): state = S2; transitions[FLOAT] += 1
                elif not digit: state = INVALID; transitions[FLOAT] += 1
            elif state == S2:
                if ch in (ord('+'), ord('-')): state = EXPONENT
                else: state = INVALID
                transitions[S2] += 1
            elif state == EXPONENT:
                if digit: state = SCIENTIFIC
                else: state = INVALID
                transitions[EXPONENT] += 1
            elif state == SCIENTIFIC:
                if not digit: state = INVALID; transitions[INVALID] += 1
            pos += 1
        finals[state] += 1
    return finals


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if (input_is_null or values is None or not isinstance(values, (list, tuple))
            or len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))):
        return INVALID_RESULT, b""
    if any(type(v) is not int or not -(2**63) <= v < 2**63 for v in values):
        return -1, b""
    n, step, seed = values[:3]
    if n < 1 or n > MAX_TEXT or len(values) != n + 3 or step < 1 or step > 16 or seed < 1 or seed > 255:
        return -1, b""
    raw = values[3:]
    if any(ch < 32 or ch > 126 for ch in raw) or raw[0] == ord(',') or raw[-1] == ord(','):
        return -1, b""
    if any(raw[i] != ord(',') and (raw[i] ^ seed) in (0, ord(',')) for i in range(0, n, step)):
        return -1, b""
    for i in range(1, n):
        if raw[i] == ord(',') and raw[i-1] == ord(','):
            return -1, b""
    original = bytearray(raw)
    transitions = [0] * STATES
    final = _scan(original, transitions)
    corrupted = bytearray(original)
    for i in range(0, n, step):
        if corrupted[i] != ord(','):
            corrupted[i] ^= seed
    final2 = _scan(corrupted, transitions)
    final = [a + b for a, b in zip(final, final2)]
    for i in range(0, n, step):
        if corrupted[i] != ord(','):
            corrupted[i] ^= seed
    if corrupted != original:
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES):
        return OUTPUT_ERROR, b""
    out = b"".join(struct.pack("<I", x) for pair in zip(final, transitions) for x in pair)
    return len(out), out
