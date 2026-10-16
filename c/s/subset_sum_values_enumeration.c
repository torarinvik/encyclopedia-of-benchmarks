/* Enumerate positive value lists in include-first source order. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 11
#define MAX_TARGET 256
#define MAX_ITEM 64

static void write_i64_le(uint8_t *output, size_t *position, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (unsigned shift = 0; shift < 64; shift += 8)
        output[(*position)++] = (uint8_t)((bits >> shift) & 0xffu);
}

static size_t enumerate(const int64_t *items, size_t item_count, size_t index,
                        int64_t target, int64_t sum, int64_t *chosen,
                        size_t chosen_count, uint8_t *output, size_t *position,
                        int emit)
{
    if (sum == target) {
        if (emit) {
            write_i64_le(output, position, (int64_t)chosen_count);
            for (size_t i = 0; i < chosen_count; ++i) write_i64_le(output, position, chosen[i]);
        }
        return chosen_count + 1;
    }
    if (index == item_count || sum > target) return 0;
    chosen[chosen_count] = items[index];
    const size_t include_slots = enumerate(items, item_count, index + 1, target,
        sum + items[index], chosen, chosen_count + 1, output, position, emit);
    const size_t exclude_slots = enumerate(items, item_count, index + 1, target,
        sum, chosen, chosen_count, output, position, emit);
    return include_slots + exclude_slots;
}

int64_t subset_sum_values_enumeration(const int64_t *input, size_t length,
                                     uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length == 0 || length > MAX_ITEMS + 1) return -1;
    const int64_t target = input[0];
    if (target < 0 || target > MAX_TARGET) return -1;
    const size_t items = length - 1;
    for (size_t i = 0; i < items; ++i)
        if (input[i + 1] < 1 || input[i + 1] > MAX_ITEM) return -1;

    int64_t chosen[MAX_ITEMS] = {0};
    size_t dummy_position = 0;
    const size_t slots = enumerate(input + 1, items, 0, target, 0, chosen, 0,
                                   NULL, &dummy_position, 0);
    const size_t required = slots * 8;
    if (required == 0) return 0;
    if (output == NULL || output_capacity < required) return -2;
    size_t position = 0;
    enumerate(input + 1, items, 0, target, 0, chosen, 0, output, &position, 1);
    return (int64_t)position;
}
