#include <cstddef>
#include <cstdint>

namespace {
constexpr int MaxVertices = 12;
constexpr int MaxEdges = 24;
constexpr std::size_t MaxInputLength = 2 + 3 * MaxEdges + 1;

int find_root(int *parent, int vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

void join_roots(int *parent, int left, int right) {
    const int a = find_root(parent, left), b = find_root(parent, right);
    if (a != b) parent[b] = a;
}

bool alternative_path_exists(const int *left, const int *right, const int *edge_id,
        int edge_count, int omitted_edge, int source, int target) {
    bool seen[MaxVertices]{};
    int queue[MaxVertices];
    int head = 0, tail = 0;
    seen[source] = true;
    queue[tail++] = source;
    while (head < tail) {
        const int vertex = queue[head++];
        if (vertex == target) return true;
        for (int edge = 0; edge < edge_count; ++edge) {
            if (edge_id[edge] == omitted_edge) continue;
            int neighbor = -1;
            if (left[edge] == vertex) neighbor = right[edge];
            else if (right[edge] == vertex) neighbor = left[edge];
            if (neighbor >= 0 && !seen[neighbor]) {
                seen[neighbor] = true;
                queue[tail++] = neighbor;
            }
        }
    }
    return false;
}
}

extern "C" std::int64_t mst_edge_classification(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > MaxInputLength) return -1;
    if (input[0] < 1 || input[0] > MaxVertices || input[1] < 0 || input[1] > MaxEdges) return -1;
    const int vertex_count = static_cast<int>(input[0]);
    const int edge_count = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(2 + 3 * edge_count)) return -1;

    int left[MaxEdges], right[MaxEdges], weight[MaxEdges], order[MaxEdges];
    std::uint8_t classes[MaxEdges]{};
    for (int edge = 0; edge < edge_count; ++edge) {
        const auto u = input[2 + 3 * edge];
        const auto v = input[3 + 3 * edge];
        const auto w = input[4 + 3 * edge];
        if (u < 0 || u >= v || v >= vertex_count || w < 0 || w > 20) return -1;
        left[edge] = static_cast<int>(u);
        right[edge] = static_cast<int>(v);
        weight[edge] = static_cast<int>(w);
        order[edge] = edge;
        for (int prior = 0; prior < edge; ++prior)
            if (left[prior] == left[edge] && right[prior] == right[edge]) return -1;
    }
    for (int i = 1; i < edge_count; ++i) {
        const int item = order[i];
        int j = i;
        while (j > 0 && (weight[order[j - 1]] > weight[item] ||
                (weight[order[j - 1]] == weight[item] && order[j - 1] > item))) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = item;
    }

    int parent[MaxVertices];
    for (int vertex = 0; vertex < vertex_count; ++vertex) parent[vertex] = vertex;
    for (int start = 0; start < edge_count;) {
        int stop = start + 1;
        const int group_weight = weight[order[start]];
        while (stop < edge_count && weight[order[stop]] == group_weight) ++stop;
        int q_left[MaxEdges], q_right[MaxEdges], q_id[MaxEdges];
        int q_count = 0;
        for (int pos = start; pos < stop; ++pos) {
            const int id = order[pos];
            const int a = find_root(parent, left[id]);
            const int b = find_root(parent, right[id]);
            if (a != b) { q_left[q_count] = a; q_right[q_count] = b; q_id[q_count++] = id; }
        }
        for (int e = 0; e < q_count; ++e)
            classes[q_id[e]] = alternative_path_exists(q_left, q_right, q_id, q_count,
                q_id[e], q_left[e], q_right[e]) ? 1 : 2;
        for (int pos = start; pos < stop; ++pos) {
            const int id = order[pos];
            join_roots(parent, left[id], right[id]);
        }
        start = stop;
    }
    const int representative = find_root(parent, 0);
    for (int vertex = 1; vertex < vertex_count; ++vertex)
        if (find_root(parent, vertex) != representative) return -1;
    if (output_capacity < static_cast<std::size_t>(edge_count) || (edge_count > 0 && output == nullptr)) return -2;
    for (int edge = 0; edge < edge_count; ++edge) output[edge] = classes[edge];
    return edge_count;
}
