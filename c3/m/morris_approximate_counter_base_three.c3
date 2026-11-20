module morris_approximate_counter_base_three;

const usz MAX_UPDATES = 30;
const usz MAX_VALID_INPUT_VALUES = 1 + MAX_UPDATES;
const usz MAX_PARSEABLE_INPUT_VALUES = MAX_VALID_INPUT_VALUES + 1;
const ulong DRAW_SPACE = 205891132094649ul;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long morris_approximate_counter_base_three(long* input, usz length,
    char* output, usz capacity) @export("morris_approximate_counter_base_three") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    long updates_value = input[0];
    if (updates_value < 0 || updates_value > (long)MAX_UPDATES) return -1;
    usz updates = (usz)updates_value;
    if (length != 1 + updates) return -1;

    usz state = 0;
    ulong threshold = DRAW_SPACE;
    ulong estimate = 0;
    for (usz event = 0; event < updates; event += 1) {
        long draw_value = input[1 + event];
        if (draw_value < 0 || (ulong)draw_value >= DRAW_SPACE) return -1;
        if ((ulong)draw_value < threshold) {
            state += 1;
            threshold /= 3;
            estimate = 3 * estimate + 1;
        }
    }

    if (output == null || capacity < 16) return -2;
    store_i64_le(output, 0, (long)state);
    store_i64_le(output, 8, (long)estimate);
    return 16;
}
