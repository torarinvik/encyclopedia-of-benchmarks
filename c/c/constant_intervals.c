#include <stddef.h>
#include <stdint.h>

#define MAX_N 256

typedef struct {
    uint8_t *output;
    size_t count;
    size_t last_hi;
    int32_t last_value;
    int has_last;
} interval_state;

static int32_t value_at(size_t index, int64_t step, int64_t offset, int64_t divisor) {
    return (int32_t)((step * (int64_t)index + offset) / divisor);
}

static void store_i32_le(uint8_t *output, size_t position, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[position + byte] = (uint8_t)(bits >> (8 * byte));
}

static void append_interval(interval_state *state, size_t lo, size_t hi, int32_t value) {
    if (state->has_last && state->last_hi == lo && state->last_value == value) {
        store_i32_le(state->output, (state->count - 1) * 12 + 4, (int32_t)hi);
    } else {
        const size_t position = state->count * 12;
        store_i32_le(state->output, position, (int32_t)lo);
        store_i32_le(state->output, position + 4, (int32_t)hi);
        store_i32_le(state->output, position + 8, value);
        ++state->count;
    }
    state->last_hi = hi;
    state->last_value = value;
    state->has_last = 1;
}

static void visit_range(size_t lo, size_t hi, int64_t step, int64_t offset,
                        int64_t divisor, interval_state *state) {
    const int32_t first = value_at(lo, step, offset, divisor);
    const int32_t last = value_at(hi - 1, step, offset, divisor);
    if (first == last || hi - lo == 1) {
        append_interval(state, lo, hi, first);
        return;
    }
    const size_t mid = lo + (hi - lo) / 2;
    visit_range(lo, mid, step, offset, divisor, state);
    visit_range(mid, hi, step, offset, divisor, state);
}

int64_t constant_intervals(const int64_t *input, size_t length,
                           uint8_t *output, size_t output_capacity) {
    if (input == NULL || length != 4) return -1;
    const int64_t n_value = input[0];
    const int64_t step = input[1];
    const int64_t offset = input[2];
    const int64_t divisor = input[3];
    if (n_value < 0 || n_value > MAX_N || step < 0 || step > 65535
        || offset < 0 || offset > 65535 || divisor < 1 || divisor > 65535) return -1;
    const size_t n = (size_t)n_value;
    const size_t maximum_bytes = n * 12;
    if (output_capacity < maximum_bytes || (maximum_bytes > 0 && output == NULL)) return -2;
    if (n == 0) return 0;

    interval_state state = {output, 0, 0, 0, 0};
    visit_range(0, n, step, offset, divisor, &state);
    return (int64_t)state.count;
}
