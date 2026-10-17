#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 64;
constexpr std::size_t max_output_bytes = 1016;

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

int make_code(const std::int64_t *input, std::size_t n, std::int64_t *code) {
    bool adjacency[max_vertices][max_vertices]{};
    std::size_t degree[max_vertices]{};
    for (std::size_t edge = 0; edge + 1 < n; ++edge) {
        const auto raw_u = input[2 + edge * 2], raw_v = input[3 + edge * 2];
        if (raw_u < 0 || raw_v < 0 || raw_u >= static_cast<std::int64_t>(n) || raw_v >= static_cast<std::int64_t>(n) || raw_u == raw_v) return -1;
        const auto u = static_cast<std::size_t>(raw_u), v = static_cast<std::size_t>(raw_v);
        if (adjacency[u][v]) return -1;
        adjacency[u][v] = adjacency[v][u] = true;
        ++degree[u]; ++degree[v];
    }
    bool visited[max_vertices]{};
    std::size_t queue[max_vertices]{}, head = 0, tail = 0;
    visited[0] = true; queue[tail++] = 0;
    while (head < tail) {
        const auto u = queue[head++];
        for (std::size_t v = 0; v < n; ++v) if (adjacency[u][v] && !visited[v]) { visited[v] = true; queue[tail++] = v; }
    }
    if (tail != n) return -1;

    bool active[max_vertices]{};
    for (std::size_t v = 0; v < n; ++v) active[v] = true;
    for (std::size_t step = 0; step + 2 < n; ++step) {
        std::size_t leaf = n;
        for (std::size_t v = n; v > 0; --v) if (active[v - 1] && degree[v - 1] == 1) { leaf = v - 1; break; }
        if (leaf == n) return -1;
        std::size_t neighbor = n;
        for (std::size_t v = 0; v < n; ++v) if (active[v] && adjacency[leaf][v]) { neighbor = v; break; }
        if (neighbor == n) return -1;
        code[step] = static_cast<std::int64_t>(neighbor);
        active[leaf] = false; adjacency[leaf][neighbor] = adjacency[neighbor][leaf] = false; --degree[neighbor];
    }
    return static_cast<int>(n > 2 ? n - 2 : 0);
}

void add_edge(std::int64_t edges[max_vertices - 1][2], std::size_t index, std::size_t u, std::size_t v) {
    if (u < v) { edges[index][0] = static_cast<std::int64_t>(u); edges[index][1] = static_cast<std::int64_t>(v); }
    else { edges[index][0] = static_cast<std::int64_t>(v); edges[index][1] = static_cast<std::int64_t>(u); }
}

int make_decoded_edges(const std::int64_t *input, std::size_t n, std::int64_t edges[max_vertices - 1][2]) {
    std::size_t remaining[max_vertices]{};
    for (std::size_t i = 0; i + 2 < n; ++i) {
        const auto raw = input[2 + i];
        if (raw < 0 || raw >= static_cast<std::int64_t>(n)) return -1;
        ++remaining[static_cast<std::size_t>(raw)];
    }
    bool active[max_vertices]{};
    for (std::size_t v = 0; v < n; ++v) active[v] = true;
    std::size_t out = 0;
    for (std::size_t i = 0; i + 2 < n; ++i) {
        std::size_t leaf = n;
        for (std::size_t v = n; v > 0; --v) if (active[v - 1] && remaining[v - 1] == 0) { leaf = v - 1; break; }
        if (leaf == n) return -1;
        const auto vertex = static_cast<std::size_t>(input[2 + i]);
        add_edge(edges, out++, leaf, vertex); active[leaf] = false; --remaining[vertex];
    }
    std::size_t first = n;
    for (std::size_t v = n; v > 0; --v) if (active[v - 1]) { first = v - 1; break; }
    if (first == n) return -1;
    active[first] = false;
    std::size_t second = n;
    for (std::size_t v = n; v > 0; --v) if (active[v - 1]) { second = v - 1; break; }
    if (second == n) return -1;
    add_edge(edges, out++, first, second);
    for (std::size_t i = 1; i < out; ++i) {
        const auto u = edges[i][0], v = edges[i][1];
        std::size_t j = i;
        while (j > 0 && (edges[j - 1][0] > u || (edges[j - 1][0] == u && edges[j - 1][1] > v))) {
            edges[j][0] = edges[j - 1][0]; edges[j][1] = edges[j - 1][1]; --j;
        }
        edges[j][0] = u; edges[j][1] = v;
    }
    return static_cast<int>(out);
}
}

extern "C" std::int64_t prufer_code(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > 129) return -1;
    const auto mode = input[0], raw_n = input[1];
    if (raw_n < 1 || raw_n > static_cast<std::int64_t>(max_vertices) || (mode != 0 && mode != 1)) return -1;
    const auto n = static_cast<std::size_t>(raw_n);
    if (mode == 0) {
        if (length != 2 * n) return -1;
        std::int64_t code[max_vertices]{};
        const int code_length = make_code(input, n, code);
        if (code_length < 0) return -1;
        const auto needed = static_cast<std::size_t>(code_length) * 8;
        if (needed == 0) return 0;
        if (output == nullptr || capacity < needed) return -2;
        for (int i = 0; i < code_length; ++i) write_i64_le(output, static_cast<std::size_t>(i) * 8, code[i]);
        return static_cast<std::int64_t>(needed);
    }
    if (n < 2 || length != n) return -1;
    std::int64_t edges[max_vertices - 1][2]{};
    const int edge_count = make_decoded_edges(input, n, edges);
    if (edge_count < 0) return -1;
    const auto needed = 8 + static_cast<std::size_t>(edge_count) * 16;
    if (needed > max_output_bytes) return -1;
    if (output == nullptr || capacity < needed) return -2;
    write_i64_le(output, 0, edge_count);
    for (int i = 0; i < edge_count; ++i) {
        write_i64_le(output, 8 + static_cast<std::size_t>(i) * 16, edges[i][0]);
        write_i64_le(output, 16 + static_cast<std::size_t>(i) * 16, edges[i][1]);
    }
    return static_cast<std::int64_t>(needed);
}
