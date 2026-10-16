#include <cstdint>

namespace {
constexpr int MAX_ORDER = 31;
constexpr std::uint64_t FNV_OFFSET = UINT64_C(0xcbf29ce484222325);
constexpr std::uint64_t FNV_PRIME = UINT64_C(0x100000001b3);

std::uint64_t hash_byte(std::uint64_t hash, std::uint8_t byte) {
    return (hash ^ byte) * FNV_PRIME;
}

std::uint64_t hash_i32(std::uint64_t hash, std::int32_t value) {
    const std::uint32_t bits = static_cast<std::uint32_t>(value);
    for (unsigned shift = 0; shift < 32; shift += 8) hash = hash_byte(hash, static_cast<std::uint8_t>(bits >> shift));
    return hash;
}
}

extern "C" std::int64_t magic_square(std::int64_t n) {
    if (n < 1 || n > MAX_ORDER || n % 2 == 0) return -1;
    const int order = static_cast<int>(n);
    std::int32_t square[MAX_ORDER * MAX_ORDER]{};
    int row = order / 2, column = order - 1;
    square[row * MAX_ORDER + column] = 1;
    for (int value = 2; value <= order * order; ++value) {
        const int next_row = (row - 1 + order) % order;
        const int next_column = (column + 1) % order;
        if (square[next_row * MAX_ORDER + next_column] == 0) {
            row = next_row;
            column = next_column;
        } else {
            column = (column - 1 + order) % order;
        }
        square[row * MAX_ORDER + column] = value;
    }
    std::uint64_t hash = hash_byte(FNV_OFFSET, static_cast<std::uint8_t>(order));
    for (int r = 0; r < order; ++r) for (int c = 0; c < order; ++c) hash = hash_i32(hash, square[r * MAX_ORDER + c]);
    return static_cast<std::int64_t>(hash & UINT64_C(0x7fffffffffffffff));
}
