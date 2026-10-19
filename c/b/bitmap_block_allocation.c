#include <stddef.h>
#include <stdint.h>

#define MAX_BITS 4096
#define MAX_OPS 32
#define MAX_INPUT_LENGTH (2 + 2 * MAX_OPS)
#define MAX_OUTPUT_BYTES (MAX_BITS / 8)

int64_t bitmap_block_allocation(const int64_t *values, size_t length, uint8_t *output, size_t capacity) {
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    int64_t raw_bits = values[0], raw_ops = values[1];
    if (raw_bits < 1 || raw_bits > MAX_BITS || raw_ops < 0 || raw_ops > MAX_OPS ||
        length != 2 + 2 * (size_t)raw_ops) return -1;
    size_t bits = (size_t)raw_bits, ops = (size_t)raw_ops;
    uint16_t offsets[MAX_OPS], runs[MAX_OPS];
    for (size_t i = 0; i < ops; ++i) {
        int64_t offset = values[2 + 2*i], run = values[3 + 2*i];
        if (offset < 0 || (uint64_t)offset > bits || run < 0 || (uint64_t)run > bits - (size_t)offset) return -1;
        offsets[i] = (uint16_t)offset; runs[i] = (uint16_t)run;
    }
    size_t byte_count = (bits + 7) / 8;
    uint8_t bitmap[MAX_OUTPUT_BYTES] = {0};
    for (size_t i = 0; i < bits; ++i) if ((i & 1u) == 0) bitmap[i / 8] |= (uint8_t)(1u << (i % 8));
    for (size_t i = 0; i < ops; ++i) {
        for (size_t j = offsets[i]; j < (size_t)offsets[i] + runs[i]; ++j) {
            uint8_t mask = (uint8_t)(1u << (j % 8));
            if (i % 3 == 0) bitmap[j / 8] |= mask;
            else if (i % 3 == 1) bitmap[j / 8] &= (uint8_t)~mask;
            else bitmap[j / 8] ^= mask;
        }
    }
    if (output == NULL || capacity < byte_count) return -2;
    for (size_t i = 0; i < byte_count; ++i) output[i] = bitmap[i];
    return (int64_t)byte_count;
}
