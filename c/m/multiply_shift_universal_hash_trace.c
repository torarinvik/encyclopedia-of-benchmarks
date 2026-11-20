#include <stddef.h>
#include <stdint.h>

#define MS_BITS 32
#define MS_MAX_HASH_BITS 16
#define MS_MAX_QUERIES 32
#define MS_MAX_WORDS (2 + 2 * MS_MAX_QUERIES)
#define MS_MASK UINT64_C(0xffffffff)

static void ms_write_u64_le(uint8_t *output, size_t index, uint64_t value)
{
    for (size_t byte = 0; byte < 8; ++byte)
        output[index * 8 + byte] = (uint8_t)(value >> (8 * byte));
}

int64_t multiply_shift_universal_hash_trace(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MS_MAX_WORDS + 1) return -1;
    const int64_t width_value = input[0];
    const int64_t count_value = input[1];
    if (width_value < 1 || width_value > MS_MAX_HASH_BITS ||
        count_value < 0 || count_value > MS_MAX_QUERIES) return -1;
    const size_t count = (size_t)count_value;
    if (length != 2 + 2 * count) return -1;

    for (size_t query = 0; query < count; ++query) {
        const int64_t multiplier = input[2 + 2 * query];
        const int64_t key = input[3 + 2 * query];
        if (multiplier < 1 || multiplier > (int64_t)MS_MASK ||
            (multiplier & 1) == 0 || key < 0 || key > (int64_t)MS_MASK) return -1;
    }

    const size_t required = count * 8;
    if ((required > 0 && output == NULL) || capacity < required) return -2;
    const unsigned shift = MS_BITS - (unsigned)width_value;
    for (size_t query = 0; query < count; ++query) {
        const uint64_t multiplier = (uint64_t)input[2 + 2 * query];
        const uint64_t key = (uint64_t)input[3 + 2 * query];
        const uint64_t low_word = (multiplier * key) & MS_MASK;
        ms_write_u64_le(output, query, low_word >> shift);
    }
    return (int64_t)required;
}
