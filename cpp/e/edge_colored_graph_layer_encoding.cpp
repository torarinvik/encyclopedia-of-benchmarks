#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 8, MaxM = 28, MaxVertices = 24, MaxInput = 97;

void put(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t edge_colored_graph_layer_encoding(
        const std::int64_t* input, std::size_t length,
        std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 5 || length > MaxInput) return -1;
    const auto n0 = input[0], m0 = input[1], d0 = input[2], q0 = input[3];
    if (n0 < 1 || n0 > 8 || m0 < 0 || m0 > 28 || d0 < 1 || d0 > 3 || q0 < 1 || q0 > 3) return -1;
    const auto n = static_cast<std::size_t>(n0), m = static_cast<std::size_t>(m0);
    const auto layers = static_cast<std::size_t>(d0), classes = static_cast<std::size_t>(q0);
    const auto edgeOffset = 4 + n;
    if (length != edgeOffset + 3 * m) return -1;
    std::array<std::int64_t, MaxN> sourceColor{};
    for (std::size_t v = 0; v < n; ++v) {
        sourceColor[v] = input[4 + v];
        if (sourceColor[v] < 0 || sourceColor[v] >= q0) return -1;
    }
    std::array<std::array<std::uint8_t, MaxN>, MaxN> edgeColor{};
    for (std::size_t offset = edgeOffset; offset < length; offset += 3) {
        auto u0 = input[offset], v0 = input[offset + 1], color = input[offset + 2];
        if (u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0 || color < 1 || color >= (1LL << d0)) return -1;
        auto u = static_cast<std::size_t>(u0), v = static_cast<std::size_t>(v0);
        if (u > v) { auto temp = u; u = v; v = temp; }
        if (edgeColor[u][v] != 0) return -1;
        edgeColor[u][v] = static_cast<std::uint8_t>(color);
    }
    const auto nodes = n * layers;
    std::array<std::array<bool, MaxVertices>, MaxVertices> adjacency{};
    for (std::size_t layer = 0; layer < layers; ++layer)
        for (std::size_t u = 0; u < n; ++u)
            for (std::size_t v = u + 1; v < n; ++v)
                if ((edgeColor[u][v] & (1U << layer)) != 0)
                    adjacency[layer * n + u][layer * n + v] = true;
    for (std::size_t v = 0; v < n; ++v)
        for (std::size_t layer = 0; layer + 1 < layers; ++layer)
            adjacency[layer * n + v][(layer + 1) * n + v] = true;
    std::size_t edgeCount = 0;
    for (std::size_t u = 0; u < nodes; ++u)
        for (std::size_t v = u + 1; v < nodes; ++v)
            edgeCount += adjacency[u][v];
    const auto bytes = 8 * (2 + nodes + 2 * edgeCount);
    if (output == nullptr || capacity < bytes) return -2;
    put(output, 0, static_cast<std::int64_t>(nodes));
    put(output, 8, static_cast<std::int64_t>(edgeCount));
    std::size_t word = 2;
    for (std::size_t layer = 0; layer < layers; ++layer)
        for (std::size_t v = 0; v < n; ++v)
            put(output, 8 * word++, static_cast<std::int64_t>(layer * classes + sourceColor[v]));
    for (std::size_t u = 0; u < nodes; ++u)
        for (std::size_t v = u + 1; v < nodes; ++v)
            if (adjacency[u][v]) {
                put(output, 8 * word++, static_cast<std::int64_t>(u));
                put(output, 8 * word++, static_cast<std::int64_t>(v));
            }
    return static_cast<std::int64_t>(bytes);
}
