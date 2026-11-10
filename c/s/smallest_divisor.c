#include <stddef.h>
#include <stdint.h>

int64_t smallest_divisor(const int64_t *input, size_t length) {
    if (length < 2 || length > 257 || input == NULL) return -1;
    const uint64_t count = (uint64_t)(length - 1);
    const uint64_t threshold = (uint64_t)input[0];
    if (threshold < count || threshold > 1000000) return -1;
    uint64_t maximum = 0;
    uint64_t total = 0;
    for (size_t index = 1; index < length; ++index) {
        const uint64_t value = (uint64_t)input[index];
        if (value == 0 || value > 1000000) return -1;
        maximum = value > maximum ? value : maximum;
        total += value;
    }
    if (threshold == count) return (int64_t)maximum;

    uint64_t low = (total - 1) / threshold + 1;
    const uint64_t upper_bound = (total - count) / (threshold - count + 1) + 1;
    uint64_t high = upper_bound < maximum ? upper_bound : maximum;
    while (low < high) {
        const uint64_t middle = low + ((high - low) >> 1);
        uint64_t rounded_sum = count;
        if (count <= 4) {
            for (size_t index = 1; index < length; ++index) {
                rounded_sum += ((uint32_t)input[index] - 1) / (uint32_t)middle;
            }
        } else {
            const uint64_t reciprocal = (1099511627775 / middle) + 1;
            for (size_t index = 1; index < length; ++index) {
                rounded_sum += (((uint64_t)input[index] - 1) * reciprocal) >> 40;
            }
        }
        if (rounded_sum <= threshold) high = middle;
        else low = middle + 1;
    }
    return (int64_t)low;
}
