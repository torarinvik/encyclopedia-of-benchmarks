#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxVertices = 64;
constexpr int kMaxEdges = 128;
constexpr int kMaxArcs = 2 * kMaxEdges;
constexpr std::size_t kMaxInputLength = 2 + 2 * kMaxEdges + 1;

struct Graph {
    std::array<int, kMaxVertices> head{};
    std::array<int, kMaxVertices> tail{};
    std::array<int, kMaxArcs> to{};
    std::array<int, kMaxArcs> next{};
    std::array<int, kMaxArcs> arc_edge{};
    std::array<int, kMaxEdges> edge_u{};
    std::array<bool, kMaxEdges> edge_used{};
    std::array<int, kMaxEdges> direction{};
    std::array<int, kMaxVertices> discovery{};
    std::array<int, kMaxVertices> low{};
    int timer = 0;
    int bridges = 0;

    void append_arc(int from, int target, int edge, int& arc_count) noexcept {
        const int arc = arc_count++;
        to[arc] = target;
        arc_edge[arc] = edge;
        next[arc] = -1;
        if (head[from] == -1) head[from] = arc;
        else next[tail[from]] = arc;
        tail[from] = arc;
    }

    void visit(int vertex) noexcept {
        discovery[vertex] = low[vertex] = timer++;
        for (int arc = head[vertex]; arc != -1; arc = next[arc]) {
            const int edge = arc_edge[arc];
            if (edge_used[edge]) continue;
            edge_used[edge] = true;
            direction[edge] = vertex == edge_u[edge] ? 1 : -1;
            const int neighbor = to[arc];
            if (discovery[neighbor] == -1) {
                visit(neighbor);
                if (low[neighbor] < low[vertex]) low[vertex] = low[neighbor];
                if (low[neighbor] > discovery[vertex]) ++bridges;
            } else if (discovery[neighbor] < low[vertex]) {
                low[vertex] = discovery[neighbor];
            }
        }
    }
};

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>((bits >> (byte * 8)) & 0xffu);
}
} // namespace

extern "C" std::int64_t strong_orientation(const std::int64_t* input, std::size_t length,
                                             std::uint8_t* output,
                                             std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const std::int64_t raw_vertices = input[0], raw_edges = input[1];
    if (raw_vertices < 1 || raw_vertices > kMaxVertices || raw_edges < 0 || raw_edges > kMaxEdges)
        return -1;
    const auto vertex_count = static_cast<std::size_t>(raw_vertices);
    const auto edge_count = static_cast<std::size_t>(raw_edges);
    if (length != 2 + 2 * edge_count) return -1;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto left = input[2 + 2 * edge], right = input[3 + 2 * edge];
        if (left < 0 || right < 0 || left >= raw_vertices || right >= raw_vertices) return -1;
    }
    const std::size_t output_bytes = 8 * (edge_count + 1);
    if (output == nullptr || output_capacity < output_bytes) return -2;

    Graph graph{};
    graph.head.fill(-1);
    graph.tail.fill(-1);
    graph.discovery.fill(-1);
    int arc_count = 0;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const int left = static_cast<int>(input[2 + 2 * edge]);
        const int right = static_cast<int>(input[3 + 2 * edge]);
        graph.edge_u[edge] = left;
        graph.append_arc(left, right, static_cast<int>(edge), arc_count);
        graph.append_arc(right, left, static_cast<int>(edge), arc_count);
    }
    int components = 0;
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
        if (graph.discovery[vertex] == -1) {
            ++components;
            graph.visit(static_cast<int>(vertex));
        }
    }
    store_i64_le(output, 0, components + graph.bridges);
    for (std::size_t edge = 0; edge < edge_count; ++edge)
        store_i64_le(output, 8 * (edge + 1), graph.direction[edge]);
    return static_cast<std::int64_t>(output_bytes);
}
