"""Bounded portable oracle for the Brainfuck bytecode interpreter benchmark."""

from __future__ import annotations

I64_MIN, I64_MAX = -(2**63), 2**63 - 1
MAX_PROGRAM_LENGTH = 2048
MAX_INPUT_BYTES = 1024
MAX_INPUT_LENGTH = MAX_PROGRAM_LENGTH + MAX_INPUT_BYTES + 2
MAX_OUTPUT_BYTES = 8192
MAX_STEPS = 100_000
TAPE_RADIUS = 128


def expected_output(values: list[int]) -> tuple[int, bytes]:
    """Interpret one packed program/input pair, returning output bytes or -2."""
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -2, b""
    program_length = values[0]
    if not 0 <= program_length <= MAX_PROGRAM_LENGTH or len(values) < program_length + 2:
        return -2, b""
    program = values[1:1 + program_length]
    input_length_index = 1 + program_length
    input_length = values[input_length_index]
    if (not 0 <= input_length <= MAX_INPUT_BYTES
            or len(values) != input_length_index + input_length + 1
            or any(not 32 <= byte <= 126 for byte in program)
            or any(not 0 <= byte <= 255 for byte in values[input_length_index + 1:])):
        return -2, b""

    matching = [-1] * program_length
    stack: list[int] = []
    for position, command in enumerate(program):
        if command == ord("["):
            stack.append(position)
        elif command == ord("]"):
            if not stack:
                return -2, b""
            opening = stack.pop()
            matching[opening] = position
            matching[position] = opening
    if stack:
        return -2, b""

    tape = [0] * (2 * TAPE_RADIUS + 1)
    pointer = TAPE_RADIUS
    input_index = input_length_index + 1
    instruction = 0
    steps = 0
    output = bytearray()
    while instruction < program_length:
        steps += 1
        if steps > MAX_STEPS:
            return -2, b""
        command = program[instruction]
        if command == ord("."):
            output.append(tape[pointer])
            if len(output) > MAX_OUTPUT_BYTES:
                return -2, b""
        elif command == ord(","):
            tape[pointer] = values[input_index] if input_index < len(values) else 0
            if input_index < len(values):
                input_index += 1
        elif command == ord(">"):
            pointer += 1
            if pointer > 2 * TAPE_RADIUS:
                return -2, b""
        elif command == ord("<"):
            pointer -= 1
            if pointer < 0:
                return -2, b""
        elif command == ord("+"):
            tape[pointer] = (tape[pointer] + 1) & 255
        elif command == ord("-"):
            tape[pointer] = (tape[pointer] - 1) & 255
        elif command == ord("[") and tape[pointer] == 0:
            instruction = matching[instruction]
        elif command == ord("]") and tape[pointer] != 0:
            instruction = matching[instruction]
        instruction += 1
    return len(output), bytes(output)
