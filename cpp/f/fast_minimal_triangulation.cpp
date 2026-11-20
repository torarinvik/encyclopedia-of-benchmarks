#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 8, M = 28, INPUT = 59;
using Graph = std::array<std::uint16_t, N>;

void put_word(std::uint8_t *out, std::size_t at, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (int b = 0; b < 8; ++b) out[at + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}

std::uint64_t fmt(std::uint16_t vertices, const Graph &graph) {
    bool complete = true;
    for (int u = 0; u < N; ++u) if ((vertices >> u) & 1u) {
        const auto others = static_cast<std::uint16_t>(vertices & ~(1u << u));
        if ((graph[u] & others) != others) complete = false;
    }
    if (complete) return 0;
    int pivot = -1;
    for (int u = 0; u < N && pivot < 0; ++u) if ((vertices >> u) & 1u) {
        const auto others = static_cast<std::uint16_t>(vertices & ~(1u << u));
        if ((graph[u] & others) != others) pivot = u;
    }
    const auto region_a = static_cast<std::uint16_t>((1u << pivot) | (graph[pivot] & vertices));
    auto unseen = static_cast<std::uint16_t>(vertices & ~region_a);
    std::array<std::uint16_t, N> components{};
    std::array<std::uint16_t, N> closures{};
    int component_count = 0;
    while (unseen) {
        int seed = 0; while (((unseen >> seed) & 1u) == 0) ++seed;
        auto comp = static_cast<std::uint16_t>(1u << seed);
        unseen = static_cast<std::uint16_t>(unseen & ~comp);
        auto frontier = comp;
        while (frontier) {
            int u = 0; while (((frontier >> u) & 1u) == 0) ++u;
            frontier = static_cast<std::uint16_t>(frontier & ~(1u << u));
            const auto add = static_cast<std::uint16_t>(graph[u] & unseen);
            comp |= add; frontier |= add; unseen = static_cast<std::uint16_t>(unseen & ~add);
        }
        components[component_count++] = comp;
    }
    Graph saturated = graph;
    std::uint64_t result = 0;
    for (int ci = 0; ci < component_count; ++ci) {
        const auto comp = components[ci];
        std::uint16_t boundary = 0;
        for (int u = 0; u < N; ++u) if ((comp >> u) & 1u)
            boundary |= static_cast<std::uint16_t>(graph[u] & vertices & ~comp);
        closures[ci] = static_cast<std::uint16_t>(comp | boundary);
        for (int u = 0; u < N; ++u) if ((boundary >> u) & 1u)
            for (int v = u + 1; v < N; ++v) if ((boundary >> v) & 1u) {
                if (((saturated[u] >> v) & 1u) == 0) {
                    saturated[u] |= static_cast<std::uint16_t>(1u << v);
                    saturated[v] |= static_cast<std::uint16_t>(1u << u);
                    result |= std::uint64_t{1} << (u * N + v);
                }
            }
    }
    result |= fmt(region_a, saturated);
    for (int ci = 0; ci < component_count; ++ci) result |= fmt(closures[ci], saturated);
    return result;
}
} // namespace

extern "C" std::int64_t fast_minimal_triangulation(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > INPUT) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > N || m64 < 0 || m64 > M || length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const int n = static_cast<int>(n64), m = static_cast<int>(m64);
    Graph graph{};
    std::uint64_t original = 0;
    std::int64_t previous_u = -1, previous_v = -1;
    for (int i = 0; i < m; ++i) {
        const auto u64 = input[2 + 2 * i], v64 = input[3 + 2 * i];
        if (u64 < 0 || v64 <= u64 || v64 >= n64 || u64 < previous_u ||
            (u64 == previous_u && v64 <= previous_v)) return -1;
        const int u = static_cast<int>(u64), v = static_cast<int>(v64);
        previous_u = u64; previous_v = v64;
        graph[u] |= static_cast<std::uint16_t>(1u << v);
        graph[v] |= static_cast<std::uint16_t>(1u << u);
        original |= std::uint64_t{1} << (u * N + v);
    }
    const auto all = static_cast<std::uint16_t>((1u << n) - 1u);
    const auto fill = fmt(all, graph) & ~original;
    int count = 0;
    for (int u = 0; u < n; ++u) for (int v = u + 1; v < n; ++v)
        if ((fill >> (u * N + v)) & 1u) ++count;
    const std::size_t bytes = 8u * (1u + 2u * static_cast<std::size_t>(count));
    if (output == nullptr || capacity < bytes) return -2;
    put_word(output, 0, count);
    int index = 1;
    for (int u = 0; u < n; ++u) for (int v = u + 1; v < n; ++v)
        if ((fill >> (u * N + v)) & 1u) { put_word(output, 8u * index++, u); put_word(output, 8u * index++, v); }
    return static_cast<std::int64_t>(bytes);
}
