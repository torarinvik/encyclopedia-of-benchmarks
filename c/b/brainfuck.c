/* Interpret a bounded Brainfuck byte program with portable limits. */
#include <stddef.h>
#include <stdint.h>

#define MAX_PROGRAM 2048
#define MAX_INPUT 1024
#define MAX_OUTPUT 8192
#define MAX_STEPS 100000
#define TAPE_CELLS 257

int64_t brainfuck(const int64_t *values, size_t length,
                  uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2 || length > MAX_PROGRAM + MAX_INPUT + 2) return -2;
    if (values[0] < 0 || values[0] > MAX_PROGRAM) return -2;
    const size_t program_length = (size_t)values[0];
    const size_t input_length_index = program_length + 1;
    if (length <= input_length_index || values[input_length_index] < 0
        || values[input_length_index] > MAX_INPUT) return -2;
    const size_t input_length = (size_t)values[input_length_index];
    if (length != program_length + input_length + 2) return -2;

    int32_t matching[MAX_PROGRAM];
    size_t openings[MAX_PROGRAM];
    for (size_t index = 0; index < program_length; ++index) {
        matching[index] = -1;
        const int64_t byte = values[index + 1];
        if (byte < 32 || byte > 126) return -2;
    }
    size_t depth = 0;
    for (size_t index = 0; index < program_length; ++index) {
        const int64_t byte = values[index + 1];
        if (byte == '[') {
            openings[depth++] = index;
        } else if (byte == ']') {
            if (depth == 0) return -2;
            const size_t opening = openings[--depth];
            matching[opening] = (int32_t)index;
            matching[index] = (int32_t)opening;
        }
    }
    if (depth != 0) return -2;
    for (size_t index = 0; index < input_length; ++index) {
        const int64_t byte = values[input_length_index + 1 + index];
        if (byte < 0 || byte > 255) return -2;
    }

    uint8_t tape[TAPE_CELLS] = {0};
    uint8_t scratch[MAX_OUTPUT];
    size_t data_pointer = TAPE_CELLS / 2;
    size_t input_index = 0;
    size_t instruction = 0;
    size_t steps = 0;
    size_t output_length = 0;
    while (instruction < program_length) {
        if (++steps > MAX_STEPS) return -2;
        const int64_t command = values[instruction + 1];
        if (command == '.') {
            if (output_length == MAX_OUTPUT) return -2;
            scratch[output_length++] = tape[data_pointer];
        } else if (command == ',') {
            tape[data_pointer] = input_index < input_length
                ? (uint8_t)values[input_length_index + 1 + input_index++] : 0;
        } else if (command == '>') {
            if (++data_pointer >= TAPE_CELLS) return -2;
        } else if (command == '<') {
            if (data_pointer == 0) return -2;
            --data_pointer;
        } else if (command == '+') {
            tape[data_pointer] = (uint8_t)(tape[data_pointer] + 1u);
        } else if (command == '-') {
            tape[data_pointer] = (uint8_t)(tape[data_pointer] - 1u);
        } else if (command == '[' && tape[data_pointer] == 0) {
            instruction = (size_t)matching[instruction];
        } else if (command == ']' && tape[data_pointer] != 0) {
            instruction = (size_t)matching[instruction];
        }
        ++instruction;
    }
    if (output_length > output_capacity || (output_length != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < output_length; ++index) output[index] = scratch[index];
    return (int64_t)output_length;
}
