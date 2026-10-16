"""Oracle for the bounded numeric domain of TheAlgorithms/JavaScript RPN evaluator."""
from __future__ import annotations

import struct

MAX_TOKENS = 64
MAX_OPERAND_MILLI = 1_000_000_000
MAX_VALUES = 1 + 2 * MAX_TOKENS
MAX_PARSEABLE_VALUES = MAX_VALUES + 2
MAX_OUTPUT = 12


def expected_output(values: list[int], output_capacity: int = MAX_OUTPUT) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 1 or len(values) > MAX_PARSEABLE_VALUES
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return -1, b""
    count = values[0]
    if count < 1 or count > MAX_TOKENS or len(values) != 1 + 2 * count:
        return -1, b""
    stack: list[float] = []
    valid = True
    for i in range(count):
        op, payload = values[1 + 2 * i:3 + 2 * i]
        if op == 0:
            if abs(payload) > MAX_OPERAND_MILLI:
                return -1, b""
            stack.append(float(payload) / 1000.0)
        elif op in (1, 2, 3, 4):
            if payload != 0:
                return -1, b""
            if len(stack) < 2:
                valid = False
                break
            right = stack.pop()
            left = stack.pop()
            if op == 1:
                stack.append(left + right)
            elif op == 2:
                stack.append(left - right)
            elif op == 3:
                stack.append(left * right)
            elif right == 0.0:
                valid = False
                break
            else:
                stack.append(left / right)
        else:
            valid = False
            break
    valid = valid and len(stack) == 1
    encoded = (struct.pack("<I", 1) + struct.pack("<d", stack[0])) if valid else struct.pack("<I", 0)
    if output_capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
