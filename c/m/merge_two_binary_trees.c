/* Merge two heap-indexed trees and encode the result as little-endian i32 slots. */
#include <stddef.h>
#include <stdint.h>

#define MAX_TREE_SLOTS 255
#define MAX_INPUT_LENGTH 512
#define NULL_SLOT INT64_C(-1000001)

static int valid_tree(const int64_t *input, size_t start, size_t count)
{
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[start + index];
        if (value != NULL_SLOT && (value < -100000 || value > 100000)) return 0;
        if (index > 0 && input[start + (index - 1) / 2] == NULL_SLOT && value != NULL_SLOT) return 0;
    }
    return 1;
}

int64_t merge_two_binary_trees(const int64_t *input, size_t length,
                               uint8_t *output, size_t output_capacity)
{
    if (length < 2 || length > MAX_INPUT_LENGTH || input == NULL) return -1;
    if (input[0] < 0 || input[0] > MAX_TREE_SLOTS) return -1;
    const size_t first_count = (size_t)input[0];
    const size_t second_count_position = first_count + 1;
    if (second_count_position >= length) return -1;
    if (input[second_count_position] < 0 || input[second_count_position] > MAX_TREE_SLOTS) return -1;
    const size_t second_count = (size_t)input[second_count_position];
    const size_t first_start = 1;
    const size_t second_start = second_count_position + 1;
    if (length != second_start + second_count) return -1;
    if (!valid_tree(input, first_start, first_count)
            || !valid_tree(input, second_start, second_count)) return -1;

    const size_t maximum_slots = first_count > second_count ? first_count : second_count;
    int32_t merged[MAX_TREE_SLOTS];
    size_t node_count = 0;
    for (size_t index = 0; index < maximum_slots; ++index) {
        const int64_t first = index < first_count ? input[first_start + index] : NULL_SLOT;
        const int64_t second = index < second_count ? input[second_start + index] : NULL_SLOT;
        if (first == NULL_SLOT && second == NULL_SLOT) {
            merged[index] = -1000001;
        } else {
            const int64_t value = (first == NULL_SLOT ? 0 : first) + (second == NULL_SLOT ? 0 : second);
            merged[index] = (int32_t)value;
            ++node_count;
        }
    }
    size_t output_slots = maximum_slots;
    while (output_slots > 0 && merged[output_slots - 1] == -1000001) --output_slots;
    const size_t output_bytes = output_slots * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == NULL)) return -2;

    for (size_t index = 0; index < output_slots; ++index) {
        const uint32_t bits = (uint32_t)merged[index];
        for (size_t byte = 0; byte < 4; ++byte)
            output[index * 4 + byte] = (uint8_t)((bits >> (byte * 8)) & 255U);
    }
    return (int64_t)node_count;
}
