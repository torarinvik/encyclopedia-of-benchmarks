#include <stddef.h>
#include <stdint.h>

#define MAX_INDEX INT64_C(4096)
#define MAX_COUNT INT64_C(128)
static void store_u64_le(uint8_t *output, size_t offset, uint64_t value) {
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(value >> (byte * 8));
}

static void radical_inverse(int64_t index, int64_t base,
                            uint64_t *numerator, uint64_t *denominator) {
    uint64_t reversed = 0;
    uint64_t scale = 1;
    while (index > 0) {
        reversed = reversed * (uint64_t)base + (uint64_t)(index % base);
        scale *= (uint64_t)base;
        index /= base;
    }
    *numerator = reversed;
    *denominator = scale;
}

int64_t van_der_corput_sequence(const int64_t *input, size_t length,
                                uint8_t *output, size_t output_capacity) {
    if (input == NULL || length != 3) return -1;
    const int64_t base = input[0];
    const int64_t first_index = input[1];
    const int64_t count = input[2];
    if (base < 2 || base > 16 || first_index < 1 || first_index > MAX_INDEX
        || count < 0 || count > MAX_COUNT
        || (count > 0 && first_index + count - 1 > MAX_INDEX)) return -1;

    const size_t output_bytes = (size_t)count * 16;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (int64_t offset = 0; offset < count; ++offset) {
        uint64_t numerator = 0;
        uint64_t denominator = 1;
        radical_inverse(first_index + offset, base, &numerator, &denominator);
        const size_t position = (size_t)offset * 16;
        store_u64_le(output, position, numerator);
        store_u64_le(output, position + 8, denominator);
    }
    return (int64_t)output_bytes;
}
