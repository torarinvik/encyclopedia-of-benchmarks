#include <cstddef>
#include <cstdint>

namespace {
struct Edge { std::size_t u, v; std::int64_t weight; bool used; };
void put_i64(std::uint8_t* out, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[word * 8 + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t approximate_matching_greedy(const std::int64_t* input, std::size_t length,
                                                      std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 2 || length > 98) return -1;
    const auto n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > 12 || m0 < 0 || m0 > 32 || length != 2 + 3 * static_cast<std::size_t>(m0)) return -1;
    const auto m = static_cast<std::size_t>(m0);
    bool seen[12][12]{}; bool matched[12]{}; Edge edges[32]{};
    for (std::size_t i = 0; i < m; ++i) {
        const auto u0 = input[2 + 3*i], v0 = input[3 + 3*i], weight = input[4 + 3*i];
        if (u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0 || weight < 1 || weight > 100) return -1;
        const auto u = static_cast<std::size_t>(u0), v = static_cast<std::size_t>(v0);
        const auto lo = u < v ? u : v, hi = u < v ? v : u;
        if (seen[lo][hi]) return -1;
        seen[lo][hi] = true; edges[i] = {u, v, weight, false};
    }
    if (!output || capacity < 16) return -2;
    std::int64_t total = 0; std::uint64_t selected = 0;
    for (std::size_t step = 0; step < m; ++step) {
        auto best = m;
        for (std::size_t i = 0; i < m; ++i)
            if (!edges[i].used && (best == m || edges[i].weight > edges[best].weight)) best = i;
        edges[best].used = true; const auto edge = edges[best];
        if (!matched[edge.u] && !matched[edge.v]) {
            matched[edge.u] = matched[edge.v] = true;
            selected |= std::uint64_t{1} << best; total += edge.weight;
        }
    }
    put_i64(output, 0, total); put_i64(output, 1, static_cast<std::int64_t>(selected));
    return 16;
}
