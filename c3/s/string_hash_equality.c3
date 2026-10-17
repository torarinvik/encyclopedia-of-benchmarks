module string_hash_equality;

const ulong[24] ROUND_CONSTANTS = {
    0x0000000000000001ul,
    0x0000000000008082ul,
    0x800000000000808aul,
    0x8000000080008000ul,
    0x000000000000808bul,
    0x0000000080000001ul,
    0x8000000080008081ul,
    0x8000000000008009ul,
    0x000000000000008aul,
    0x0000000000000088ul,
    0x0000000080008009ul,
    0x000000008000000aul,
    0x000000008000808bul,
    0x800000000000008bul,
    0x8000000000008089ul,
    0x8000000000008003ul,
    0x8000000000008002ul,
    0x8000000000000080ul,
    0x000000000000800aul,
    0x800000008000000aul,
    0x8000000080008081ul,
    0x8000000000008080ul,
    0x0000000080000001ul,
    0x8000000080008008ul
};
const uint[25] ROTATION_OFFSETS = {0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43, 25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14};

fn ulong rotate_left(ulong value, uint amount) {
    if (amount == 0) return value;
    return (value << amount) | (value >> (64 - amount));
}

fn void keccak_f1600(ulong* state) {
    ulong column[5] = {};
    ulong delta[5] = {};
    ulong moved[25] = {};
    for (usz round = 0; round < 24; round++) {
        for (usz x = 0; x < 5; x++) column[x] = state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20];
        for (usz x = 0; x < 5; x++) delta[x] = column[(x + 4) % 5] ^ rotate_left(column[(x + 1) % 5], 1);
        for (usz y = 0; y < 5; y++) for (usz x = 0; x < 5; x++) {
            usz source = x + 5 * y;
            usz target = y + 5 * ((2 * x + 3 * y) % 5);
            moved[target] = rotate_left(state[source] ^ delta[x], ROTATION_OFFSETS[source]);
        }
        for (usz y = 0; y < 5; y++) for (usz x = 0; x < 5; x++)
            state[x + 5 * y] = moved[x + 5 * y] ^ ((~moved[(x + 1) % 5 + 5 * y]) & moved[(x + 2) % 5 + 5 * y]);
        state[0] ^= ROUND_CONSTANTS[round];
    }
}

fn void keccak256_bytes(long* input, usz start, usz byte_length, ulong* digest) {
    uchar block[136] = {};
    for (usz i = 0; i < byte_length; i++) block[i] = (uchar)input[start + i];
    block[byte_length] ^= 1;
    block[135] ^= 128;
    ulong state[25] = {};
    for (usz lane = 0; lane < 17; lane++) for (usz byte = 0; byte < 8; byte++)
        state[lane] |= (ulong)block[lane * 8 + byte] << (8 * byte);
    keccak_f1600(&state[0]);
    for (usz lane = 0; lane < 4; lane++) digest[lane] = state[lane];
}

fn long string_hash_equality(long* input, usz length) @export("string_hash_equality") {
    if (input == null || length < 2 || length > 131) return -1;
    if (input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > 64) return -1;
    usz length_a = (usz)input[0], length_b = (usz)input[1];
    if (length != 2 + length_a + length_b) return -1;
    for (usz i = 0; i < length_a + length_b; i++) if (input[2 + i] < 0 || input[2 + i] > 255) return -1;
    ulong digest_a[4] = {}, digest_b[4] = {};
    keccak256_bytes(input, 2, length_a, &digest_a[0]);
    keccak256_bytes(input, 2 + length_a, length_b, &digest_b[0]);
    for (usz lane = 0; lane < 4; lane++) if (digest_a[lane] != digest_b[lane]) return 0;
    return 1;
}
