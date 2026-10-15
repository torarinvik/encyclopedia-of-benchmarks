/* Emit fixed-size index combinations as little-endian subset masks. */
#include <stddef.h>
#include <stdint.h>

int64_t subset_combinations(const int64_t *input, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (length == 0 || length > 13 || input[0] < 0) return -1;
    const size_t item_count = length - 1;
    if (item_count > 12) return -1;
    if (input[0] > (int64_t)item_count) return 0;
    const size_t choose = (size_t)input[0];

    size_t count = 1;
    for (size_t index = 1; index <= choose; ++index)
        count = count * (item_count - choose + index) / index;
    const size_t required = 2 * count;
    if (output_capacity < required || (required != 0 && output == NULL)) return -2;

    size_t indices[12];
    for (size_t index = 0; index < choose; ++index) indices[index] = index;
    for (size_t combination = 0; combination < count; ++combination) {
        size_t mask = 0;
        for (size_t index = 0; index < choose; ++index) mask |= (size_t)1 << indices[index];
        output[2 * combination] = (uint8_t)(mask & 255u);
        output[2 * combination + 1] = (uint8_t)(mask >> 8);
        if (combination + 1 == count) break;
        size_t position = choose;
        while (position > 0) {
            --position;
            if (indices[position] < item_count - choose + position) break;
        }
        ++indices[position];
        for (size_t index = position + 1; index < choose; ++index)
            indices[index] = indices[index - 1] + 1;
    }
    return (int64_t)count;
}
