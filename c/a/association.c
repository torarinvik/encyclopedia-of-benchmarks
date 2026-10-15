#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 11
#define MAX_ITEMSETS ((1u << MAX_ITEMS) - 1u)

static unsigned popcount(unsigned value) {
    unsigned count = 0;
    while (value != 0) { count += value & 1u; value >>= 1; }
    return count;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) output[offset + b] = (uint8_t)(bits >> (8 * b));
}

int64_t association(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || input[0] < 1 || input[0] > 64 || input[1] < 1 || input[1] > MAX_ITEMS) return -1;
    const size_t transactions = (size_t)input[0], items = (size_t)input[1];
    if (length != 2 + transactions) return -1;
    const unsigned limit = 1u << items, valid_bits = limit - 1u;
    for (size_t t = 0; t < transactions; ++t)
        if (input[2 + t] < 0 || (uint64_t)input[2 + t] > valid_bits) return -1;

    uint8_t frequent[1u << MAX_ITEMS] = {0};
    uint64_t masks[MAX_ITEMSETS];
    int64_t supports[MAX_ITEMSETS];
    size_t result_count = 0;
    for (unsigned size = 1; size <= items; ++size) {
        for (unsigned mask = 1; mask < limit; ++mask) {
            if (popcount(mask) != size) continue;
            if (size > 1) {
                int all_subsets_frequent = 1;
                for (unsigned bit = 0; bit < items; ++bit)
                    if ((mask & (1u << bit)) != 0 && !frequent[mask ^ (1u << bit)]) all_subsets_frequent = 0;
                if (!all_subsets_frequent) continue;
            }
            int64_t support = 0;
            for (size_t t = 0; t < transactions; ++t)
                if (((unsigned)input[2 + t] & mask) == mask) ++support;
            if (support > 0) {
                frequent[mask] = 1;
                masks[result_count] = mask;
                supports[result_count++] = support;
            }
        }
    }
    const size_t required = result_count * 16;
    if (capacity < required || (required != 0 && output == NULL)) return -2;
    for (size_t i = 0; i < result_count; ++i) {
        put_i64_le(output, i * 16, (int64_t)masks[i]);
        put_i64_le(output, i * 16 + 8, supports[i]);
    }
    return (int64_t)required;
}
