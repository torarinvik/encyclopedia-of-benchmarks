#include <cstdint>

namespace {
constexpr int MIN_ORDER = 4;
constexpr int MAX_ORDER = 64;
constexpr std::uint64_t FNV_OFFSET = UINT64_C(0xcbf29ce484222325);
constexpr std::uint64_t FNV_PRIME = UINT64_C(0x100000001b3);

std::uint64_t hash_byte(std::uint64_t hash, std::uint8_t byte) {
    return (hash ^ byte) * FNV_PRIME;
}

std::uint64_t hash_i32(std::uint64_t hash, std::int32_t value) {
    const std::uint32_t bits = static_cast<std::uint32_t>(value);
    for (unsigned shift = 0; shift < 32; shift += 8) {
        hash = hash_byte(hash, static_cast<std::uint8_t>(bits >> shift));
    }
    return hash;
}
}

extern "C" std::int64_t magic_square_doubly_even_complement(std::int64_t n) {
    if (n < MIN_ORDER || n > MAX_ORDER || n % 4 != 0) return -1;
    const int order = static_cast<int>(n);
    const std::int32_t ceiling = order * order + 1;
    std::uint64_t hash = hash_byte(FNV_OFFSET, static_cast<std::uint8_t>(order));

    for (int row = 0; row < order; ++row) {
        for (int column = 0; column < order; ++column) {
            std::int32_t value = row * order + column + 1;
            const int local_row = row % 4;
            const int local_column = column % 4;
            if (local_row == local_column || local_row + local_column == 3) value = ceiling - value;
            hash = hash_i32(hash, value);
        }
    }
    return static_cast<std::int64_t>(hash & UINT64_C(0x7fffffffffffffff));
}
