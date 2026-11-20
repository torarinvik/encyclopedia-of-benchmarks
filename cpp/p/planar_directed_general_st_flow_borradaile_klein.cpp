#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <queue>
#include <utility>
#include <vector>

namespace {
constexpr int kMaxN = 6;
constexpr int kMaxM = 10;
constexpr std::size_t kMaxInput = 61;
constexpr int kMaxAugmentations = 25;
constexpr std::int64_t kInf = std::numeric_limits<std::int64_t>::max() / 4;

struct Edge { int tail; int head; int capacity; };
struct Graph {
    int n = 0, m = 0, source = 0, sink = 0;
    std::vector<Edge> edges;
    std::vector<std::vector<int>> rotation;
    std::vector<std::array<int, kMaxM>> local_position;
    std::vector<int> left_face, right_face;
    int face_count = 0, infinity_face = 0, root_anchor = -1;
};

int dart_tail(const Graph& graph, int dart) {
    const auto& edge = graph.edges[static_cast<std::size_t>(dart / 2)];
    return (dart & 1) ? edge.head : edge.tail;
}

int dart_head(const Graph& graph, int dart) {
    const auto& edge = graph.edges[static_cast<std::size_t>(dart / 2)];
    return (dart & 1) ? edge.tail : edge.head;
}

int next_left_dart(const Graph& graph, int dart) {
    const int vertex = dart_head(graph, dart);
    const int edge_id = dart / 2;
    const auto& row = graph.rotation[static_cast<std::size_t>(vertex)];
    const int position = graph.local_position[static_cast<std::size_t>(vertex)][static_cast<std::size_t>(edge_id)];
    if (row.empty() || position < 0) return -1;
    const int next_edge = row[static_cast<std::size_t>((position + static_cast<int>(row.size()) - 1) % static_cast<int>(row.size()))];
    return 2 * next_edge + (graph.edges[static_cast<std::size_t>(next_edge)].head == vertex ? 1 : 0);
}

bool decode(const std::int64_t* input, std::size_t length, Graph& graph) {
    if (input == nullptr || length < 4 || length > kMaxInput) return false;
    const auto n = input[0], m = input[1], source = input[2], sink = input[3];
    if (n < 2 || n > kMaxN || m < 1 || m > kMaxM || source < 0 || source >= n ||
        sink < 0 || sink >= n || source == sink || length < 4 + 3 * static_cast<std::size_t>(m)) return false;
    graph.n = static_cast<int>(n); graph.m = static_cast<int>(m);
    graph.source = static_cast<int>(source); graph.sink = static_cast<int>(sink);
    graph.edges.reserve(static_cast<std::size_t>(m));
    std::array<std::array<bool, kMaxN>, kMaxN> pair_seen{};
    std::size_t cursor = 4;
    for (int edge_id = 0; edge_id < graph.m; ++edge_id) {
        const auto u = input[cursor++], v = input[cursor++], cap = input[cursor++];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v || cap < 1 || cap > 5) return false;
        if (pair_seen[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] ||
            pair_seen[static_cast<std::size_t>(v)][static_cast<std::size_t>(u)]) return false;
        pair_seen[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] = true;
        pair_seen[static_cast<std::size_t>(v)][static_cast<std::size_t>(u)] = true;
        graph.edges.push_back({static_cast<int>(u), static_cast<int>(v), static_cast<int>(cap)});
    }

    graph.rotation.resize(static_cast<std::size_t>(graph.n));
    graph.local_position.resize(static_cast<std::size_t>(graph.n));
    std::vector<std::array<int, 2>> occurrences(static_cast<std::size_t>(graph.m), {0, 0});
    for (auto& row : graph.local_position) row.fill(-1);
    for (int vertex = 0; vertex < graph.n; ++vertex) {
        if (cursor >= length) return false;
        const auto degree = input[cursor++];
        if (degree < 1 || degree > graph.n - 1 || cursor + static_cast<std::size_t>(degree) > length) return false;
        auto& row = graph.rotation[static_cast<std::size_t>(vertex)];
        std::array<bool, kMaxM> used{};
        row.reserve(static_cast<std::size_t>(degree));
        for (int position = 0; position < degree; ++position) {
            const auto raw_edge = input[cursor++];
            if (raw_edge < 0 || raw_edge >= graph.m) return false;
            const int edge_id = static_cast<int>(raw_edge);
            if (used[static_cast<std::size_t>(edge_id)]) return false;
            used[static_cast<std::size_t>(edge_id)] = true;
            row.push_back(edge_id);
            graph.local_position[static_cast<std::size_t>(vertex)][static_cast<std::size_t>(edge_id)] = position;
            const auto& edge = graph.edges[static_cast<std::size_t>(edge_id)];
            if (edge.tail == vertex) ++occurrences[static_cast<std::size_t>(edge_id)][0];
            else if (edge.head == vertex) ++occurrences[static_cast<std::size_t>(edge_id)][1];
            else return false;
        }
    }
    if (cursor != length) return false;
    for (const auto& occurrence : occurrences)
        if (occurrence[0] != 1 || occurrence[1] != 1) return false;

    std::vector<bool> reached(static_cast<std::size_t>(graph.n), false);
    std::queue<int> pending;
    reached[static_cast<std::size_t>(graph.source)] = true;
    pending.push(graph.source);
    while (!pending.empty()) {
        const int u = pending.front(); pending.pop();
        for (const auto& edge : graph.edges) {
            const int v = edge.tail == u ? edge.head : (edge.head == u ? edge.tail : -1);
            if (v >= 0 && !reached[static_cast<std::size_t>(v)]) {
                reached[static_cast<std::size_t>(v)] = true;
                pending.push(v);
            }
        }
    }
    if (std::find(reached.begin(), reached.end(), false) != reached.end()) return false;

    graph.left_face.assign(static_cast<std::size_t>(2 * graph.m), -1);
    for (int start = 0; start < 2 * graph.m; ++start) {
        if (graph.left_face[static_cast<std::size_t>(start)] >= 0) continue;
        int dart = start;
        while (graph.left_face[static_cast<std::size_t>(dart)] < 0) {
            graph.left_face[static_cast<std::size_t>(dart)] = graph.face_count;
            dart = next_left_dart(graph, dart);
            if (dart < 0) return false;
        }
        if (dart != start) return false;
        ++graph.face_count;
    }
    if (graph.face_count != graph.m - graph.n + 2) return false;
    graph.right_face.resize(static_cast<std::size_t>(2 * graph.m));
    for (int dart = 0; dart < 2 * graph.m; ++dart)
        graph.right_face[static_cast<std::size_t>(dart)] = graph.left_face[static_cast<std::size_t>(dart ^ 1)];
    graph.root_anchor = graph.rotation[static_cast<std::size_t>(graph.sink)][0];
    const auto& anchor_edge = graph.edges[static_cast<std::size_t>(graph.root_anchor)];
    const int root_dart = 2 * graph.root_anchor + (anchor_edge.head == graph.sink ? 1 : 0);
    graph.infinity_face = graph.right_face[static_cast<std::size_t>(root_dart)];
    return true;
}

void right_first_search(const Graph& graph, int vertex, int anchor_edge, bool root,
                        const std::vector<std::vector<int>>& residual,
                        std::vector<bool>& seen, std::vector<int>& parent,
                        std::vector<int>& parent_edge) {
    const auto& row = graph.rotation[static_cast<std::size_t>(vertex)];
    const int degree = static_cast<int>(row.size());
    const int anchor = graph.local_position[static_cast<std::size_t>(vertex)][static_cast<std::size_t>(anchor_edge)];
    const int first = root ? 0 : 1;
    for (int step = first; step < first + degree; ++step) {
        const int edge_id = row[static_cast<std::size_t>((anchor + step) % degree)];
        const auto& edge = graph.edges[static_cast<std::size_t>(edge_id)];
        const int neighbor = edge.tail == vertex ? edge.head : edge.tail;
        if (!seen[static_cast<std::size_t>(neighbor)] &&
            residual[static_cast<std::size_t>(neighbor)][static_cast<std::size_t>(vertex)] > 0) {
            seen[static_cast<std::size_t>(neighbor)] = true;
            parent[static_cast<std::size_t>(neighbor)] = vertex;
            parent_edge[static_cast<std::size_t>(neighbor)] = edge_id;
            right_first_search(graph, neighbor, edge_id, false, residual, seen, parent, parent_edge);
        }
    }
}

std::int64_t solve(const Graph& graph) {
    std::vector<std::vector<std::int64_t>> dual(
        static_cast<std::size_t>(graph.face_count),
        std::vector<std::int64_t>(static_cast<std::size_t>(graph.face_count), kInf));
    for (int dart = 0; dart < 2 * graph.m; ++dart) {
        const int from = graph.right_face[static_cast<std::size_t>(dart)];
        const int to = graph.left_face[static_cast<std::size_t>(dart)];
        const std::int64_t length = (dart & 1) ? 0 : graph.edges[static_cast<std::size_t>(dart / 2)].capacity;
        dual[static_cast<std::size_t>(from)][static_cast<std::size_t>(to)] =
            std::min(dual[static_cast<std::size_t>(from)][static_cast<std::size_t>(to)], length);
    }
    std::vector<std::int64_t> distance(static_cast<std::size_t>(graph.face_count), kInf);
    std::vector<bool> settled(static_cast<std::size_t>(graph.face_count), false);
    distance[static_cast<std::size_t>(graph.infinity_face)] = 0;
    for (int count = 0; count < graph.face_count; ++count) {
        int current = -1;
        for (int face = 0; face < graph.face_count; ++face)
            if (!settled[static_cast<std::size_t>(face)] &&
                (current < 0 || distance[static_cast<std::size_t>(face)] < distance[static_cast<std::size_t>(current)]))
                current = face;
        if (current < 0 || distance[static_cast<std::size_t>(current)] == kInf) break;
        settled[static_cast<std::size_t>(current)] = true;
        for (int next = 0; next < graph.face_count; ++next) {
            const auto weight = dual[static_cast<std::size_t>(current)][static_cast<std::size_t>(next)];
            if (weight == kInf) continue;
            const auto candidate = distance[static_cast<std::size_t>(current)] + weight;
            if (candidate < distance[static_cast<std::size_t>(next)])
                distance[static_cast<std::size_t>(next)] = candidate;
        }
    }

    std::vector<std::vector<int>> residual(static_cast<std::size_t>(graph.n), std::vector<int>(static_cast<std::size_t>(graph.n), 0));
    for (int edge_id = 0; edge_id < graph.m; ++edge_id) {
        const int dart = 2 * edge_id;
        const auto eta = distance[static_cast<std::size_t>(graph.left_face[static_cast<std::size_t>(dart)])] -
                         distance[static_cast<std::size_t>(graph.right_face[static_cast<std::size_t>(dart)])];
        const auto& edge = graph.edges[static_cast<std::size_t>(edge_id)];
        if (eta < 0 || eta > edge.capacity) return -1;
        residual[static_cast<std::size_t>(edge.tail)][static_cast<std::size_t>(edge.head)] += edge.capacity - static_cast<int>(eta);
        residual[static_cast<std::size_t>(edge.head)][static_cast<std::size_t>(edge.tail)] += static_cast<int>(eta);
    }

    std::int64_t value = 0;
    for (int augmentation = 0; augmentation <= kMaxAugmentations; ++augmentation) {
        std::vector<bool> seen(static_cast<std::size_t>(graph.n), false);
        std::vector<int> parent(static_cast<std::size_t>(graph.n), -1);
        std::vector<int> parent_edge(static_cast<std::size_t>(graph.n), -1);
        seen[static_cast<std::size_t>(graph.sink)] = true;
        right_first_search(graph, graph.sink, graph.root_anchor, true, residual, seen, parent, parent_edge);
        if (!seen[static_cast<std::size_t>(graph.source)]) return value;
        if (augmentation == kMaxAugmentations) return -1;
        int delta = std::numeric_limits<int>::max();
        for (int vertex = graph.source; vertex != graph.sink; vertex = parent[static_cast<std::size_t>(vertex)]) {
            const int next = parent[static_cast<std::size_t>(vertex)];
            delta = std::min(delta, residual[static_cast<std::size_t>(vertex)][static_cast<std::size_t>(next)]);
        }
        for (int vertex = graph.source; vertex != graph.sink; vertex = parent[static_cast<std::size_t>(vertex)]) {
            const int next = parent[static_cast<std::size_t>(vertex)];
            residual[static_cast<std::size_t>(vertex)][static_cast<std::size_t>(next)] -= delta;
            residual[static_cast<std::size_t>(next)][static_cast<std::size_t>(vertex)] += delta;
        }
        value += delta;
    }
    return -1;
}
}  // namespace

extern "C" std::int64_t planar_directed_general_st_flow_borradaile_klein(
    const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    Graph graph;
    if (!decode(input, length, graph)) return -1;
    const auto value = solve(graph);
    if (value < 0) return -1;
    if (output == nullptr || capacity < 8) return -2;
    const auto bits = static_cast<std::uint64_t>(value);
    for (int byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    return 8;
}
