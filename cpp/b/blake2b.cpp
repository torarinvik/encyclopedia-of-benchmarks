#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_INPUT = 4096;
constexpr std::size_t BLOCK_BYTES = 128;
constexpr std::uint64_t IV[8] = {
    UINT64_C(0x6a09e667f3bcc908), UINT64_C(0xbb67ae8584caa73b),
    UINT64_C(0x3c6ef372fe94f82b), UINT64_C(0xa54ff53a5f1d36f1),
    UINT64_C(0x510e527fade682d1), UINT64_C(0x9b05688c2b3e6c1f),
    UINT64_C(0x1f83d9abfb41bd6b), UINT64_C(0x5be0cd19137e2179)
};
constexpr std::uint8_t SIGMA[10][16] = {
    {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15},
    {14,10,4,8,9,15,13,6,1,12,0,2,11,7,5,3},
    {11,8,12,0,5,2,15,13,10,14,3,6,7,1,9,4},
    {7,9,3,1,13,12,11,14,2,6,5,10,4,0,15,8},
    {9,0,5,7,2,4,10,15,14,1,11,12,6,8,3,13},
    {2,12,6,10,0,11,8,3,4,13,7,5,15,14,1,9},
    {12,5,1,15,14,13,4,10,0,7,6,3,9,2,8,11},
    {13,11,7,14,12,1,3,9,5,0,15,4,8,6,2,10},
    {6,15,14,9,11,3,0,8,12,2,13,7,1,4,10,5},
    {10,2,8,4,7,6,1,5,15,11,9,14,3,12,13,0}
};

std::uint64_t rotr64(std::uint64_t value, unsigned amount) {
    return (value >> amount) | (value << (64 - amount));
}
void mix(std::uint64_t v[16], unsigned a, unsigned b, unsigned c, unsigned d,
         std::uint64_t x, std::uint64_t y) {
    v[a] = v[a] + v[b] + x; v[d] = rotr64(v[d] ^ v[a], 32);
    v[c] += v[d]; v[b] = rotr64(v[b] ^ v[c], 24);
    v[a] = v[a] + v[b] + y; v[d] = rotr64(v[d] ^ v[a], 16);
    v[c] += v[d]; v[b] = rotr64(v[b] ^ v[c], 63);
}
std::uint64_t load_le64(const std::uint8_t bytes[8]) {
    std::uint64_t value = 0;
    for (unsigned i = 0; i < 8; ++i) value |= std::uint64_t(bytes[i]) << (8 * i);
    return value;
}
void compress(std::uint64_t h[8], const std::uint8_t block[BLOCK_BYTES],
              std::uint64_t counter, bool is_last) {
    std::uint64_t m[16], v[16];
    for (unsigned i = 0; i < 16; ++i) m[i] = load_le64(block + 8 * i);
    for (unsigned i = 0; i < 8; ++i) { v[i] = h[i]; v[i + 8] = IV[i]; }
    v[12] ^= counter;
    if (is_last) v[14] = ~v[14];
    for (unsigned round = 0; round < 12; ++round) {
        const auto *s = SIGMA[round % 10];
        mix(v,0,4,8,12,m[s[0]],m[s[1]]); mix(v,1,5,9,13,m[s[2]],m[s[3]]);
        mix(v,2,6,10,14,m[s[4]],m[s[5]]); mix(v,3,7,11,15,m[s[6]],m[s[7]]);
        mix(v,0,5,10,15,m[s[8]],m[s[9]]); mix(v,1,6,11,12,m[s[10]],m[s[11]]);
        mix(v,2,7,8,13,m[s[12]],m[s[13]]); mix(v,3,4,9,14,m[s[14]],m[s[15]]);
    }
    for (unsigned i = 0; i < 8; ++i) h[i] ^= v[i] ^ v[i + 8];
}
}

extern "C" std::int64_t blake2b(const std::int64_t *input, std::size_t length,
                                 std::uint8_t *output, std::size_t capacity) noexcept {
    if (length > MAX_INPUT || (length > 0 && input == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i) if (input[i] < 0 || input[i] > 255) return -1;
    if (output == nullptr || capacity < 64) return -2;
    std::uint64_t h[8];
    for (unsigned i = 0; i < 8; ++i) h[i] = IV[i];
    h[0] ^= UINT64_C(0x01010040);
    std::uint8_t block[BLOCK_BYTES]{};
    std::size_t consumed = 0;
    std::uint64_t counter = 0;
    while (length - consumed > BLOCK_BYTES) {
        for (std::size_t i = 0; i < BLOCK_BYTES; ++i) block[i] = static_cast<std::uint8_t>(input[consumed + i]);
        counter += BLOCK_BYTES;
        compress(h, block, counter, false);
        consumed += BLOCK_BYTES;
        for (std::size_t i = 0; i < BLOCK_BYTES; ++i) block[i] = 0;
    }
    const std::size_t remaining = length - consumed;
    for (std::size_t i = 0; i < remaining; ++i) block[i] = static_cast<std::uint8_t>(input[consumed + i]);
    counter += remaining;
    compress(h, block, counter, true);
    for (unsigned word = 0; word < 8; ++word)
        for (unsigned byte = 0; byte < 8; ++byte)
            output[word * 8 + byte] = static_cast<std::uint8_t>(h[word] >> (8 * byte));
    return 64;
}
