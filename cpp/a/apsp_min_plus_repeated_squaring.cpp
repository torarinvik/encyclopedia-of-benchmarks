#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 8;
constexpr std::int64_t INF = 1000000;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t apsp_min_plus_repeated_squaring(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (!input || length < 2 || length > 65) return -1;
    const auto n0 = input[0];
    if (n0 < 1 || n0 > static_cast<std::int64_t>(MAX_N)) return -1;
    const auto n = static_cast<std::size_t>(n0);
    if (length != 1 + n * n) return -1;
    std::int64_t current[MAX_N * MAX_N]{}, next[MAX_N * MAX_N]{};
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = 0; j < n; ++j) {
            const auto value = input[1 + i * n + j];
            if ((i == j && value != 0)
                || (i != j && value != INF && (value < 1 || value > 1000))) return -1;
            current[i * n + j] = value;
        }
    }
    std::size_t edge_bound = 1;
    while (edge_bound < n - 1) {
        for (std::size_t i = 0; i < n; ++i) {
            for (std::size_t j = 0; j < n; ++j) {
                auto best = INF;
                for (std::size_t k = 0; k < n; ++k) {
                    const auto left = current[i * n + k], right = current[k * n + j];
                    if (left != INF && right != INF && left + right < best) best = left + right;
                }
                next[i * n + j] = best;
            }
        }
        for (std::size_t index = 0; index < n * n; ++index) current[index] = next[index];
        edge_bound *= 2;
    }
    const auto bytes = 8 * n * n;
    if (!output || capacity < bytes) return -2;
    for (std::size_t index = 0; index < n * n; ++index)
        store_i64_le(output, 8 * index, current[index]);
    return static_cast<std::int64_t>(bytes);
}
