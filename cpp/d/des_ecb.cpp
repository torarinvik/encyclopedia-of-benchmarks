#include <cstddef>
#include <cstdint>

static constexpr std::uint8_t IP[64] = {
    58, 50, 42, 34, 26, 18, 10, 2, 60, 52, 44, 36, 28, 20, 12, 4,
    62, 54, 46, 38, 30, 22, 14, 6, 64, 56, 48, 40, 32, 24, 16, 8,
    57, 49, 41, 33, 25, 17, 9, 1, 59, 51, 43, 35, 27, 19, 11, 3,
    61, 53, 45, 37, 29, 21, 13, 5, 63, 55, 47, 39, 31, 23, 15, 7
};

static constexpr std::uint8_t IP_INV[64] = {
    40, 8, 48, 16, 56, 24, 64, 32, 39, 7, 47, 15, 55, 23, 63, 31,
    38, 6, 46, 14, 54, 22, 62, 30, 37, 5, 45, 13, 53, 21, 61, 29,
    36, 4, 44, 12, 52, 20, 60, 28, 35, 3, 43, 11, 51, 19, 59, 27,
    34, 2, 42, 10, 50, 18, 58, 26, 33, 1, 41, 9, 49, 17, 57, 25
};

static constexpr std::uint8_t E[48] = {
    32, 1, 2, 3, 4, 5, 4, 5, 6, 7, 8, 9, 8, 9, 10, 11,
    12, 13, 12, 13, 14, 15, 16, 17, 16, 17, 18, 19, 20, 21, 20, 21,
    22, 23, 24, 25, 24, 25, 26, 27, 28, 29, 28, 29, 30, 31, 32, 1
};

static constexpr std::uint8_t P[32] = {
    16, 7, 20, 21, 29, 12, 28, 17, 1, 15, 23, 26, 5, 18, 31, 10,
    2, 8, 24, 14, 32, 27, 3, 9, 19, 13, 30, 6, 22, 11, 4, 25
};

static constexpr std::uint8_t PC1[56] = {
    57, 49, 41, 33, 25, 17, 9, 1, 58, 50, 42, 34, 26, 18, 10, 2,
    59, 51, 43, 35, 27, 19, 11, 3, 60, 52, 44, 36, 63, 55, 47, 39,
    31, 23, 15, 7, 62, 54, 46, 38, 30, 22, 14, 6, 61, 53, 45, 37,
    29, 21, 13, 5, 28, 20, 12, 4
};

static constexpr std::uint8_t PC2[48] = {
    14, 17, 11, 24, 1, 5, 3, 28, 15, 6, 21, 10, 23, 19, 12, 4,
    26, 8, 16, 7, 27, 20, 13, 2, 41, 52, 31, 37, 47, 55, 30, 40,
    51, 45, 33, 48, 44, 49, 39, 56, 34, 53, 46, 42, 50, 36, 29, 32
};

static constexpr std::uint8_t SHIFTS[16] = {
    1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1
};

static constexpr std::uint8_t SBOX[512] = {
    14, 4, 13, 1, 2, 15, 11, 8, 3, 10, 6, 12, 5, 9, 0, 7,
    0, 15, 7, 4, 14, 2, 13, 1, 10, 6, 12, 11, 9, 5, 3, 8,
    4, 1, 14, 8, 13, 6, 2, 11, 15, 12, 9, 7, 3, 10, 5, 0,
    15, 12, 8, 2, 4, 9, 1, 7, 5, 11, 3, 14, 10, 0, 6, 13,
    15, 1, 8, 14, 6, 11, 3, 4, 9, 7, 2, 13, 12, 0, 5, 10,
    3, 13, 4, 7, 15, 2, 8, 14, 12, 0, 1, 10, 6, 9, 11, 5,
    0, 14, 7, 11, 10, 4, 13, 1, 5, 8, 12, 6, 9, 3, 2, 15,
    13, 8, 10, 1, 3, 15, 4, 2, 11, 6, 7, 12, 0, 5, 14, 9,
    10, 0, 9, 14, 6, 3, 15, 5, 1, 13, 12, 7, 11, 4, 2, 8,
    13, 7, 0, 9, 3, 4, 6, 10, 2, 8, 5, 14, 12, 11, 15, 1,
    13, 6, 4, 9, 8, 15, 3, 0, 11, 1, 2, 12, 5, 10, 14, 7,
    1, 10, 13, 0, 6, 9, 8, 7, 4, 15, 14, 3, 11, 5, 2, 12,
    7, 13, 14, 3, 0, 6, 9, 10, 1, 2, 8, 5, 11, 12, 4, 15,
    13, 8, 11, 5, 6, 15, 0, 3, 4, 7, 2, 12, 1, 10, 14, 9,
    10, 6, 9, 0, 12, 11, 7, 13, 15, 1, 3, 14, 5, 2, 8, 4,
    3, 15, 0, 6, 10, 1, 13, 8, 9, 4, 5, 11, 12, 7, 2, 14,
    2, 12, 4, 1, 7, 10, 11, 6, 8, 5, 3, 15, 13, 0, 14, 9,
    14, 11, 2, 12, 4, 7, 13, 1, 5, 0, 15, 10, 3, 9, 8, 6,
    4, 2, 1, 11, 10, 13, 7, 8, 15, 9, 12, 5, 6, 3, 0, 14,
    11, 8, 12, 7, 1, 14, 2, 13, 6, 15, 0, 9, 10, 4, 5, 3,
    12, 1, 10, 15, 9, 2, 6, 8, 0, 13, 3, 4, 14, 7, 5, 11,
    10, 15, 4, 2, 7, 12, 9, 5, 6, 1, 13, 14, 0, 11, 3, 8,
    9, 14, 15, 5, 2, 8, 12, 3, 7, 0, 4, 10, 1, 13, 11, 6,
    4, 3, 2, 12, 9, 5, 15, 10, 11, 14, 1, 7, 6, 0, 8, 13,
    4, 11, 2, 14, 15, 0, 8, 13, 3, 12, 9, 7, 5, 10, 6, 1,
    13, 0, 11, 7, 4, 9, 1, 10, 14, 3, 5, 12, 2, 15, 8, 6,
    1, 4, 11, 13, 12, 3, 7, 14, 10, 15, 6, 8, 0, 5, 9, 2,
    6, 11, 13, 8, 1, 4, 10, 7, 9, 5, 0, 15, 14, 2, 3, 12,
    13, 2, 8, 4, 6, 15, 11, 1, 10, 9, 3, 14, 5, 0, 12, 7,
    1, 15, 13, 8, 10, 3, 7, 4, 12, 5, 6, 11, 0, 14, 9, 2,
    7, 11, 4, 1, 9, 12, 14, 2, 0, 6, 10, 13, 15, 3, 5, 8,
    2, 1, 14, 7, 4, 10, 8, 13, 15, 12, 9, 0, 3, 5, 6, 11
};

static std::uint64_t permute(std::uint64_t value, const std::uint8_t *table, std::size_t count, unsigned width) {
    std::uint64_t result = 0;
    for (std::size_t i = 0; i < count; ++i) result = (result << 1) | ((value >> (width - table[i])) & 1u);
    return result;
}

static void make_keys(std::uint64_t key, std::uint64_t keys[16]) {
    const std::uint64_t selected = permute(key, PC1, 56, 64);
    const std::uint32_t mask = (1u << 28) - 1u;
    std::uint32_t left = static_cast<std::uint32_t>(selected >> 28), right = static_cast<std::uint32_t>(selected & mask);
    for (std::size_t round = 0; round < 16; ++round) {
        const unsigned shift = SHIFTS[round];
        left = ((left << shift) | (left >> (28 - shift))) & mask;
        right = ((right << shift) | (right >> (28 - shift))) & mask;
        keys[round] = permute((static_cast<std::uint64_t>(left) << 28) | right, PC2, 48, 56);
    }
}

static std::uint32_t feistel(std::uint32_t right, std::uint64_t key) {
    const std::uint64_t mixed = permute(right, E, 48, 32) ^ key;
    std::uint32_t substituted = 0;
    for (unsigned box = 0; box < 8; ++box) {
        const unsigned six = static_cast<unsigned>((mixed >> (42 - 6 * box)) & 63u);
        const unsigned row = ((six & 32u) >> 4) | (six & 1u), column = (six >> 1) & 15u;
        substituted = (substituted << 4) | SBOX[box * 64 + row * 16 + column];
    }
    return static_cast<std::uint32_t>(permute(substituted, P, 32, 32));
}

static std::uint64_t encrypt_block(std::uint64_t block, const std::uint64_t keys[16]) {
    const std::uint64_t state = permute(block, IP, 64, 64);
    std::uint32_t left = static_cast<std::uint32_t>(state >> 32), right = static_cast<std::uint32_t>(state);
    for (std::size_t round = 0; round < 16; ++round) { const std::uint32_t next = left ^ feistel(right, keys[round]); left = right; right = next; }
    return permute((static_cast<std::uint64_t>(right) << 32) | left, IP_INV, 64, 64);
}

extern "C" std::int64_t des_ecb(const std::int64_t *values, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (values == nullptr || length < 2 || length > 42) return -1;
    const std::int64_t size_arg = values[0];
    if (size_arg < 0 || size_arg > 40 || length != 2 + static_cast<std::size_t>(size_arg)) return -1;
    const std::size_t size = static_cast<std::size_t>(size_arg), out_size = ((size + 7) / 8) * 8;
    for (std::size_t i = 0; i < size; ++i) if (values[2 + i] < 0 || values[2 + i] > 127) return -1;
    if (out_size != 0 && (output == nullptr || capacity < out_size)) return -2;
    std::uint64_t keys[16]; make_keys(static_cast<std::uint64_t>(values[1]), keys);
    for (std::size_t offset = 0; offset < out_size; offset += 8) {
        std::uint64_t block = 0;
        for (std::size_t j = 0; j < 8; ++j) { const std::size_t index = offset + j; const std::uint8_t byte = index < size ? static_cast<std::uint8_t>(values[2 + index]) : 0; block = (block << 8) | byte; }
        std::uint64_t encrypted = encrypt_block(block, keys);
        for (std::size_t j = 0; j < 8; ++j) output[offset + j] = static_cast<std::uint8_t>(encrypted >> (56 - 8 * j));
    }
    return static_cast<std::int64_t>(out_size);
}
