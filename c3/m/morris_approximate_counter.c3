module morris_approximate_counter;

const usz MAX_UPDATES = 53;
const usz DRAW_BITS = 53;
const usz MAX_INPUT_VALUES = 1 + MAX_UPDATES;
const ulong DRAW_LIMIT = 1ul << DRAW_BITS;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long morris_approximate_counter(long* input, usz length, char* output,
    usz capacity) @export("morris_approximate_counter") {
    if (input == null || length < 1 || length > MAX_INPUT_VALUES) return -1;
    long updates_value = input[0];
    if (updates_value < 1 || updates_value > (long)MAX_UPDATES) return -1;
    usz updates = (usz)updates_value;
    if (length != 1 + updates) return -1;

    usz state = 0;
    for (usz event = 0; event < updates; event += 1) {
        long draw_value = input[1 + event];
        if (draw_value < 0 || (ulong)draw_value >= DRAW_LIMIT) return -1;
        ulong threshold = 1ul << (DRAW_BITS - state);
        if ((ulong)draw_value < threshold) state += 1;
    }

    if (output == null || capacity < 16) return -2;
    long estimate = (long)((1ul << state) - 1);
    store_i64_le(output, 0, (long)state);
    store_i64_le(output, 8, estimate);
    return 16;
}
