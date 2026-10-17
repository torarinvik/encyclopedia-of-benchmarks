#include <cstddef>
#include <cstdint>

#define MAX_BYTES 64
#define MAX_PARSEABLE_INPUT_LENGTH 131
#define RATE_BYTES 136

static const std::uint64_t ROUND_CONSTANTS[24] = {
    0x0000000000000001ULL,
    0x0000000000008082ULL,
    0x800000000000808aULL,
    0x8000000080008000ULL,
    0x000000000000808bULL,
    0x0000000080000001ULL,
    0x8000000080008081ULL,
    0x8000000000008009ULL,
    0x000000000000008aULL,
    0x0000000000000088ULL,
    0x0000000080008009ULL,
    0x000000008000000aULL,
    0x000000008000808bULL,
    0x800000000000008bULL,
    0x8000000000008089ULL,
    0x8000000000008003ULL,
    0x8000000000008002ULL,
    0x8000000000000080ULL,
    0x000000000000800aULL,
    0x800000008000000aULL,
    0x8000000080008081ULL,
    0x8000000000008080ULL,
    0x0000000080000001ULL,
    0x8000000080008008ULL
};
static const unsigned int ROTATION_OFFSETS[25] = {0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43, 25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14};

static std::uint64_t rotate_left(std::uint64_t value, unsigned int amount) {
    return amount == 0 ? value : (value << amount) | (value >> (64 - amount));
}

static void keccak_f1600(std::uint64_t state[25]) {
    std::uint64_t column[5], delta[5], moved[25];
    for (std::size_t round = 0; round < 24; ++round) {
        for (std::size_t x = 0; x < 5; ++x)
            column[x] = state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20];
        for (std::size_t x = 0; x < 5; ++x)
            delta[x] = column[(x + 4) % 5] ^ rotate_left(column[(x + 1) % 5], 1);
        for (std::size_t y = 0; y < 5; ++y) for (std::size_t x = 0; x < 5; ++x)
            moved[y + 5 * ((2 * x + 3 * y) % 5)] = rotate_left(state[x + 5 * y] ^ delta[x], ROTATION_OFFSETS[x + 5 * y]);
        for (std::size_t y = 0; y < 5; ++y) for (std::size_t x = 0; x < 5; ++x)
            state[x + 5 * y] = moved[x + 5 * y] ^ ((~moved[(x + 1) % 5 + 5 * y]) & moved[(x + 2) % 5 + 5 * y]);
        state[0] ^= ROUND_CONSTANTS[round];
    }
}

static void keccak256_bytes(const std::int64_t *input, std::size_t start, std::size_t byte_length, std::uint64_t digest[4]) {
    std::uint8_t block[RATE_BYTES] = {0};
    for (std::size_t i = 0; i < byte_length; ++i) block[i] = (std::uint8_t)input[start + i];
    block[byte_length] ^= 0x01;
    block[RATE_BYTES - 1] ^= 0x80;
    std::uint64_t state[25] = {0};
    for (std::size_t lane = 0; lane < RATE_BYTES / 8; ++lane)
        for (std::size_t byte = 0; byte < 8; ++byte)
            state[lane] |= (std::uint64_t)block[lane * 8 + byte] << (8 * byte);
    keccak_f1600(state);
    for (std::size_t lane = 0; lane < 4; ++lane) digest[lane] = state[lane];
}

extern "C" std::int64_t string_hash_equality(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_BYTES || input[1] < 0 || input[1] > MAX_BYTES) return -1;
    std::size_t length_a = (std::size_t)input[0], length_b = (std::size_t)input[1];
    if (length != 2 + length_a + length_b) return -1;
    for (std::size_t i = 0; i < length_a + length_b; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 255) return -1;
    std::uint64_t digest_a[4], digest_b[4];
    keccak256_bytes(input, 2, length_a, digest_a);
    keccak256_bytes(input, 2 + length_a, length_b, digest_b);
    for (std::size_t lane = 0; lane < 4; ++lane) if (digest_a[lane] != digest_b[lane]) return 0;
    return 1;
}
