// Clean-room bounded GBBS k-core profile; see package LICENSE.txt.
#include <array>
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 16, MaxM = 64, MaxInput = 2 + 2 * MaxM;
void storeI64LE(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t gbbs_k_core_decomposition(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 2 || length > MaxInput) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(MaxM) ||
        length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::array<std::array<bool, MaxN>, MaxN> adjacent{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = true;
    }
    const auto outputBytes = 8 * n;
    if (!output || capacity < outputBytes) return -2;

    std::array<int, MaxN> degree{}, core{};
    std::array<bool, MaxN> alive{}, shell{};
    for (std::size_t u = 0; u < n; ++u) {
        alive[u] = true;
        for (std::size_t v = 0; v < n; ++v) degree[u] += adjacent[u][v];
    }
    std::size_t remaining = n;
    while (remaining > 0) {
        int k = static_cast<int>(n);
        for (std::size_t u = 0; u < n; ++u)
            if (alive[u] && degree[u] < k) k = degree[u];
        for (std::size_t u = 0; u < n; ++u) {
            shell[u] = alive[u] && degree[u] == k;
            if (shell[u]) { alive[u] = false; core[u] = k; --remaining; }
        }
        for (std::size_t v = 0; v < n; ++v) if (alive[v]) {
            int removed = 0;
            for (std::size_t u = 0; u < n; ++u) removed += shell[u] && adjacent[u][v];
            if (removed > 0) degree[v] = std::max(k, degree[v] - removed);
        }
    }
    for (std::size_t u = 0; u < n; ++u) storeI64LE(output, 8 * u, core[u]);
    return static_cast<std::int64_t>(outputBytes);
}
