#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t lovasz_toggle_defective_coloring_trace(
    const std::int64_t* input, std::size_t length) {
    constexpr int max_n = 16;
    constexpr int max_m = 120;
    constexpr std::size_t max_parseable_input = 246;
    if (input == nullptr || length < 5 || length > max_parseable_input) return -1;
    const std::int64_t n64 = input[0], r64 = input[1], b64 = input[2];
    const std::int64_t initial_mask = input[3], m64 = input[4];
    if (n64 < 0 || n64 > max_n || r64 < 1 || r64 > 8 || b64 < 1 || b64 > 8 ||
        m64 < 0 || m64 > max_m) return -1;
    const int n = static_cast<int>(n64);
    const int red_limit = static_cast<int>(r64);
    const int blue_limit = static_cast<int>(b64);
    const int m = static_cast<int>(m64);
    const std::int64_t valid_bits = (std::int64_t{1} << n) - 1;
    if (initial_mask < 0 || (initial_mask & ~valid_bits) != 0 ||
        length != 5 + 2 * static_cast<std::size_t>(m)) return -1;

    std::array<std::array<bool, max_n>, max_n> adjacent{};
    std::array<int, max_n> degree{};
    for (int edge = 0; edge < m; ++edge) {
        const std::int64_t u64 = input[5 + 2 * static_cast<std::size_t>(edge)];
        const std::int64_t v64 = input[6 + 2 * static_cast<std::size_t>(edge)];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return -1;
        const int u = static_cast<int>(u64), v = static_cast<int>(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = true;
        if (++degree[u] > red_limit + blue_limit + 1 ||
            ++degree[v] > red_limit + blue_limit + 1) return -1;
    }

    std::int64_t red_mask = initial_mask;
    int toggle_count = 0;
    for (;;) {
        int bad_vertex = -1;
        for (int v = 0; v < n; ++v) {
            int red_degree = 0;
            for (int u = 0; u < n; ++u)
                if (adjacent[v][u] && ((red_mask >> u) & 1) != 0) ++red_degree;
            const int blue_degree = degree[v] - red_degree;
            const bool is_red = ((red_mask >> v) & 1) != 0;
            if ((is_red && red_degree > red_limit) ||
                (!is_red && blue_degree > blue_limit)) {
                bad_vertex = v;
                break;
            }
        }
        if (bad_vertex < 0) break;
        red_mask ^= std::int64_t{1} << bad_vertex;
        ++toggle_count;
    }
    return (static_cast<std::int64_t>(toggle_count) << n) | red_mask;
}
