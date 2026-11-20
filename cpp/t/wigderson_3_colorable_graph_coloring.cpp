#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 32;
constexpr std::size_t max_edges = 128;
constexpr std::size_t max_input = 2 + 2 * max_edges;
}

extern "C" std::int64_t wigderson_3_colorable_graph_coloring(
        const std::int64_t* input, std::size_t length,
        std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input + 1) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_vertices)
            || input[1] < 0 || input[1] > static_cast<std::int64_t>(max_edges)) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    const std::size_t m = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * m) return -1;

    std::array<std::array<bool, max_vertices>, max_vertices> adjacent{};
    for (std::size_t e = 0; e < m; ++e) {
        const auto raw_u = input[2 + 2 * e];
        const auto raw_v = input[3 + 2 * e];
        if (raw_u < 0 || raw_v <= raw_u || raw_v >= static_cast<std::int64_t>(n)) return -1;
        const auto u = static_cast<std::size_t>(raw_u);
        const auto v = static_cast<std::size_t>(raw_v);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = true;
    }

    std::array<bool, max_vertices> active{};
    std::array<std::uint8_t, max_vertices> colors{};
    std::fill_n(active.begin(), n, true);
    std::size_t threshold = 0;
    while ((threshold + 1) * (threshold + 1) <= n) ++threshold;
    std::int64_t next_color = 1;

    while (true) {
        std::size_t chosen = n;
        std::size_t maximum_degree = 0;
        for (std::size_t v = 0; v < n; ++v) {
            if (!active[v]) continue;
            std::size_t degree = 0;
            for (std::size_t w = 0; w < n; ++w)
                if (active[w] && adjacent[v][w]) ++degree;
            if (chosen == n || degree > maximum_degree) {
                chosen = v;
                maximum_degree = degree;
            }
        }
        if (chosen == n || maximum_degree < threshold) break;

        std::array<bool, max_vertices> in_neighborhood{};
        std::array<std::int8_t, max_vertices> side{};
        side.fill(-1);
        std::array<std::size_t, max_vertices> queue{};
        for (std::size_t v = 0; v < n; ++v)
            in_neighborhood[v] = active[v] && adjacent[chosen][v];
        for (std::size_t root = 0; root < n; ++root) {
            if (!in_neighborhood[root] || side[root] >= 0) continue;
            std::size_t head = 0;
            std::size_t tail = 0;
            side[root] = 0;
            queue[tail++] = root;
            while (head < tail) {
                const std::size_t u = queue[head++];
                for (std::size_t v = 0; v < n; ++v) {
                    if (!in_neighborhood[v] || !adjacent[u][v]) continue;
                    if (side[v] < 0) {
                        side[v] = static_cast<std::int8_t>(1 - side[u]);
                        queue[tail++] = v;
                    } else if (side[v] == side[u]) {
                        return -1;
                    }
                }
            }
        }
        for (std::size_t v = 0; v < n; ++v)
            if (in_neighborhood[v]) colors[v] = static_cast<std::uint8_t>(next_color + side[v]);
        colors[chosen] = static_cast<std::uint8_t>(next_color + 2);
        active[chosen] = false;
        for (std::size_t v = 0; v < n; ++v)
            if (adjacent[chosen][v]) active[v] = false;
        next_color += 2;
    }

    for (std::size_t v = 0; v < n; ++v) {
        if (!active[v]) continue;
        std::array<bool, max_vertices + 2> forbidden{};
        for (std::size_t w = 0; w < n; ++w)
            if (adjacent[v][w] && colors[w] > 0) forbidden[colors[w]] = true;
        std::size_t candidate = static_cast<std::size_t>(next_color);
        while (candidate < forbidden.size() && forbidden[candidate]) ++candidate;
        if (candidate >= forbidden.size()) return -1;
        colors[v] = static_cast<std::uint8_t>(candidate);
    }

    const std::uint8_t palette = n == 0 ? 0 :
        *std::max_element(colors.begin(), colors.begin() + n);
    const std::size_t output_bytes = n + 1;
    if (output == nullptr || capacity < output_bytes) return -2;
    output[0] = palette;
    std::copy_n(colors.begin(), n, output + 1);
    return static_cast<std::int64_t>(output_bytes);
}
