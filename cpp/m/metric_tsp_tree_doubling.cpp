#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t MaxN = 8, MaxInput = 65;
void storeI64LE(std::uint8_t* out, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) { out[offset + b] = static_cast<std::uint8_t>(bits & 255U); bits >>= 8; }
}
}

extern "C" std::int64_t metric_tsp_tree_doubling(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 2 || length > MaxInput) return -1;
    const auto n64 = input[0];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || length != 1 + static_cast<std::size_t>(n64 * n64)) return -1;
    const auto n = static_cast<std::size_t>(n64);
    std::int64_t d[MaxN][MaxN]{};
    for (std::size_t u = 0; u < n; ++u) for (std::size_t v = 0; v < n; ++v) {
        const auto w = input[1 + u * n + v];
        if (w < 0 || w > 10000 || (u == v && w != 0)) return -1;
        d[u][v] = w;
    }
    for (std::size_t u = 0; u < n; ++u) for (std::size_t v = u + 1; v < n; ++v) if (d[u][v] != d[v][u]) return -1;
    for (std::size_t u = 0; u < n; ++u) for (std::size_t v = 0; v < n; ++v)
        for (std::size_t k = 0; k < n; ++k) if (d[u][v] > d[u][k] + d[k][v]) return -1;
    const auto outputBytes = 8 * (n + 2);
    if (!output || capacity < outputBytes) return -2;
    bool processed[MaxN][MaxN]{}, tree[MaxN][MaxN]{};
    std::size_t parent[MaxN]{}, accepted = 0, edgeCount = n * (n - 1) / 2;
    for (std::size_t i = 0; i < n; ++i) parent[i] = i;
    for (std::size_t step = 0; step < edgeCount && accepted + 1 < n; ++step) {
        std::size_t bu = 0, bv = 0;
        auto bw = std::numeric_limits<std::int64_t>::max();
        for (std::size_t u = 0; u < n; ++u) for (std::size_t v = u + 1; v < n; ++v)
            if (!processed[u][v] && d[u][v] < bw) { bw = d[u][v]; bu = u; bv = v; }
        processed[bu][bv] = true;
        auto ru = bu, rv = bv;
        while (parent[ru] != ru) ru = parent[ru];
        while (parent[rv] != rv) rv = parent[rv];
        if (ru != rv) { parent[rv] = ru; tree[bu][bv] = tree[bv][bu] = true; ++accepted; }
    }
    std::size_t stack[MaxN]{}, order[MaxN]{}, top = 1, count = 0;
    bool visited[MaxN]{};
    stack[0] = 0;
    while (top > 0) {
        const auto v = stack[--top];
        if (visited[v]) continue;
        visited[v] = true; order[count++] = v;
        for (std::size_t rev = n; rev > 0; --rev) { const auto w = rev - 1; if (tree[v][w] && !visited[w]) stack[top++] = w; }
    }
    std::int64_t cost = 0;
    for (std::size_t i = 0; i + 1 < n; ++i) cost += d[order[i]][order[i + 1]];
    cost += d[order[n - 1]][0];
    storeI64LE(output, 0, cost);
    for (std::size_t i = 0; i < n; ++i) storeI64LE(output, 8 * (i + 1), static_cast<std::int64_t>(order[i]));
    storeI64LE(output, 8 * (n + 1), 0);
    return static_cast<std::int64_t>(outputBytes);
}
