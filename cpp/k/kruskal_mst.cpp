#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 64;
constexpr std::size_t max_edges = max_vertices * (max_vertices - 1) / 2;
constexpr std::size_t max_valid_input_length = 6050;
constexpr std::size_t max_parseable_input_length = max_valid_input_length + 1;
constexpr std::int64_t min_weight = -1'000'000;
constexpr std::int64_t max_weight = 1'000'000;
constexpr std::uint64_t fnv_offset = 14695981039346656037ULL;
constexpr std::uint64_t fnv_prime = 1099511628211ULL;

struct Edge { std::uint16_t u; std::uint16_t v; std::int32_t weight; };

int find_root(int* parent, int node)
{
    int root = node;
    while (parent[root] != root) root = parent[root];
    while (parent[node] != node) {
        int next = parent[node];
        parent[node] = root;
        node = next;
    }
    return root;
}

void hash_byte(std::uint64_t& hash, std::uint8_t byte)
{
    hash = (hash ^ byte) * fnv_prime;
}

void hash_u16(std::uint64_t& hash, std::uint16_t value)
{
    for (unsigned int byte = 0; byte < 2; ++byte)
        hash_byte(hash, static_cast<std::uint8_t>(value >> (8 * byte)));
}

void hash_i32(std::uint64_t& hash, std::int32_t value)
{
    const std::uint32_t bits = static_cast<std::uint32_t>(value);
    for (unsigned int byte = 0; byte < 4; ++byte)
        hash_byte(hash, static_cast<std::uint8_t>(bits >> (8 * byte)));
}

void hash_i64(std::uint64_t& hash, std::int64_t value)
{
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (unsigned int byte = 0; byte < 8; ++byte)
        hash_byte(hash, static_cast<std::uint8_t>(bits >> (8 * byte)));
}
}

extern "C" std::int64_t kruskal_mst(const std::int64_t* input, std::size_t length)
{
    if (input == nullptr || length < 2 || length > max_parseable_input_length) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_vertices) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_edges)) return -1;
    const int vertex_count = static_cast<int>(input[0]);
    const int edge_count = static_cast<int>(input[1]);
    if (length != 2 + static_cast<std::size_t>(edge_count) * 3 || length > max_valid_input_length) return -1;
    const int max_for_graph = vertex_count * (vertex_count - 1) / 2;
    if (edge_count > max_for_graph || (vertex_count == 1 ? edge_count != 0 : edge_count < vertex_count - 1)) return -1;

    Edge edges[max_edges];
    bool seen_pairs[max_vertices][max_vertices] = {};
    for (int index = 0; index < edge_count; ++index) {
        const std::size_t base = 2 + static_cast<std::size_t>(index) * 3;
        const std::int64_t raw_u = input[base];
        const std::int64_t raw_v = input[base + 1];
        const std::int64_t raw_weight = input[base + 2];
        if (raw_u < 0 || raw_u >= vertex_count || raw_v < 0 || raw_v >= vertex_count ||
            raw_u == raw_v || raw_weight < min_weight || raw_weight > max_weight) return -1;
        const auto u = static_cast<std::uint16_t>(std::min(raw_u, raw_v));
        const auto v = static_cast<std::uint16_t>(std::max(raw_u, raw_v));
        if (seen_pairs[u][v]) return -1;
        seen_pairs[u][v] = true;
        edges[index] = Edge{u, v, static_cast<std::int32_t>(raw_weight)};
    }
    std::sort(edges, edges + edge_count, [](const Edge& left, const Edge& right) {
        return left.weight < right.weight;
    });
    for (int index = 1; index < edge_count; ++index)
        if (edges[index - 1].weight == edges[index].weight) return -1;

    int parent[max_vertices];
    int rank[max_vertices] = {};
    for (int vertex = 0; vertex < vertex_count; ++vertex) parent[vertex] = vertex;
    Edge selected[max_vertices - 1];
    int selected_count = 0;
    std::int64_t total_weight = 0;
    for (int index = 0; index < edge_count && selected_count < vertex_count - 1; ++index) {
        const int left = find_root(parent, edges[index].u);
        const int right = find_root(parent, edges[index].v);
        if (left == right) continue;
        if (rank[left] < rank[right]) parent[left] = right;
        else if (rank[left] > rank[right]) parent[right] = left;
        else { parent[right] = left; ++rank[left]; }
        selected[selected_count++] = edges[index];
        total_weight += edges[index].weight;
    }
    if (selected_count != vertex_count - 1) return -1;

    std::uint64_t hash = fnv_offset;
    hash_u16(hash, static_cast<std::uint16_t>(vertex_count));
    hash_u16(hash, static_cast<std::uint16_t>(selected_count));
    for (int index = 0; index < selected_count; ++index) {
        hash_u16(hash, selected[index].u);
        hash_u16(hash, selected[index].v);
        hash_i32(hash, selected[index].weight);
    }
    hash_i64(hash, total_weight);
    return static_cast<std::int64_t>(hash & 0x7fffffffffffffffULL);
}
