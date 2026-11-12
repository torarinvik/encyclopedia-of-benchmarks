#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 64
#define MAX_INSERTIONS 16
#define MAX_INPUT_VALUES (1 + 2 * MAX_OPERATIONS)
#define MAX_OUTPUT_BYTES (8 * MAX_OPERATIONS)
#define BIT_COUNT 63

static void insert_value(uint64_t basis[BIT_COUNT], uint64_t value) {
    for (int bit = BIT_COUNT - 1; bit >= 0 && value != 0; --bit) {
        if (((value >> bit) & UINT64_C(1)) == 0) continue;
        if (basis[bit] == 0) {
            basis[bit] = value;
            return;
        }
        value ^= basis[bit];
    }
}

static uint64_t maximum_value(const uint64_t basis[BIT_COUNT]) {
    uint64_t best = 0;
    for (int bit = BIT_COUNT - 1; bit >= 0; --bit) {
        const uint64_t candidate = best ^ basis[bit];
        if (candidate > best) best = candidate;
    }
    return best;
}

static int contains_value(const uint64_t basis[BIT_COUNT], uint64_t value) {
    for (int bit = BIT_COUNT - 1; bit >= 0; --bit) {
        if (((value >> bit) & UINT64_C(1)) == 0) continue;
        if (basis[bit] == 0) return 0;
        value ^= basis[bit];
    }
    return value == 0;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t xor_linear_basis(const int64_t *input, size_t length,
                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t operation_count_value = input[0];
    if (operation_count_value < 1 || operation_count_value > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)operation_count_value;

    uint64_t basis[BIT_COUNT] = {0};
    int64_t results[MAX_OPERATIONS];
    size_t result_count = 0, cursor = 1, insertion_count = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        if (cursor >= length) return -1;
        const int64_t kind = input[cursor++];
        if (kind == 0 || kind == 2) {
            if (cursor >= length) return -1;
            const int64_t raw_value = input[cursor++];
            if (raw_value < 0) return -1;
            const uint64_t value = (uint64_t)raw_value;
            if (kind == 0) {
                if (++insertion_count > MAX_INSERTIONS) return -1;
                insert_value(basis, value);
            } else {
                results[result_count++] = contains_value(basis, value) ? 1 : 0;
            }
        } else if (kind == 1) {
            results[result_count++] = (int64_t)maximum_value(basis);
        } else {
            return -1;
        }
    }
    if (cursor != length) return -1;

    const size_t output_bytes = result_count * 8;
    if (output_bytes == 0) return 0;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t result = 0; result < result_count; ++result)
        store_i64_le(output, result * 8, results[result]);
    return (int64_t)output_bytes;
}
