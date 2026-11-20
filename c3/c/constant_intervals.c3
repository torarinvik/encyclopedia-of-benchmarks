module constant_intervals;

const usz MAX_N = 256;

struct IntervalState {
    char* output;
    usz count;
    usz last_hi;
    int last_value;
    bool has_last;
}

fn int value_at(usz index, long step, long offset, long divisor) {
    return (int)((step * (long)index + offset) / divisor);
}

fn void store_i32_le(char* output, usz position, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1)
        output[position + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn void append_interval(IntervalState* state, usz lo, usz hi, int value) {
    if (state->has_last && state->last_hi == lo && state->last_value == value) {
        store_i32_le(state->output, (state->count - 1) * 12 + 4, (int)hi);
    } else {
        usz position = state->count * 12;
        store_i32_le(state->output, position, (int)lo);
        store_i32_le(state->output, position + 4, (int)hi);
        store_i32_le(state->output, position + 8, value);
        state->count += 1;
    }
    state->last_hi = hi;
    state->last_value = value;
    state->has_last = true;
}

fn void visit_range(usz lo, usz hi, long step, long offset, long divisor,
                    IntervalState* state) {
    int first = value_at(lo, step, offset, divisor);
    int last = value_at(hi - 1, step, offset, divisor);
    if (first == last || hi - lo == 1) {
        append_interval(state, lo, hi, first);
        return;
    }
    usz mid = lo + (hi - lo) / 2;
    visit_range(lo, mid, step, offset, divisor, state);
    visit_range(mid, hi, step, offset, divisor, state);
}

fn long constant_intervals(long* input, usz length, char* output, usz output_capacity)
    @export("constant_intervals") {
    if (input == null || length != 4) return -1;
    long n_value = input[0];
    long step = input[1];
    long offset = input[2];
    long divisor = input[3];
    if (n_value < 0 || n_value > (long)MAX_N || step < 0 || step > 65535
        || offset < 0 || offset > 65535 || divisor < 1 || divisor > 65535) return -1;
    usz n = (usz)n_value;
    usz maximum_bytes = n * 12;
    if (output_capacity < maximum_bytes || (maximum_bytes > 0 && output == null)) return -2;
    if (n == 0) return 0;
    IntervalState state = {output, 0, 0, 0, false};
    visit_range(0, n, step, offset, divisor, &state);
    return (long)state->count;
}
