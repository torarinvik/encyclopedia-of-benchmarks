module md5;

const uint[64] MD5_SHIFTS = {
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
};
const uint[64] MD5_K = {
    0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
    0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
    0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
    0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
    0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
    0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
    0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
    0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
    0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
    0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
    0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
    0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
    0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
    0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
    0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
    0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
};

fn uint md5_rotate_left(uint value, uint amount) {
    return (value << amount) | (value >> (32 - amount));
}

fn uint md5_byte(long* input, usz length, usz padded_length, ulong bit_length, usz position) {
    if (position < length) return (uint)input[position];
    if (position == length) return 0x80;
    if (position >= padded_length - 8) return (uint)((bit_length >> (8 * (position - (padded_length - 8)))) & 0xff);
    return 0;
}

fn uint md5_word(long* input, usz length, usz padded_length, ulong bit_length,
                 usz block_offset, usz word_index) {
    uint value = 0;
    usz start = block_offset + word_index * 4;
    for (usz byte = 0; byte < 4; byte++) value |= md5_byte(input, length, padded_length, bit_length, start + byte) << (8 * byte);
    return value;
}

fn long md5(long* input, usz length, char* output, usz capacity) @export("md5") {
    if (length > 4096 || (length > 0 && input == null)) return -1;
    for (usz index = 0; index < length; index++) if (input[index] < 0 || input[index] > 255) return -1;
    if (output == null || capacity < 16) return -2;

    usz padded_length = ((length + 8) / 64 + 1) * 64;
    ulong bit_length = (ulong)length * 8;
    uint h0 = 0x67452301, h1 = 0xefcdab89, h2 = 0x98badcfe, h3 = 0x10325476;
    for (usz offset = 0; offset < padded_length; offset += 64) {
        uint[16] words;
        for (usz index = 0; index < 16; index++) words[index] = md5_word(input, length, padded_length, bit_length, offset, index);
        uint a = h0, b = h1, c = h2, d = h3;
        for (uint index = 0; index < 64; index++) {
            uint f, g;
            if (index < 16) { f = (b & c) | (~b & d); g = index; }
            else if (index < 32) { f = (d & b) | (~d & c); g = (5 * index + 1) % 16; }
            else if (index < 48) { f = b ^ c ^ d; g = (3 * index + 5) % 16; }
            else { f = c ^ (b | ~d); g = (7 * index) % 16; }
            uint sum = a + f + MD5_K[index] + words[g];
            uint previous_d = d;
            d = c; c = b; b += md5_rotate_left(sum, MD5_SHIFTS[index]); a = previous_d;
        }
        h0 += a; h1 += b; h2 += c; h3 += d;
    }
    uint[4] state = {h0, h1, h2, h3};
    for (usz word = 0; word < 4; word++)
        for (usz byte = 0; byte < 4; byte++) output[word * 4 + byte] = (char)((state[word] >> (8 * byte)) & 255);
    return 16;
}
