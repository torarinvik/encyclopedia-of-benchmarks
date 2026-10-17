#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 16;
constexpr std::size_t max_edges = 64;
constexpr std::size_t max_input_words = 194;
constexpr std::size_t max_output_words = 1 + 3 * (max_vertices - 1);
constexpr std::size_t max_output_bytes = 4 * max_output_words;
struct Edge { std::int32_t u, v, weight; };

std::int32_t find_root(std::int32_t* parent, std::int32_t node) {
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

void put_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t minimum_spanning_tree_kruskal2(const std::int32_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input_words) return -1;
    const auto vertex_count = input[0], edge_count = input[1];
    if (vertex_count < 1 || vertex_count > static_cast<std::int32_t>(max_vertices) ||
        edge_count < 0 || edge_count > static_cast<std::int32_t>(max_edges) ||
        length != 2 + 3 * static_cast<std::size_t>(edge_count)) return -1;

    Edge input_edges[max_edges];
    bool seen[max_vertices][max_vertices] = {};
    std::size_t pos = 2;
    for (std::int32_t i = 0; i < edge_count; ++i) {
        const auto u = input[pos++], v = input[pos++], weight = input[pos++];
        if (u < 0 || v <= u || v >= vertex_count || seen[u][v]) return -1;
        seen[u][v] = true;
        input_edges[i] = {u, v, weight};
    }

    std::int32_t parent[max_vertices], rank[max_vertices] = {};
    for (std::int32_t i = 0; i < vertex_count; ++i) parent[i] = i;
    for (std::int32_t i = 0; i < edge_count; ++i) {
        const auto root_u = find_root(parent, input_edges[i].u);
        const auto root_v = find_root(parent, input_edges[i].v);
        if (root_u != root_v) parent[root_u] = root_v;
    }
    for (std::int32_t i = 1; i < vertex_count; ++i)
        if (find_root(parent, i) != find_root(parent, 0)) return -1;

    Edge ordered[max_edges];
    std::size_t ordered_count = 0;
    for (std::int32_t u = 0; u < vertex_count; ++u)
        for (std::int32_t i = 0; i < edge_count; ++i)
            if (input_edges[i].u == u) ordered[ordered_count++] = input_edges[i];
    for (std::size_t i = 1; i < ordered_count; ++i) {
        const auto key = ordered[i];
        std::size_t j = i;
        while (j > 0 && ordered[j - 1].weight > key.weight) {
            ordered[j] = ordered[j - 1];
            --j;
        }
        ordered[j] = key;
    }

    for (std::int32_t i = 0; i < vertex_count; ++i) parent[i] = i, rank[i] = 0;
    std::int32_t words[max_output_words] = {};
    std::size_t word_count = 1, accepted = 0;
    for (std::size_t i = 0; i < ordered_count && accepted < static_cast<std::size_t>(vertex_count - 1); ++i) {
        const auto root_u = find_root(parent, ordered[i].u);
        const auto root_v = find_root(parent, ordered[i].v);
        if (root_u == root_v) continue;
        if (rank[root_u] < rank[root_v]) parent[root_u] = root_v;
        else if (rank[root_u] > rank[root_v]) parent[root_v] = root_u;
        else { parent[root_u] = root_v; ++rank[root_v]; }
        words[word_count++] = ordered[i].u;
        words[word_count++] = ordered[i].v;
        words[word_count++] = ordered[i].weight;
        ++accepted;
    }
    if (accepted != static_cast<std::size_t>(vertex_count - 1)) return -1;
    words[0] = static_cast<std::int32_t>(accepted);
    const auto bytes = word_count * 4;
    if (bytes > max_output_bytes || output == nullptr || capacity < bytes) return -2;
    std::uint8_t buffer[max_output_bytes];
    for (std::size_t i = 0; i < word_count; ++i) put_i32_le(buffer, i * 4, words[i]);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return static_cast<std::int64_t>(bytes);
}
