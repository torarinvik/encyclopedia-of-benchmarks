#include <stddef.h>
#include <stdint.h>

static size_t rail_for_position(size_t position, size_t rails) {
    const size_t period = 2 * (rails - 1);
    const size_t phase = position % period;
    return phase < rails ? phase : period - phase;
}

int64_t rail_fence(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > 260) return -1;
    if (input[0] < 0 || input[0] > 1 || input[1] < 2 || input[1] > 8) return -1;
    if (input[2] < 0 || input[2] > 256) return -1;
    const size_t mode = (size_t)input[0];
    const size_t rails = (size_t)input[1];
    const size_t n = (size_t)input[2];
    if (length != n + 3) return -1;
    for (size_t i = 0; i < n; ++i) {
        if (input[i + 3] < 0 || input[i + 3] > 127) return -1;
    }
    if (output == NULL || capacity < n) return -2;

    if (mode == 0) {
        size_t out = 0;
        for (size_t rail = 0; rail < rails; ++rail) {
            for (size_t position = 0; position < n; ++position) {
                if (rail_for_position(position, rails) == rail) {
                    output[out++] = (uint8_t)input[position + 3];
                }
            }
        }
    } else {
        size_t counts[8] = {0};
        size_t starts[8] = {0};
        size_t used[8] = {0};
        for (size_t position = 0; position < n; ++position) {
            ++counts[rail_for_position(position, rails)];
        }
        for (size_t rail = 1; rail < rails; ++rail) {
            starts[rail] = starts[rail - 1] + counts[rail - 1];
        }
        for (size_t position = 0; position < n; ++position) {
            const size_t rail = rail_for_position(position, rails);
            output[position] = (uint8_t)input[3 + starts[rail] + used[rail]];
            ++used[rail];
        }
    }
    return (int64_t)n;
}
