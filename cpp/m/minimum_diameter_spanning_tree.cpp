#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t max_n = 8;
constexpr std::size_t max_m = 20;
constexpr std::size_t max_input_values = 2 + 3 * max_m + 1;
constexpr std::int64_t infinity = 1'000'000'000'000LL;

struct Edge {
    std::size_t u;
    std::size_t v;
    std::int64_t weight;
};

void shortest_tree(std::size_t n, std::size_t m, const std::array<Edge, max_m> &edges,
    int center_kind, std::size_t center_root, std::int64_t center_x2,
    std::size_t center_edge, std::array<std::int64_t, max_n> &distance,
    std::array<std::int64_t, max_n> &parent_edge) {
    std::array<bool, max_n> settled{};
    distance.fill(infinity);
    parent_edge.fill(-1);
    if (center_kind == 0) {
        distance[center_root] = 0;
    } else {
        auto u = edges[center_edge].u;
        auto v = edges[center_edge].v;
        if (u > v) std::swap(u, v);
        distance[u] = center_x2;
        distance[v] = 2 * edges[center_edge].weight - center_x2;
    }

    for (std::size_t step = 0; step < n; ++step) {
        std::size_t current = n;
        for (std::size_t vertex = 0; vertex < n; ++vertex) {
            if (!settled[vertex] &&
                (current == n || distance[vertex] < distance[current])) current = vertex;
        }
        if (current == n || distance[current] == infinity) return;
        settled[current] = true;
        for (std::size_t edge_id = 0; edge_id < m; ++edge_id) {
            const auto left = edges[edge_id].u;
            const auto right = edges[edge_id].v;
            if (left == right) continue;
            std::size_t neighbor;
            if (current == left) neighbor = right;
            else if (current == right) neighbor = left;
            else continue;
            const auto candidate = distance[current] + 2 * edges[edge_id].weight;
            if (!settled[neighbor] && candidate < distance[neighbor]) {
                distance[neighbor] = candidate;
                parent_edge[neighbor] = static_cast<std::int64_t>(edge_id);
            }
        }
    }
}

std::int64_t tree_diameter(std::size_t n, const std::array<Edge, max_m> &edges,
    const std::array<std::size_t, max_n> &selected) {
    std::array<std::array<bool, max_n>, max_n> adjacent{};
    std::array<std::array<std::int64_t, max_n>, max_n> weight{};
    for (std::size_t index = 0; index + 1 < n; ++index) {
        const auto &edge = edges[selected[index]];
        adjacent[edge.u][edge.v] = adjacent[edge.v][edge.u] = true;
        weight[edge.u][edge.v] = weight[edge.v][edge.u] = edge.weight;
    }
    std::int64_t diameter = 0;
    for (std::size_t source = 0; source < n; ++source) {
        std::array<std::int64_t, max_n> distance{};
        std::array<std::size_t, max_n> parent{}, stack{};
        distance.fill(-1);
        parent.fill(n);
        std::size_t top = 1;
        stack[0] = source;
        distance[source] = 0;
        while (top > 0) {
            const auto current = stack[--top];
            diameter = std::max(diameter, distance[current]);
            for (std::size_t neighbor = 0; neighbor < n; ++neighbor) {
                if (adjacent[current][neighbor] && parent[current] != neighbor &&
                    distance[neighbor] < 0) {
                    parent[neighbor] = current;
                    distance[neighbor] = distance[current] + weight[current][neighbor];
                    stack[top++] = neighbor;
                }
            }
        }
    }
    return diameter;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t minimum_diameter_spanning_tree(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input_values) return -1;
    const auto n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) ||
        m_value < 0 || m_value > static_cast<std::int64_t>(max_m)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto m = static_cast<std::size_t>(m_value);
    if (length != 2 + 3 * m) return -1;

    std::array<Edge, max_m> edges{};
    std::array<std::array<std::int64_t, max_n>, max_n> graph_distance{};
    for (std::size_t left = 0; left < n; ++left)
        for (std::size_t right = 0; right < n; ++right)
            graph_distance[left][right] = left == right ? 0 : infinity;
    for (std::size_t edge_id = 0; edge_id < m; ++edge_id) {
        const auto offset = 2 + 3 * edge_id;
        const auto u_value = input[offset], v_value = input[offset + 1];
        const auto edge_weight = input[offset + 2];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value ||
            edge_weight < 0 || edge_weight > 9) return -1;
        const auto u = static_cast<std::size_t>(u_value);
        const auto v = static_cast<std::size_t>(v_value);
        edges[edge_id] = {u, v, edge_weight};
        if (u != v && edge_weight < graph_distance[u][v])
            graph_distance[u][v] = graph_distance[v][u] = edge_weight;
    }
    for (std::size_t middle = 0; middle < n; ++middle)
        for (std::size_t left = 0; left < n; ++left)
            for (std::size_t right = 0; right < n; ++right)
                graph_distance[left][right] = std::min(graph_distance[left][right],
                    graph_distance[left][middle] + graph_distance[middle][right]);
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        if (graph_distance[0][vertex] == infinity) return -1;

    auto best_radius2 = infinity;
    int best_kind = 0;
    std::size_t best_root = 0, best_edge = 0;
    std::int64_t best_x2 = 0;
    for (std::size_t root = 0; root < n; ++root) {
        std::int64_t eccentricity = 0;
        for (std::size_t vertex = 0; vertex < n; ++vertex)
            eccentricity = std::max(eccentricity, graph_distance[root][vertex]);
        const auto radius2 = 2 * eccentricity;
        if (radius2 < best_radius2) {
            best_radius2 = radius2;
            best_kind = 0;
            best_root = root;
        }
    }
    for (std::size_t edge_id = 0; edge_id < m; ++edge_id) {
        auto u = edges[edge_id].u, v = edges[edge_id].v;
        const auto edge_weight = edges[edge_id].weight;
        if (u == v) continue;
        if (u > v) std::swap(u, v);
        for (std::int64_t x2 = 0; x2 <= 2 * edge_weight; ++x2) {
            std::int64_t radius2 = 0;
            for (std::size_t vertex = 0; vertex < n; ++vertex) {
                const auto from_u = 2 * graph_distance[u][vertex] + x2;
                const auto from_v = 2 * graph_distance[v][vertex] + 2 * edge_weight - x2;
                radius2 = std::max(radius2, std::min(from_u, from_v));
            }
            if (radius2 < best_radius2) {
                best_radius2 = radius2;
                best_kind = 1;
                best_root = u;
                best_x2 = x2;
                best_edge = edge_id;
            }
        }
    }

    std::array<std::int64_t, max_n> center_distance{}, parent_edge{};
    shortest_tree(n, m, edges, best_kind, best_root, best_x2, best_edge,
        center_distance, parent_edge);
    std::array<std::size_t, max_n> selected{};
    std::size_t selected_count = 0;
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        if (parent_edge[vertex] >= 0) selected[selected_count++] = static_cast<std::size_t>(parent_edge[vertex]);
    if (selected_count + 2 == n && best_kind == 1) {
        const auto u = edges[best_edge].u, v = edges[best_edge].v;
        if (parent_edge[u] == -1 && parent_edge[v] == -1) selected[selected_count++] = best_edge;
    }
    if (selected_count != n - 1) return -1;
    std::sort(selected.begin(), selected.begin() + static_cast<std::ptrdiff_t>(selected_count));

    std::array<std::int64_t, max_n> staged{};
    staged[0] = tree_diameter(n, edges, selected);
    for (std::size_t index = 0; index < selected_count; ++index)
        staged[index + 1] = static_cast<std::int64_t>(selected[index]);
    const auto required = 8 * n;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < n; ++index)
        store_i64_le(output, 8 * index, staged[index]);
    return static_cast<std::int64_t>(required);
}
