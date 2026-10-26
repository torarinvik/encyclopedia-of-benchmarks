/* Clean-room bounded GBBS CoSimRank pair profile; see package LICENSE.txt. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 8, max_m = 24, max_input = 5 + 2 * max_m;
void store_scaled_binary64(std::uint8_t *output, std::uint32_t numerator) {
    std::uint64_t bits = 0;
    if (numerator != 0) {
        unsigned high = 0;
        while ((numerator >> (high + 1)) != 0) ++high;
        const std::uint64_t exponent = static_cast<std::uint64_t>(1003 + high);
        const std::uint64_t significand = static_cast<std::uint64_t>(numerator) << (52 - high);
        bits = (exponent << 52) | (significand & ((std::uint64_t{1} << 52) - 1));
    }
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[byte] = static_cast<std::uint8_t>(bits & 255); bits >>= 8;
    }
}
}

extern "C" std::int64_t gbbs_cosimrank_pair_similarity(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 5 || length > max_input) return -1;
    const auto n64 = input[0], m64 = input[1], u64 = input[2], v64 = input[3], iters64 = input[4];
    if (n64 < 1 || n64 > 8 || m64 < 0 || m64 > 24 || u64 < 0 || u64 >= n64 ||
        v64 < 0 || v64 >= n64 || iters64 < 1 || iters64 > 4 || length != 5 + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::array<std::size_t, max_m> from{}, to{};
    std::array<std::size_t, max_n> degree{};
    std::array<std::array<bool, max_n>, max_n> seen{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto a64 = input[5 + 2 * edge], b64 = input[6 + 2 * edge];
        if (a64 < 0 || a64 >= n64 || b64 < 0 || b64 >= n64 || a64 == b64) return -1;
        const auto a = static_cast<std::size_t>(a64), b = static_cast<std::size_t>(b64);
        if (seen[a][b]) return -1;
        seen[a][b] = true; from[edge] = a; to[edge] = b; ++degree[a];
    }
    for (std::size_t i = 0; i < n; ++i)
        if (degree[i] != 0 && degree[i] != 1 && degree[i] != 2 && degree[i] != 4) return -1;
    if (output == nullptr || capacity < 8) return -2;
    std::array<std::uint32_t, max_n> cu{}, cv{}, nu{}, nv{};
    cu[static_cast<std::size_t>(u64)] = 256; cv[static_cast<std::size_t>(v64)] = 256;
    std::uint32_t numerator = u64 == v64 ? (1u << 20) : 0;
    for (std::size_t step = 0; step < static_cast<std::size_t>(iters64); ++step) {
        for (std::size_t edge = 0; edge < m; ++edge) {
            const auto a = from[edge], b = to[edge];
            nu[b] += cu[a] / static_cast<std::uint32_t>(degree[a]);
            nv[b] += cv[a] / static_cast<std::uint32_t>(degree[a]);
        }
        std::uint32_t dot = 0;
        for (std::size_t i = 0; i < n; ++i) dot += nu[i] * nv[i];
        numerator += dot << (3 - step);
        for (std::size_t i = 0; i < n; ++i) { cu[i] = nu[i]; cv[i] = nv[i]; nu[i] = 0; nv[i] = 0; }
    }
    store_scaled_binary64(output, numerator);
    return 8;
}
