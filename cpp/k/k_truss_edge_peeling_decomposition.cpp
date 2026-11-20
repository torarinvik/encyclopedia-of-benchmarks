// Clean-room bounded edge-peeling truss decomposition.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 16, MaxM = 120, MaxParseableInput = 243;
void storeI64LE(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t k_truss_edge_peeling_decomposition(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 2 || length > MaxParseableInput) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > 16 || m64 < 0 || m64 > 120 ||
        length != 2 + 2 * static_cast<std::size_t>(m64) || length > 242) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::array<std::array<bool, MaxN>, MaxN> adjacent{};
    std::array<std::array<int, MaxN>, MaxN> edgeIndex{};
    for (auto& row : edgeIndex) row.fill(-1);
    std::array<int, MaxM> edgeU{}, edgeV{}, support{};
    std::array<bool, MaxM> alive{};
    std::array<std::int64_t, MaxM> trussness{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = true;
        edgeIndex[u][v] = edgeIndex[v][u] = static_cast<int>(edge);
        edgeU[edge] = static_cast<int>(u);
        edgeV[edge] = static_cast<int>(v);
        alive[edge] = true;
    }
    for (std::size_t u = 0; u < n; ++u)
        for (std::size_t v = u + 1; v < n; ++v)
            for (std::size_t w = v + 1; w < n; ++w)
                if (adjacent[u][v] && adjacent[u][w] && adjacent[v][w]) {
                    ++support[edgeIndex[u][v]];
                    ++support[edgeIndex[u][w]];
                    ++support[edgeIndex[v][w]];
                }
    const auto outputBytes = 8 * m;
    if (!output || capacity < outputBytes) return -2;
    std::size_t remaining = m;
    int level = 0;
    while (remaining > 0) {
        int selected = -1;
        for (std::size_t edge = 0; edge < m; ++edge)
            if (alive[edge] && (selected < 0 || support[edge] < support[static_cast<std::size_t>(selected)]))
                selected = static_cast<int>(edge);
        level = std::max(level, support[static_cast<std::size_t>(selected)]);
        trussness[static_cast<std::size_t>(selected)] = level + 2;
        alive[static_cast<std::size_t>(selected)] = false;
        --remaining;
        const auto u = static_cast<std::size_t>(edgeU[static_cast<std::size_t>(selected)]);
        const auto v = static_cast<std::size_t>(edgeV[static_cast<std::size_t>(selected)]);
        for (std::size_t w = 0; w < n; ++w) {
            if (w == u || w == v || !adjacent[u][w] || !adjacent[v][w]) continue;
            const int first = edgeIndex[u][w], second = edgeIndex[v][w];
            if (alive[static_cast<std::size_t>(first)] && alive[static_cast<std::size_t>(second)]) {
                if (support[static_cast<std::size_t>(first)] > level) --support[static_cast<std::size_t>(first)];
                if (support[static_cast<std::size_t>(second)] > level) --support[static_cast<std::size_t>(second)];
            }
        }
    }
    for (std::size_t edge = 0; edge < m; ++edge) storeI64LE(output, 8 * edge, trussness[edge]);
    return static_cast<std::int64_t>(outputBytes);
}
