#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 16, max_m = 64, max_input = 2 + 2 * max_m;
void compress_components(std::size_t n, int *component) {
    for (std::size_t node = 0; node < n; ++node)
        while (component[node] != component[component[node]])
            component[node] = component[component[node]];
}
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & UINT64_C(255));
        bits >>= 8;
    }
}
}

extern "C" std::int64_t gapbs_shiloach_vishkin_components(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(max_n) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(max_m) || length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::uint8_t adjacency[max_n][max_n]{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto pos = 2 + 2 * edge;
        const auto u = input[pos], v = input[pos + 1];
        if (u < 0 || v <= u || v >= n64 || adjacency[u][v]) return -1;
        adjacency[u][v] = adjacency[v][u] = 1;
    }
    const auto output_bytes = 8 * n;
    if (output == nullptr || capacity < output_bytes) return -2;
    int component[max_n];
    for (std::size_t node = 0; node < n; ++node) component[node] = static_cast<int>(node);
    bool changed = true;
    std::size_t rounds = 0;
    const std::size_t round_limit = n * n + 1;
    while (changed && rounds < round_limit) {
        changed = false;
        for (std::size_t u = 0; u < n; ++u) {
            for (std::size_t v = 0; v < n; ++v) {
                if (!adjacency[u][v]) continue;
                const int component_u = component[u], component_v = component[v];
                if (component_u == component_v) continue;
                const int high = component_u > component_v ? component_u : component_v;
                const int low = component_u + (component_v - high);
                if (component[high] == high) { changed = true; component[high] = low; }
            }
        }
        compress_components(n, component);
        ++rounds;
    }
    if (changed) return -1;
    for (std::size_t node = 0; node < n; ++node)
        store_i64_le(output, 8 * node, component[node]);
    return static_cast<std::int64_t>(output_bytes);
}
