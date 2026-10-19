module revert_bits;

const INPUT_COUNT = 2;
const OUTPUT_BYTES = 12;

fn uint reverse_bits32(uint n) {
    n = ((n >> 1) & 0x55555555u) | ((n & 0x55555555u) << 1);
    n = ((n >> 2) & 0x33333333u) | ((n & 0x33333333u) << 2);
    n = ((n >> 4) & 0x0f0f0f0fu) | ((n & 0x0f0f0f0fu) << 4);
    return ((n & 0xff000000u) >> 24) | ((n & 0x00ff0000u) >> 8) |
           ((n & 0x0000ff00u) << 8) | ((n & 0x000000ffu) << 24);
}

fn ulong reverse_bits64(ulong n) {
    n = ((n >> 1) & 0x5555555555555555ul) | ((n & 0x5555555555555555ul) << 1);
    n = ((n >> 2) & 0x3333333333333333ul) | ((n & 0x3333333333333333ul) << 2);
    n = ((n >> 4) & 0x0f0f0f0f0f0f0f0ful) | ((n & 0x0f0f0f0f0f0f0f0ful) << 4);
    return ((n & 0xff00000000000000ul) >> 56) |
           ((n & 0x00ff000000000000ul) >> 40) |
           ((n & 0x0000ff0000000000ul) >> 24) |
           ((n & 0x000000ff00000000ul) >> 8) |
           ((n & 0x00000000ff000000ul) << 8) |
           ((n & 0x0000000000ff0000ul) << 24) |
           ((n & 0x000000000000ff00ul) << 40) |
           ((n & 0x00000000000000fful) << 56);
}

fn long revert_bits(long* input, usz length, uchar* output, usz capacity)
    @export("revert_bits") {
    if (input == null || length != INPUT_COUNT || input[0] < 0 ||
        (ulong)input[0] > 0xfffffffful) return -1;
    if (output == null || capacity < OUTPUT_BYTES) return -2;
    uint reversed32 = reverse_bits32((uint)input[0]);
    ulong reversed64 = reverse_bits64((ulong)input[1]);
    for (usz i = 0; i < 4; i++) output[i] = (uchar)(reversed32 >> (8 * i));
    for (usz i = 0; i < 8; i++) output[4 + i] = (uchar)(reversed64 >> (8 * i));
    return OUTPUT_BYTES;
}
