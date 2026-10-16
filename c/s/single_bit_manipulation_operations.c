#include <stddef.h>
#include <stdint.h>

int64_t single_bit_manipulation_operations(const int64_t *input, size_t length) {
    if (input == NULL || length != 3) return -1;
    const int64_t opcode = input[0], number = input[1], position = input[2];
    if (opcode < 0 || opcode > 5 || number < INT32_MIN || number > INT32_MAX) return -1;
    if (opcode == 5) {
        if (position != -1) return -1;
        return number & (number - 1);
    }
    if (position < 0 || position > 31) return -1;
    const int64_t mask = INT64_C(1) << position;
    switch (opcode) {
        case 0: return number | mask;
        case 1: return number & ~mask;
        case 2: return number ^ mask;
        case 3: return (int64_t)(((uint64_t)number >> position) & 1u);
        case 4: return (number & mask) != 0;
        default: return -1;
    }
}
