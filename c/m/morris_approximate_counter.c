#include <stddef.h>
#include <stdint.h>

#define MAX_UPDATES 53
#define DRAW_BITS 53
#define MAX_INPUT_VALUES (1 + MAX_UPDATES)
#define DRAW_LIMIT (UINT64_C(1) << DRAW_BITS)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t morris_approximate_counter(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_VALUES) return -1;
    const int64_t updates_value = input[0];
    if (updates_value < 1 || updates_value > MAX_UPDATES) return -1;
    const size_t updates = (size_t)updates_value;
    if (length != 1 + updates) return -1;

    size_t state = 0;
    for (size_t event = 0; event < updates; ++event) {
        const int64_t draw_value = input[1 + event];
        if (draw_value < 0 || (uint64_t)draw_value >= DRAW_LIMIT) return -1;
        const uint64_t threshold = UINT64_C(1) << (DRAW_BITS - state);
        if ((uint64_t)draw_value < threshold) ++state;
    }

    if (output == NULL || capacity < 16) return -2;
    const int64_t estimate = (int64_t)((UINT64_C(1) << state) - 1);
    store_i64_le(output, 0, (int64_t)state);
    store_i64_le(output, 8, estimate);
    return 16;
}
