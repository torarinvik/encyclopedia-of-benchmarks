#include <stddef.h>
#include <stdint.h>

#define MAX_PAIRS 10
#define MAX_INPUT_LENGTH 21
#define MAX_OUTPUT_BYTES 20

int64_t balanced_parenthesis_successor(const int64_t *input, size_t length,
    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t pairs_value = input[0];
    if (pairs_value < 1 || pairs_value > MAX_PAIRS) return -1;
    const size_t pairs = (size_t)pairs_value;
    const size_t sequence_length = 2 * pairs;
    if (length != 1 + sequence_length) return -1;
    uint8_t symbols[MAX_OUTPUT_BYTES];
    int balance = 0;
    for (size_t i = 0; i < sequence_length; ++i) {
        const int64_t symbol = input[1 + i];
        if (symbol != 0 && symbol != 1) return -1;
        symbols[i] = (uint8_t)symbol;
        balance += symbol == 0 ? 1 : -1;
        if (balance < 0) return -1;
    }
    if (balance != 0) return -1;
    if (output == NULL || capacity < sequence_length) return -2;

    uint8_t staged[MAX_OUTPUT_BYTES];
    int reverse_depth = 0;
    for (size_t cursor = sequence_length; cursor > 0; --cursor) {
        const size_t i = cursor - 1;
        if (symbols[i] == 0) --reverse_depth;
        else ++reverse_depth;
        if (symbols[i] == 0 && reverse_depth > 0) {
            --reverse_depth;
            const size_t suffix_length = sequence_length - i - 1;
            const size_t opening_count = (size_t)((int)suffix_length - reverse_depth) / 2;
            const size_t closing_count = suffix_length - opening_count;
            for (size_t j = 0; j < i; ++j) staged[j] = symbols[j] == 0 ? '(' : ')';
            staged[i] = ')';
            size_t position = i + 1;
            for (size_t j = 0; j < opening_count; ++j) staged[position++] = '(';
            for (size_t j = 0; j < closing_count; ++j) staged[position++] = ')';
            for (size_t j = 0; j < sequence_length; ++j) output[j] = staged[j];
            return (int64_t)sequence_length;
        }
    }
    return -3;
}
