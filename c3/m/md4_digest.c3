module md4_digest;

const uint[4] R1 = {3, 7, 11, 19};
const uint[4] R2 = {3, 5, 9, 13};
const uint[4] R3 = {3, 9, 11, 15};
const uint[16] ORDER3 = {0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15};

fn uint rotl32(uint value, uint amount) { return (value << amount) | (value >> (32 - amount)); }
fn uint choose(uint x, uint y, uint z) { return (x & y) | (~x & z); }
fn uint majority(uint x, uint y, uint z) { return (x & y) | (x & z) | (y & z); }
fn uint parity(uint x, uint y, uint z) { return x ^ y ^ z; }

fn uint read_word(long* input, usz n, usz padded, ulong bit_length, usz offset, usz word_index) {
    uint result = 0;
    usz first = offset + word_index * 4;
    for (usz byte = 0; byte < 4; byte++) {
        usz position = first + byte;
        uint value = 0;
        if (position < n) value = (uint)input[position + 1];
        else if (position == n) value = 0x80;
        else if (position >= padded - 8) value = (uint)((bit_length >> (8 * (position - (padded - 8)))) & 0xff);
        result |= value << (8 * byte);
    }
    return result;
}

fn long md4_digest(long* input, usz length, char* output, usz capacity) @export("md4_digest") {
    if (input == null || length < 1 || length > 4098) return -1;
    long signed_count = input[0];
    if (signed_count < 0 || signed_count > 4096 || length != (usz)signed_count + 1) return -1;
    usz n = (usz)signed_count;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 0 || input[i + 1] > 255) return -1;
    if (output == null || capacity < 16) return -2;

    usz padded = ((n + 8) / 64 + 1) * 64;
    ulong bit_length = (ulong)n * 8;
    uint h0 = 0x67452301, h1 = 0xefcdab89, h2 = 0x98badcfe, h3 = 0x10325476;
    for (usz offset = 0; offset < padded; offset += 64) {
        uint[16] words;
        for (usz i = 0; i < 16; i++) words[i] = read_word(input, n, padded, bit_length, offset, i);
        uint a = h0, b = h1, c = h2, d = h3;
        for (uint step = 0; step < 48; step++) {
            uint round = step / 16, index = step % 16;
            uint mix, word, shift, constant;
            if (round == 0) { mix = choose(b, c, d); word = index; shift = R1[index % 4]; constant = 0; }
            else if (round == 1) { mix = majority(b, c, d); word = (index % 4) * 4 + index / 4; shift = R2[index % 4]; constant = 0x5a827999; }
            else { mix = parity(b, c, d); word = ORDER3[index]; shift = R3[index % 4]; constant = 0x6ed9eba1; }
            uint next_b = b + rotl32(a + mix + words[word] + constant, shift);
            uint prior_d = d; d = c; c = b; b = next_b; a = prior_d;
        }
        h0 += a; h1 += b; h2 += c; h3 += d;
    }
    uint[4] state = {h0, h1, h2, h3};
    for (usz word = 0; word < 4; word++)
        for (usz byte = 0; byte < 4; byte++) output[word * 4 + byte] = (char)((state[word] >> (8 * byte)) & 255);
    return 16;
}
