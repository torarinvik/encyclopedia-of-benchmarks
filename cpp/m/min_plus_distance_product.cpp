#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_INPUT = 130, MAX_OUTPUT = 512, MAX_DIM = 8;
constexpr std::int64_t INF = 1000000;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = static_cast<std::uint8_t>(bits & 255u); bits >>= 8; }
}
}

extern "C" std::int64_t min_plus_distance_product(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 4 || length > MAX_INPUT) return -1;
    const auto n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > MAX_DIM || m0 < 1 || m0 > MAX_DIM) return -1;
    const auto n = static_cast<std::size_t>(n0), m = static_cast<std::size_t>(m0);
    if (length != 2 + 2 * n * m) return -1;
    for (std::size_t i = 2; i < length; ++i)
        if (input[i] < 0 || (input[i] > 1000 && input[i] != INF)) return -1;
    const auto bytes = 8 * n * n;
    if (bytes > MAX_OUTPUT) return -1;
    if (!output || capacity < bytes) return -2;
    std::int64_t result[MAX_DIM * MAX_DIM];
    const auto *a = input + 2;
    const auto *b = input + 2 + n * m;
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = 0; j < n; ++j) {
            auto best = INF;
            for (std::size_t k = 0; k < m; ++k) {
                const auto x = a[i * m + k], y = b[k * n + j];
                if (x != INF && y != INF && x + y < best) best = x + y;
            }
            result[i * n + j] = best;
        }
    }
    for (std::size_t i = 0; i < n * n; ++i) store_i64_le(output, 8 * i, result[i]);
    return static_cast<std::int64_t>(bytes);
}
