#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t kMaxN = 8;
constexpr std::size_t kMaxM = 20;

int find_root(std::array<int, kMaxN>& parent, int vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t second_best_mst(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 2 + 3 * kMaxM) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN)
            || input[1] < input[0] - 1 || input[1] > static_cast<std::int64_t>(kMaxM)) return -1;
    const int n = static_cast<int>(input[0]);
    const int m = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(2 + 3 * m)) return -1;

    std::array<int, kMaxM> edge_u{}, edge_v{}, edge_weight{}, order{};
    std::array<std::array<bool, kMaxN>, kMaxN> seen{};
    for (int edge = 0; edge < m; ++edge) {
        const auto u = input[2 + 3 * edge];
        const auto v = input[3 + 3 * edge];
        const auto weight = input[4 + 3 * edge];
        if (u < 0 || u >= v || v >= n || weight < 0 || weight > 1'000'000) return -1;
        if (seen[u][v]) return -1;
        seen[u][v] = true;
        edge_u[edge] = static_cast<int>(u);
        edge_v[edge] = static_cast<int>(v);
        edge_weight[edge] = static_cast<int>(weight);
        order[edge] = edge;
    }

    for (int i = 1; i < m; ++i) {
        const int edge = order[i];
        int j = i;
        while (j > 0 && (edge_weight[order[j - 1]] > edge_weight[edge]
                || (edge_weight[order[j - 1]] == edge_weight[edge] && order[j - 1] > edge))) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = edge;
    }

    std::array<int, kMaxN> dsu{}, size{};
    for (int vertex = 0; vertex < n; ++vertex) { dsu[vertex] = vertex; size[vertex] = 1; }
    std::array<bool, kMaxM> in_mst{};
    std::array<std::array<int, kMaxN>, kMaxN> tree_to{}, tree_edge{};
    std::array<int, kMaxN> degree{};
    int selected = 0;
    std::int64_t mst_weight = 0;
    for (int position = 0; position < m; ++position) {
        const int edge = order[position];
        int root_u = find_root(dsu, edge_u[edge]);
        int root_v = find_root(dsu, edge_v[edge]);
        if (root_u == root_v) continue;
        if (size[root_u] < size[root_v]) std::swap(root_u, root_v);
        dsu[root_v] = root_u;
        size[root_u] += size[root_v];
        in_mst[edge] = true;
        ++selected;
        mst_weight += edge_weight[edge];
        tree_to[edge_u[edge]][degree[edge_u[edge]]] = edge_v[edge];
        tree_edge[edge_u[edge]][degree[edge_u[edge]]++] = edge;
        tree_to[edge_v[edge]][degree[edge_v[edge]]] = edge_u[edge];
        tree_edge[edge_v[edge]][degree[edge_v[edge]]++] = edge;
    }
    if (selected != n - 1) return -1;

    std::int64_t second_weight = -1;
    int entering_edge = -1, leaving_edge = -1;
    for (int added = 0; added < m; ++added) {
        if (in_mst[added]) continue;
        std::array<int, kMaxN> parent{}, parent_edge{}, queue{};
        parent.fill(-1);
        int head = 0, tail = 0;
        const int start = edge_u[added], target = edge_v[added];
        parent[start] = start;
        queue[tail++] = start;
        while (head < tail && parent[target] == -1) {
            const int vertex = queue[head++];
            for (int i = 0; i < degree[vertex]; ++i) {
                const int next = tree_to[vertex][i];
                if (parent[next] != -1) continue;
                parent[next] = vertex;
                parent_edge[next] = tree_edge[vertex][i];
                queue[tail++] = next;
            }
        }
        std::int64_t first_weight = -1, second_path_weight = -1;
        int first_edge = -1, second_path_edge = -1;
        for (int vertex = target; vertex != start; vertex = parent[vertex]) {
            const int path_edge = parent_edge[vertex];
            const auto weight = edge_weight[path_edge];
            if (weight > first_weight) {
                second_path_weight = first_weight; second_path_edge = first_edge;
                first_weight = weight; first_edge = path_edge;
            } else if (weight == first_weight) {
                if (first_edge < 0 || path_edge < first_edge) first_edge = path_edge;
            } else if (weight > second_path_weight) {
                second_path_weight = weight; second_path_edge = path_edge;
            } else if (weight == second_path_weight
                    && (second_path_edge < 0 || path_edge < second_path_edge)) {
                second_path_edge = path_edge;
            }
        }
        std::int64_t removed_weight = -1;
        int removed_edge = -1;
        if (edge_weight[added] > first_weight) {
            removed_weight = first_weight; removed_edge = first_edge;
        } else if (edge_weight[added] == first_weight && second_path_weight >= 0) {
            removed_weight = second_path_weight; removed_edge = second_path_edge;
        }
        if (removed_edge < 0) continue;
        const auto candidate = mst_weight + edge_weight[added] - removed_weight;
        if (second_weight < 0 || candidate < second_weight
                || (candidate == second_weight && (added < entering_edge
                    || (added == entering_edge && removed_edge < leaving_edge)))) {
            second_weight = candidate;
            entering_edge = added;
            leaving_edge = removed_edge;
        }
    }

    if (output == nullptr || capacity < 32) return -2;
    store_i64_le(output, 0, mst_weight);
    store_i64_le(output, 8, second_weight);
    store_i64_le(output, 16, entering_edge);
    store_i64_le(output, 24, leaving_edge);
    return 32;
}
