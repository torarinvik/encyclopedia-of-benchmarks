module sha3;

const usz MAX_MESSAGE_BYTES = 4096;
const usz MAX_PARSEABLE_INPUT_LENGTH = 4099;
const usz MAX_OUTPUT_BYTES = 64;
const ulong[24] ROUND_CONSTANTS = {
    0x0000000000000001, 0x0000000000008082, 0x800000000000808A, 0x8000000080008000,
    0x000000000000808B, 0x0000000080000001, 0x8000000080008081, 0x8000000000008009,
    0x000000000000008A, 0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
    0x000000008000808B, 0x800000000000008B, 0x8000000080008089, 0x8000000000008003,
    0x8000000000008002, 0x8000000000000080, 0x000000000000800A, 0x800000008000000A,
    0x8000000080008081, 0x8000000000008080, 0x0000000080000001, 0x8000000080008008
};
const uint[25] ROTATION_OFFSETS = {
    0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43,
    25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14
};

fn ulong rotate_left(ulong value, uint amount) {
    if (amount == 0) return value;
    return (value << amount) | (value >> (64 - amount));
}

fn void keccak_f(ulong* state) {
    ulong[5] column;
    ulong[5] delta;
    ulong[25] moved;
    for (usz round = 0; round < 24; round++) {
        for (usz x = 0; x < 5; x++)
            column[x] = state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20];
        for (usz x = 0; x < 5; x++)
            delta[x] = column[(x + 4) % 5] ^ rotate_left(column[(x + 1) % 5], 1);
        for (usz y = 0; y < 5; y++)
            for (usz x = 0; x < 5; x++) state[x + 5 * y] ^= delta[x];

        for (usz y = 0; y < 5; y++) {
            for (usz x = 0; x < 5; x++) {
                usz source = x + 5 * y;
                usz target = y + 5 * ((2 * x + 3 * y) % 5);
                moved[target] = rotate_left(state[source], ROTATION_OFFSETS[source]);
            }
        }
        for (usz y = 0; y < 5; y++)
            for (usz x = 0; x < 5; x++)
                state[x + 5 * y] = moved[x + 5 * y] ^
                    ((~moved[(x + 1) % 5 + 5 * y]) & moved[(x + 2) % 5 + 5 * y]);
        state[0] ^= ROUND_CONSTANTS[round];
    }
}

fn void absorb_byte(ulong* state, usz offset, uint8 value) {
    state[offset / 8] ^= (ulong)value << ((offset % 8) * 8);
}

fn long sha3(long* values, usz length, uint8* output, usz output_capacity)
    @export("sha3") {
    if (values == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    if (values[0] < 0 || values[0] > 3 || values[1] < 0 || values[1] > (long)MAX_MESSAGE_BYTES) return -1L;
    usz variant = (usz)values[0];
    usz message_length = (usz)values[1];
    if (length != 2 + message_length) return -1L;
    for (usz index = 0; index < message_length; index++)
        if (values[2 + index] < 0 || values[2 + index] > 255) return -1L;

    const usz[4] digest_lengths = {28, 32, 48, 64};
    const usz[4] rates = {144, 136, 104, 72};
    usz digest_length = digest_lengths[variant];
    usz rate = rates[variant];
    if (output == null || output_capacity < digest_length) return -2L;

    ulong[25] state = zeroed;
    usz offset = 0;
    while (message_length - offset >= rate) {
        for (usz index = 0; index < rate; index++)
            absorb_byte(&state[0], index, (uint8)values[2 + offset + index]);
        keccak_f(&state[0]);
        offset += rate;
    }

    uint8[144] block = zeroed;
    usz remaining = message_length - offset;
    for (usz index = 0; index < remaining; index++)
        block[index] = (uint8)values[2 + offset + index];
    block[remaining] ^= 0x06;
    block[rate - 1] ^= 0x80;
    for (usz index = 0; index < rate; index++) absorb_byte(&state[0], index, block[index]);
    keccak_f(&state[0]);

    for (usz index = 0; index < digest_length; index++)
        output[index] = (uint8)(state[index / 8] >> ((index % 8) * 8));
    return (long)digest_length;
}
