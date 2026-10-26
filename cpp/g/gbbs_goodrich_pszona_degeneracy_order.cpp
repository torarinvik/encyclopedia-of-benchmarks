// Clean-room bounded GBBS Goodrich-Pszona degeneracy-order profile.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 20;
constexpr std::size_t MaxM = 190;
constexpr std::size_t MaxInput = 2 + 2 * MaxM;
void storeI64LE(std::uint8_t* output, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t gbbs_goodrich_pszona_degeneracy_order(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 2 || length > MaxInput) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) ||
        m64 < 0 || m64 > static_cast<std::int64_t>(MaxM)) return -1;
    const auto n = static_cast<std::size_t>(n64);
    const auto m = static_cast<std::size_t>(m64);
    if (length != 2 + 2 * m) return -1;
    std::array<std::array<bool, MaxN>, MaxN> adjacent{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = true;
    }
    if (!output || capacity < 8 * n) return -2;
    std::array<std::size_t, MaxN> degree{};
    std::array<bool, MaxN> remaining{};
    std::array<std::int64_t, MaxN> rank{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        remaining[vertex] = true;
        for (std::size_t neighbor = 0; neighbor < n; ++neighbor)
            degree[vertex] += adjacent[vertex][neighbor] ? 1U : 0U;
    }
    for (std::size_t position = 0; position < n; ++position) {
        std::size_t chosen = n;
        for (std::size_t vertex = 0; vertex < n; ++vertex)
            if (remaining[vertex] && (chosen == n || degree[vertex] < degree[chosen])) chosen = vertex;
        rank[chosen] = static_cast<std::int64_t>(position);
        remaining[chosen] = false;
        for (std::size_t neighbor = 0; neighbor < n; ++neighbor)
            if (remaining[neighbor] && adjacent[chosen][neighbor]) --degree[neighbor];
    }
    for (std::size_t vertex = 0; vertex < n; ++vertex) storeI64LE(output + 8 * vertex, rank[vertex]);
    return static_cast<std::int64_t>(8 * n);
}
