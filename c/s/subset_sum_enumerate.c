/* Emit the index masks of all signed subsets matching the target. */
#include <stddef.h>
#include <stdint.h>

int64_t subset_sum_enumerate(const int64_t *input, size_t length,
                             uint8_t *output, size_t output_capacity)
{
    if (length == 0 || length > 9) return -1;
    const int64_t target = input[0];
    if (target < -512 || target > 512) return -1;
    const size_t items = length - 1;
    for (size_t index = 0; index < items; ++index)
        if (input[index + 1] < -64 || input[index + 1] > 64) return -1;

    uint8_t masks[256];
    size_t count = 0;
    const size_t limit = (size_t)1 << items;
    for (size_t mask = 0; mask < limit; ++mask) {
        int64_t sum = 0;
        for (size_t index = 0; index < items; ++index)
            if ((mask >> index) & 1u) sum += input[index + 1];
        if (sum == target) masks[count++] = (uint8_t)mask;
    }
    if (output_capacity < count) return -2;
    for (size_t index = 0; index < count; ++index) output[index] = masks[index];
    return (int64_t)count;
}
