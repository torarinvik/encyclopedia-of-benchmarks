// Uncompiled multiword bit-parallel LCS length draft.
#include <array>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t bit_parallel_lcs(const std::int64_t* input, std::size_t length) {
    if (!input || length < 2 || length > 515) return -1;
    const auto nr = input[0], mr = input[1];
    if (nr < 0 || nr > 256 || mr < 0 || mr > 256 || length != static_cast<std::size_t>(2+nr+mr)) return -1;
    const auto n = static_cast<std::size_t>(nr), m = static_cast<std::size_t>(mr);
    for (std::size_t i = 2; i < length; ++i) if (input[i] < 0 || input[i] > 255) return -1;
    std::array<std::array<std::uint64_t,4>,256> masks{};
    std::array<std::uint64_t,4> row{};
    const auto words = (n+63)/64;
    for (std::size_t i = 0; i < n; ++i) masks[static_cast<std::size_t>(input[2+i])][i/64] |= UINT64_C(1) << (i%64);
    for (std::size_t i = 0; i < m; ++i) {
        const auto symbol = static_cast<std::size_t>(input[2+n+i]);
        std::uint64_t carry = 1, borrow = 0;
        for (std::size_t j = 0; j < words; ++j) {
            const auto old = row[j], combined = old | masks[symbol][j];
            const auto shifted = (old << 1) | carry;
            carry = old >> 63;
            const auto partial = combined - shifted;
            const auto first_borrow = combined < shifted;
            const auto difference = partial - borrow;
            borrow = first_borrow | (partial < borrow);
            row[j] = combined & (combined ^ difference);
        }
    }
    std::int64_t result = 0;
    for (std::size_t j = 0; j < words; ++j) {
        auto word = row[j];
        while (word) { word &= word-1; ++result; }
    }
    return result;
}
