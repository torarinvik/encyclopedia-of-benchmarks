module linqshuffler;

const usz MAX_N = 64;
const usz MAX_PARSEABLE_INPUT_LENGTH = 67;
const usz MAX_OUTPUT_BYTES = 520;
const long I32_MIN = -2147483648;
const long I32_MAX = 2147483647;
const long MBIG = 2147483647;

fn void store_i64_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255);
        bits >>= 8;
    }
}

fn long linqshuffler(long* input, usz input_length, uint8* output, usz output_capacity)
    @export("linqshuffler") {
    if (input == null || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    long n_value = input[0];
    long seed = input[1];
    if (n_value < 0 || n_value > (long)MAX_N || seed < I32_MIN || seed > I32_MAX) return -1L;
    usz n = (usz)n_value;
    if (input_length != n + 2) return -1L;

    long[MAX_N] values = zeroed;
    long[MAX_N] keys = zeroed;
    for (usz index = 0; index < n; index++) {
        long value = input[index + 2];
        if (value < I32_MIN || value > I32_MAX) return -1L;
        values[index] = value;
    }

    long subtraction = seed == I32_MIN ? I32_MAX : (seed < 0 ? -seed : seed);
    long[56] seed_array = zeroed;
    long mj = 161803398 - subtraction;
    seed_array[55] = mj;
    long mk = 1;
    for (usz i = 1; i < 55; i++) {
        usz ii = (21 * i) % 55;
        seed_array[ii] = mk;
        mk = mj - mk;
        if (mk < 0) mk += MBIG;
        mj = seed_array[ii];
    }
    for (usz pass = 0; pass < 4; pass++) {
        for (usz i = 1; i < 56; i++) {
            usz offset_index = 1 + (i + 30) % 55;
            seed_array[i] -= seed_array[offset_index];
            if (seed_array[i] < 0) seed_array[i] += MBIG;
        }
    }

    usz inext = 0;
    usz inextp = 21;
    for (usz index = 0; index < n; index++) {
        if (++inext >= 56) inext = 1;
        if (++inextp >= 56) inextp = 1;
        long sample = seed_array[inext] - seed_array[inextp];
        if (sample == MBIG) sample--;
        if (sample < 0) sample += MBIG;
        seed_array[inext] = sample;
        keys[index] = sample;
    }

    // Strict comparison preserves input order for equal random keys.
    for (usz index = 1; index < n; index++) {
        long key = keys[index];
        long value = values[index];
        usz cursor = index;
        while (cursor > 0 && keys[cursor - 1] > key) {
            keys[cursor] = keys[cursor - 1];
            values[cursor] = values[cursor - 1];
            cursor--;
        }
        keys[cursor] = key;
        values[cursor] = value;
    }

    usz output_bytes = 8 * (n + 1);
    if (output_bytes > MAX_OUTPUT_BYTES || output == null || output_capacity < output_bytes) return -2L;
    store_i64_le(output, 0, n_value);
    for (usz index = 0; index < n; index++)
        store_i64_le(output, 8 * (index + 1), values[index]);
    return (long)output_bytes;
}
