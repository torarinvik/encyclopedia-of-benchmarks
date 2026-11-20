module subtractive_prng_bentley_seeded_sequence;

const usz STATE_SIZE = 55;
const usz SHORT_LAG = 24;
const usz WARMUP_VALUES = 165;
const int MODULUS = 1000000000;

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long subtractive_prng_bentley_seeded_sequence(long* input, usz length,
        char* output, usz capacity) @export("subtractive_prng_bentley_seeded_sequence") {
    if (input == null || length != 2) return -1;
    long seed = input[0], count = input[1];
    if (seed < 0 || seed >= MODULUS || count < 0 || count > 64) return -1;
    usz n = (usz)count, required = n * 8;
    if (capacity < required || (required != 0 && output == null)) return -2;
    if (n == 0) return 0;

    int[55] seed_state;
    int[55] ring;
    seed_state[0] = (int)seed;
    seed_state[1] = 1;
    for (usz i = 2; i < STATE_SIZE; i++) {
        int value = seed_state[i - 2] - seed_state[i - 1];
        if (value < 0) value += MODULUS;
        seed_state[i] = value;
    }
    for (usz i = 0; i < STATE_SIZE; i++)
        ring[i] = seed_state[(34 * (i + 1)) % STATE_SIZE];

    usz write_index = 0, lag_index = STATE_SIZE - SHORT_LAG;
    for (usz step = 0; step < WARMUP_VALUES + n; step++) {
        int value = ring[write_index] - ring[lag_index];
        if (value < 0) value += MODULUS;
        ring[write_index] = value;
        if (step >= WARMUP_VALUES)
            put_i64_le(output, (step - WARMUP_VALUES) * 8, (long)value);
        write_index = (write_index + 1) % STATE_SIZE;
        lag_index = (lag_index + 1) % STATE_SIZE;
    }
    return (long)required;
}
