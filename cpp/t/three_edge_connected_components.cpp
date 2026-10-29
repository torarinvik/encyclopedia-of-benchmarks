#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxVertices = 8;
constexpr std::size_t kMaxEdges = 32;
constexpr std::size_t kMaxInputLength = 2 + 2 * kMaxEdges;

struct Edge {
    std::size_t from = 0;
    std::size_t to = 0;
};

using SameMatrix = std::array<std::array<bool, kMaxVertices>, kMaxVertices>;

void refine_for_removal(const std::array<Edge, kMaxEdges> &edges,
                        std::size_t vertex_count, std::size_t edge_count,
                        int removed_first, int removed_second, SameMatrix &same)
{
    std::array<int, kMaxVertices> component;
    component.fill(-1);
    std::array<std::size_t, kMaxVertices> queue{};
    int next_component = 0;

    for (std::size_t start = 0; start < vertex_count; ++start) {
        if (component[start] >= 0) continue;
        std::size_t head = 0;
        std::size_t tail = 0;
        component[start] = next_component;
        queue[tail++] = start;
        while (head < tail) {
            const std::size_t vertex = queue[head++];
            for (std::size_t edge_id = 0; edge_id < edge_count; ++edge_id) {
                if (static_cast<int>(edge_id) == removed_first
                    || static_cast<int>(edge_id) == removed_second) continue;
                const Edge &edge = edges[edge_id];
                std::size_t neighbor = kMaxVertices;
                if (edge.from == vertex) neighbor = edge.to;
                else if (edge.to == vertex) neighbor = edge.from;
                if (neighbor < vertex_count && component[neighbor] < 0) {
                    component[neighbor] = next_component;
                    queue[tail++] = neighbor;
                }
            }
        }
        ++next_component;
    }

    for (std::size_t first = 0; first < vertex_count; ++first)
        for (std::size_t second = first + 1; second < vertex_count; ++second)
            if (component[first] != component[second]) same[first][second] = same[second][first] = false;
}
} // namespace

extern "C" std::int64_t three_edge_connected_components(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 2 || length > kMaxInputLength) return -1;
    if (values[0] < 1 || values[0] > static_cast<std::int64_t>(kMaxVertices)
        || values[1] < 0 || values[1] > static_cast<std::int64_t>(kMaxEdges)) return -1;
    const std::size_t vertex_count = static_cast<std::size_t>(values[0]);
    const std::size_t edge_count = static_cast<std::size_t>(values[1]);
    if (length != 2 + 2 * edge_count) return -1;

    std::array<Edge, kMaxEdges> edges{};
    for (std::size_t edge_id = 0; edge_id < edge_count; ++edge_id) {
        const std::int64_t from = values[2 + 2 * edge_id];
        const std::int64_t to = values[3 + 2 * edge_id];
        if (from < 0 || from >= static_cast<std::int64_t>(vertex_count)
            || to < 0 || to >= static_cast<std::int64_t>(vertex_count)) return -1;
        edges[edge_id] = {static_cast<std::size_t>(from), static_cast<std::size_t>(to)};
    }

    SameMatrix same{};
    for (std::size_t first = 0; first < vertex_count; ++first)
        for (std::size_t second = 0; second < vertex_count; ++second) same[first][second] = true;
    refine_for_removal(edges, vertex_count, edge_count, -1, -1, same);
    for (std::size_t first = 0; first < edge_count; ++first) {
        refine_for_removal(edges, vertex_count, edge_count, static_cast<int>(first), -1, same);
        for (std::size_t second = first + 1; second < edge_count; ++second)
            refine_for_removal(edges, vertex_count, edge_count,
                               static_cast<int>(first), static_cast<int>(second), same);
    }

    std::array<int, kMaxVertices> labels;
    labels.fill(-1);
    int next_label = 0;
    for (std::size_t first = 0; first < vertex_count; ++first) {
        if (labels[first] >= 0) continue;
        for (std::size_t vertex = first; vertex < vertex_count; ++vertex)
            if (labels[vertex] < 0 && same[first][vertex]) labels[vertex] = next_label;
        ++next_label;
    }

    std::int64_t encoded = 0;
    std::int64_t place = 1;
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
        encoded += labels[vertex] * place;
        place *= 8;
    }
    return encoded;
}
