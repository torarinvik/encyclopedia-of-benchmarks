module random;

const usz MAX_COUNT = 256;
const usz MAX_INPUT_LENGTH = 5;
const usz MAX_OUTPUT_BYTES = MAX_COUNT * 4;

fn void pcg32_put_u32_le(char* output, usz index, uint value) {
    usz offset = index * 4;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(value & 255);
        value >>= 8;
    }
}

fn uint pcg32_rotate_right(uint value, uint rotation) {
    uint left_shift = (32 - rotation) & 31;
    return (value >> rotation) | (value << left_shift);
}

fn long pcg32_random(long* values, usz length, char* output, usz output_capacity) @export("pcg32_random") {
    if (values == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    if (length != 4) return -1;

    ulong seed = (ulong)values[0];
    ulong multiplier = (ulong)values[1];
    long stream_value = values[2], count_value = values[3];
    if (stream_value < 0 || count_value < 0 || count_value > 256) return -1;

    ulong increment = ((ulong)stream_value << 1) | 1;
    ulong state = seed +% increment;
    state = state *% multiplier +% increment;
    usz count = (usz)count_value;
    usz required_bytes = count * 4;
    if (required_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == null || output_capacity < required_bytes) return -2;

    for (usz index = 0; index < count; index += 1) {
        ulong value = state;
        uint rotation = (uint)(value >> 59);
        state = state *% multiplier +% increment;
        value ^= value >> 18;
        uint xorshifted = (uint)(value >> 27);
        pcg32_put_u32_le(output, index, pcg32_rotate_right(xorshifted, rotation));
    }
    return (long)required_bytes;
}
