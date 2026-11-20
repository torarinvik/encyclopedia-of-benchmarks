#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t undirected_eulerian_trail_hierholzer(
    const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 2 || length > 67 || input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 32) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * m) return -1;
    std::array<std::array<std::size_t, 2>, 32> endpoints{};
    std::array<std::array<std::size_t, 64>, 16> adjacency{};
    std::array<std::size_t, 16> degree{}, cursor{};
    for (std::size_t e = 0; e < m; ++e) {
        const auto u0 = input[2 + 2 * e]; const auto v0 = input[3 + 2 * e];
        if (u0 < 0 || v0 < 0 || u0 >= static_cast<std::int64_t>(n) || v0 >= static_cast<std::int64_t>(n)) return -1;
        const auto u = static_cast<std::size_t>(u0); const auto v = static_cast<std::size_t>(v0);
        endpoints[e] = {u, v}; adjacency[u][degree[u]++] = e; adjacency[v][degree[v]++] = e;
    }
    std::size_t odd = 0, start = 0;
    for (std::size_t v = 0; v < n; ++v) if (degree[v] % 2 != 0) { if (odd == 0) start = v; ++odd; }
    if (odd != 0 && odd != 2) return 0;
    if (odd == 0 && m != 0) while (degree[start] == 0) ++start;
    std::array<bool, 32> used{};
    std::array<std::size_t, 33> stack{}, reverse{};
    std::size_t top = 1, count = 0; stack[0] = start;
    while (top != 0) {
        const auto v = stack[top - 1];
        while (cursor[v] < degree[v] && used[adjacency[v][cursor[v]]]) ++cursor[v];
        if (cursor[v] == degree[v]) reverse[count++] = stack[--top];
        else {
            const auto e = adjacency[v][cursor[v]++]; used[e] = true;
            stack[top++] = endpoints[e][0] == v ? endpoints[e][1] : endpoints[e][0];
        }
    }
    if (count != m + 1) return 0;
    const auto bytes = count * 8;
    if (!output || capacity < bytes) return -2;
    for (std::size_t i = 0; i < count; ++i) {
        const auto value = static_cast<std::uint64_t>(reverse[count - 1 - i]);
        for (std::size_t b = 0; b < 8; ++b) output[8 * i + b] = static_cast<std::uint8_t>(value >> (8 * b));
    }
    return static_cast<std::int64_t>(bytes);
}
