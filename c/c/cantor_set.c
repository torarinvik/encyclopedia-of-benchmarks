#include <stddef.h>
#include <stdint.h>

#define MAX_LEVEL 6
#define MAX_INTERVALS 64
#define SCALE UINT64_C(1000000)

static int put_byte(uint8_t *output, size_t capacity, size_t *length, uint8_t byte) {
    if (*length >= capacity) return 0;
    output[(*length)++] = byte;
    return 1;
}

static int put_text(uint8_t *output, size_t capacity, size_t *length, const char *text) {
    while (*text) if (!put_byte(output, capacity, length, (uint8_t)*text++)) return 0;
    return 1;
}

static int put_uint(uint8_t *output, size_t capacity, size_t *length, uint64_t value) {
    uint8_t digits[20];
    size_t count = 0;
    do { digits[count++] = (uint8_t)('0' + value % 10); value /= 10; } while (value);
    while (count) if (!put_byte(output, capacity, length, digits[--count])) return 0;
    return 1;
}

static int put_fixed(uint8_t *output, size_t capacity, size_t *length, uint64_t ticks) {
    uint64_t whole = ticks / SCALE;
    uint64_t fraction = ticks % SCALE;
    if (!put_uint(output, capacity, length, whole) || !put_byte(output, capacity, length, '.')) return 0;
    for (uint64_t divisor = 100000; divisor; divisor /= 10) {
        if (!put_byte(output, capacity, length, (uint8_t)('0' + fraction / divisor % 10))) return 0;
    }
    return 1;
}

int64_t cantor_set(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != 3 || input[0] < 0 || input[0] > input[1] || input[1] > 100000 || input[2] < 0 || input[2] > MAX_LEVEL) return -1;
    if (output == NULL) return -2;
    uint64_t start = (uint64_t)input[0], span = (uint64_t)(input[1] - input[0]);
    uint64_t positions[MAX_INTERVALS] = {0}, next[MAX_INTERVALS];
    size_t interval_count = 1, output_length = 0;
    uint64_t denominator = 1;
    for (int level = 0; level <= input[2]; ++level) {
        if (!put_text(output, capacity, &output_length, "Level ") || !put_uint(output, capacity, &output_length, (uint64_t)level) || !put_byte(output, capacity, &output_length, '\t')) return -2;
        for (size_t i = 0; i < interval_count; ++i) {
            uint64_t left_num = start * denominator + span * positions[i];
            uint64_t right_num = start * denominator + span * (positions[i] + 1);
            uint64_t left = (left_num * SCALE + denominator / 2) / denominator;
            uint64_t right = (right_num * SCALE + denominator / 2) / denominator;
            if (!put_text(output, capacity, &output_length, "\t[") || !put_fixed(output, capacity, &output_length, left) ||
                !put_text(output, capacity, &output_length, "] -- [") || !put_fixed(output, capacity, &output_length, right) ||
                !put_byte(output, capacity, &output_length, ']')) return -2;
        }
        if (!put_byte(output, capacity, &output_length, '\n')) return -2;
        if (level < input[2]) {
            if (!put_byte(output, capacity, &output_length, '\n')) return -2;
            for (size_t i = 0; i < interval_count; ++i) { next[2 * i] = positions[i] * 3; next[2 * i + 1] = positions[i] * 3 + 2; }
            interval_count *= 2;
            for (size_t i = 0; i < interval_count; ++i) positions[i] = next[i];
            denominator *= 3;
        }
    }
    if (output_length >= capacity) return -2;
    output[output_length++] = 0;
    return (int64_t)output_length;
}
