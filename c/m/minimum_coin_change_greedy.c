#include <stddef.h>
#include <stdint.h>

#define MIN_TARGET (-4096)
#define MAX_TARGET 4096
#define MAX_DENOMINATIONS 32
#define MAX_INPUT_VALUES (2 + MAX_DENOMINATIONS)
#define MAX_OUTPUT_VALUES (1 + MAX_TARGET)
#define MAX_OUTPUT_BYTES (MAX_OUTPUT_VALUES * 4)

static void write_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t minimum_coin_change_greedy(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t target = input[0];
    const int64_t count_value = input[1];
    if (target < MIN_TARGET || target > MAX_TARGET ||
        count_value < 0 || count_value > MAX_DENOMINATIONS) return -1;
    const size_t denomination_count = (size_t)count_value;
    if (length != 2 + denomination_count) return -1;

    int32_t denominations[MAX_DENOMINATIONS];
    int64_t previous = 0;
    for (size_t index = 0; index < denomination_count; ++index) {
        const int64_t denomination = input[2 + index];
        if (denomination < 1 || denomination > 4096 || denomination <= previous) return -1;
        denominations[index] = (int32_t)denomination;
        previous = denomination;
    }

    int32_t chosen[MAX_TARGET];
    size_t chosen_count = 0;
    if (target > 0) {
        int64_t remaining = target;
        for (size_t index = denomination_count; index > 0; --index) {
            const int32_t denomination = denominations[index - 1];
            while (remaining >= denomination) {
                remaining -= denomination;
                chosen[chosen_count++] = denomination;
            }
        }
    }

    const size_t needed = (1 + chosen_count) * 4;
    if (output == NULL || capacity < needed) return -2;
    write_i32_le(output, 0, (int32_t)chosen_count);
    for (size_t index = 0; index < chosen_count; ++index)
        write_i32_le(output, 4 + 4 * index, chosen[index]);
    return (int64_t)needed;
}
