"""Independent register-bit oracle for one three-register A5 majority-clock step."""

from __future__ import annotations

import struct

MAX_OUTPUT_BYTES = 32
WIDTHS = (19, 22, 23)
CLOCK_BITS = (8, 10, 10)
TAPS = ((13, 16, 17, 18), (20, 21), (7, 20, 21, 22))


def expected_output(values: tuple[int, ...] | list[int], capacity: int = MAX_OUTPUT_BYTES) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or len(values) != 3
            or any(type(value) is not int for value in values)):
        return -1, b""
    if any(not 0 <= state < (1 << width) for state, width in zip(values, WIDTHS)):
        return -1, b""
    registers = [[(state >> bit) & 1 for bit in range(width)]
                 for state, width in zip(values, WIDTHS)]
    clocks = [register[index] for register, index in zip(registers, CLOCK_BITS)]
    majority = sum(clocks) >= 2
    output_bit = registers[0][-1] ^ registers[1][-1] ^ registers[2][-1]
    next_states: list[int] = []
    for register, clock, taps in zip(registers, clocks, TAPS):
        if bool(clock) == majority:
            feedback = 0
            for tap in taps:
                feedback ^= register[tap]
            register = [feedback, *register[:-1]]
        next_states.append(sum(bit << index for index, bit in enumerate(register)))
    if capacity < MAX_OUTPUT_BYTES:
        return -2, b""
    output = b"".join(struct.pack("<q", value) for value in (output_bit, *next_states))
    return len(output), output
