#include <stddef.h>
#include <stdint.h>

#define ARENA_UNITS 256
#define MAX_ORDER 8
#define MAX_OPERATIONS 64
#define MAX_IDS 32
#define MAX_INPUT_WORDS 194
#define MAX_OUTPUT_WORDS (3 * MAX_OPERATIONS + 1 + 2 * ARENA_UNITS)

int64_t buddy_system_allocator(const int64_t *values, size_t length,
                               uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || length > MAX_INPUT_WORDS) return -1;
    const int64_t raw_count = values[0];
    if (raw_count < 0 || raw_count > MAX_OPERATIONS
        || length != 1 + 3 * (size_t)raw_count) return -1;
    const size_t operation_count = (size_t)raw_count;

    uint8_t free_blocks[MAX_ORDER + 1][ARENA_UNITS] = {{0}};
    uint8_t active[MAX_IDS] = {0};
    uint16_t allocation_base[MAX_IDS] = {0};
    uint8_t allocation_order[MAX_IDS] = {0};
    int64_t staged[MAX_OUTPUT_WORDS] = {0};
    free_blocks[MAX_ORDER][0] = 1;
    size_t staged_words = 0;

    for (size_t i = 0; i < operation_count; ++i) {
        const int64_t opcode = values[1 + 3 * i];
        const int64_t raw_id = values[2 + 3 * i];
        const int64_t argument = values[3 + 3 * i];
        if (raw_id < 0 || raw_id >= MAX_IDS) return -1;
        const size_t id = (size_t)raw_id;
        if (opcode == 0) {
            if (argument < 1 || argument > ARENA_UNITS || active[id]) return -1;
            size_t target_order = 0;
            size_t rounded = 1;
            while (rounded < (size_t)argument) {
                rounded <<= 1;
                ++target_order;
            }
            size_t chosen_order = MAX_ORDER + 1;
            size_t chosen_base = ARENA_UNITS;
            for (size_t order = target_order; order <= MAX_ORDER; ++order) {
                const size_t block_size = (size_t)1 << order;
                for (size_t base = 0; base + block_size <= ARENA_UNITS; base += block_size) {
                    if (free_blocks[order][base]) {
                        chosen_order = order;
                        chosen_base = base;
                        break;
                    }
                }
                if (chosen_order <= MAX_ORDER) break;
            }
            if (chosen_order > MAX_ORDER) {
                staged[staged_words++] = 0;
                staged[staged_words++] = -1;
                staged[staged_words++] = 0;
                continue;
            }
            free_blocks[chosen_order][chosen_base] = 0;
            while (chosen_order > target_order) {
                --chosen_order;
                const size_t half = (size_t)1 << chosen_order;
                free_blocks[chosen_order][chosen_base + half] = 1;
            }
            active[id] = 1;
            allocation_base[id] = (uint16_t)chosen_base;
            allocation_order[id] = (uint8_t)target_order;
            staged[staged_words++] = 1;
            staged[staged_words++] = (int64_t)chosen_base;
            staged[staged_words++] = (int64_t)((size_t)1 << target_order);
        } else if (opcode == 1) {
            if (argument != 0 || !active[id]) return -1;
            const size_t original_base = allocation_base[id];
            const size_t original_order = allocation_order[id];
            const size_t original_size = (size_t)1 << original_order;
            active[id] = 0;
            size_t base = original_base;
            size_t order = original_order;
            while (order < MAX_ORDER) {
                const size_t buddy = base ^ ((size_t)1 << order);
                if (!free_blocks[order][buddy]) break;
                free_blocks[order][buddy] = 0;
                if (buddy < base) base = buddy;
                ++order;
            }
            free_blocks[order][base] = 1;
            staged[staged_words++] = 1;
            staged[staged_words++] = (int64_t)original_base;
            staged[staged_words++] = (int64_t)original_size;
        } else {
            return -1;
        }
    }

    const size_t count_index = staged_words;
    staged[staged_words++] = 0;
    for (size_t base = 0; base < ARENA_UNITS; ++base) {
        for (size_t order = MAX_ORDER + 1; order > 0;) {
            --order;
            if (free_blocks[order][base]) {
                staged[count_index] += 1;
                staged[staged_words++] = (int64_t)base;
                staged[staged_words++] = (int64_t)((size_t)1 << order);
                break;
            }
        }
    }
    const size_t required = staged_words * 8;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t i = 0; i < staged_words; ++i) {
        const uint64_t word = (uint64_t)staged[i];
        for (size_t byte = 0; byte < 8; ++byte) {
            output[8 * i + byte] = (uint8_t)(word >> (8 * byte));
        }
    }
    return (int64_t)required;
}
