#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 16;
constexpr std::size_t kMaxEdges = kMaxN - 1;
constexpr std::size_t kMaxArcs = 2 * kMaxEdges;
constexpr std::size_t kMaxInputLength = 48;

std::size_t find_root(std::array<int, kMaxN>& sets, std::size_t vertex) {
    while (sets[vertex] != static_cast<int>(vertex)) {
        sets[vertex] = sets[static_cast<std::size_t>(sets[vertex])];
        vertex = static_cast<std::size_t>(sets[vertex]);
    }
    return vertex;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t tree_random_walk_edge_hitting_cost(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const auto n_value = input[0], root_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(kMaxN)
            || root_value < 0 || root_value >= n_value) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto root = static_cast<std::size_t>(root_value);
    const auto edge_count = n - 1;
    if (length != 2 + 3 * edge_count) return -1;

    std::array<int, kMaxN> head{};
    std::array<int, kMaxArcs> to{};
    std::array<int, kMaxArcs> next{};
    std::array<int, kMaxN> sets{};
    std::array<std::size_t, kMaxEdges> input_u{}, input_v{};
    std::array<std::int64_t, kMaxN> incident_sum{}, down{}, up{};
    head.fill(-1);
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        sets[vertex] = static_cast<int>(vertex);

    std::size_t arc_count = 0;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto offset = 2 + 3 * edge;
        const auto u_value = input[offset], v_value = input[offset + 1];
        const auto weight = input[offset + 2];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
                || u_value == v_value || weight < 1 || weight > 9) return -1;
        const auto u = static_cast<std::size_t>(u_value);
        const auto v = static_cast<std::size_t>(v_value);
        const auto set_u = find_root(sets, u), set_v = find_root(sets, v);
        if (set_u == set_v) return -1;
        sets[set_v] = static_cast<int>(set_u);
        input_u[edge] = u;
        input_v[edge] = v;
        to[arc_count] = static_cast<int>(v);
        next[arc_count] = head[u];
        head[u] = static_cast<int>(arc_count++);
        to[arc_count] = static_cast<int>(u);
        next[arc_count] = head[v];
        head[v] = static_cast<int>(arc_count++);
        incident_sum[u] += weight;
        incident_sum[v] += weight;
    }

    const auto output_bytes = 16 * edge_count;
    if (output == nullptr || capacity < output_bytes) return -2;

    std::array<int, kMaxN> parent{};
    std::array<std::size_t, kMaxN> order{};
    parent.fill(-1);
    parent[root] = static_cast<int>(root);
    order[0] = root;
    std::size_t order_size = 1;
    for (std::size_t cursor = 0; cursor < order_size; ++cursor) {
        const auto vertex = order[cursor];
        for (int arc = head[vertex]; arc != -1; arc = next[static_cast<std::size_t>(arc)]) {
            const auto neighbor = static_cast<std::size_t>(to[static_cast<std::size_t>(arc)]);
            if (parent[neighbor] == -1) {
                parent[neighbor] = static_cast<int>(vertex);
                order[order_size++] = neighbor;
            }
        }
    }
    for (std::size_t position = n; position-- > 0;) {
        const auto vertex = order[position];
        down[vertex] = incident_sum[vertex];
        for (int arc = head[vertex]; arc != -1; arc = next[static_cast<std::size_t>(arc)]) {
            const auto child = static_cast<std::size_t>(to[static_cast<std::size_t>(arc)]);
            if (parent[child] == static_cast<int>(vertex)) down[vertex] += down[child];
        }
    }
    for (std::size_t position = 0; position < n; ++position) {
        const auto vertex = order[position];
        for (int arc = head[vertex]; arc != -1; arc = next[static_cast<std::size_t>(arc)]) {
            const auto child = static_cast<std::size_t>(to[static_cast<std::size_t>(arc)]);
            if (parent[child] == static_cast<int>(vertex))
                up[child] = up[vertex] + down[vertex] - down[child];
        }
    }
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto u = input_u[edge], v = input_v[edge];
        const auto toward_v = parent[u] == static_cast<int>(v) ? down[u] : up[v];
        const auto toward_u = parent[u] == static_cast<int>(v) ? up[u] : down[v];
        store_i64_le(output, 16 * edge, toward_v);
        store_i64_le(output, 16 * edge + 8, toward_u);
    }
    return static_cast<std::int64_t>(output_bytes);
}
