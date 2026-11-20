#include <stddef.h>
#include <stdint.h>

enum { MAX_MASKS = 64, MAX_INPUT_LENGTH = 66, MAX_BITS = 6 };

int64_t sum_over_subsets_zeta_transform(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t bit_count_value = input[0];
    if (bit_count_value < 0 || bit_count_value > MAX_BITS) return -1;
    const size_t bit_count = (size_t)bit_count_value;
    const size_t mask_count = (size_t)1 << bit_count;
    if (length != mask_count + 1) return -1;

    int64_t transformed[MAX_MASKS];
    for (size_t mask = 0; mask < mask_count; ++mask) {
        const int64_t value = input[mask + 1];
        if (value < 0 || value > 1000000) return -1;
        transformed[mask] = value;
    }

    for (size_t bit = 0; bit < bit_count; ++bit) {
        const size_t bit_value = (size_t)1 << bit;
        for (size_t mask = 0; mask < mask_count; ++mask) {
            if ((mask & bit_value) != 0)
                transformed[mask] += transformed[mask ^ bit_value];
        }
    }

    int64_t checksum = 0;
    for (size_t mask = 0; mask < mask_count; ++mask)
        checksum += (int64_t)(mask + 1) * transformed[mask];
    return checksum;
}
