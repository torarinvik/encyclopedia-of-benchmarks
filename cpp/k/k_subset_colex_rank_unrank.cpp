#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxN = 16;
constexpr int kMaxK = 16;

std::int64_t choose_small(int n, int k) {
    if (n < 0 || k < 0 || k > n) return 0;
    if (k > n - k) k = n - k;
    std::int64_t value = 1;
    for (int i = 1; i <= k; ++i) value = value * (n - k + i) / i;
    return value;
}

void store_i64_le(std::uint8_t* output, std::size_t index, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[index * 8 + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t k_subset_colex_rank_unrank(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 20) return -1;
    const std::int64_t mode = input[0];
    if ((mode != 0 && mode != 1) || length < 3) return -1;
    const std::int64_t raw_n = input[1], raw_k = input[2];
    if (raw_n < 0 || raw_n > kMaxN || raw_k < 0 || raw_k > raw_n) return -1;
    const int n = static_cast<int>(raw_n), k = static_cast<int>(raw_k);
    std::array<std::int64_t, kMaxK> indices{};
    std::int64_t rank = 0;

    if (mode == 0) {
        if (length != static_cast<std::size_t>(3 + k)) return -1;
        for (int i = 0; i < k; ++i) {
            const std::int64_t index = input[3 + static_cast<std::size_t>(i)];
            if (index < 0 || index >= n || (i > 0 && indices[i - 1] >= index)) return -1;
            indices[i] = index;
            rank += choose_small(static_cast<int>(index), i + 1);
        }
    } else {
        if (length != 4) return -1;
        rank = input[3];
        if (rank < 0 || rank >= choose_small(n, k)) return -1;
        int upper = n - 1;
        std::int64_t remainder = rank;
        for (int order = k; order >= 1; --order) {
            int candidate = upper;
            while (candidate >= 0 && choose_small(candidate, order) > remainder) --candidate;
            if (candidate < 0) return -1;
            indices[static_cast<std::size_t>(order - 1)] = candidate;
            remainder -= choose_small(candidate, order);
            upper = candidate - 1;
        }
    }

    const std::size_t words = static_cast<std::size_t>(k) + 1;
    if (output == nullptr || capacity < words * 8) return -2;
    store_i64_le(output, 0, rank);
    for (int i = 0; i < k; ++i) store_i64_le(output, static_cast<std::size_t>(i) + 1, indices[i]);
    return static_cast<std::int64_t>(words * 8);
}
