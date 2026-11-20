#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t max_n = 8;
constexpr std::size_t max_m = 16;
constexpr std::size_t max_q = 8;
constexpr std::size_t max_tree = 15;
constexpr std::size_t levels = 4;
constexpr std::size_t max_input = 67;

std::size_t find_root(std::array<std::size_t, max_n> &parent, std::size_t vertex) noexcept {
    std::size_t root = vertex;
    while (parent[root] != root) root = parent[root];
    while (parent[vertex] != vertex) {
        const std::size_t next = parent[vertex];
        parent[vertex] = root;
        vertex = next;
    }
    return root;
}

std::size_t lca(std::size_t source, std::size_t destination,
                const std::array<std::size_t, max_tree> &depth,
                const std::array<std::array<std::size_t, max_tree>, levels> &ancestor) noexcept {
    if (depth[source] < depth[destination]) std::swap(source, destination);
    std::size_t difference = depth[source] - depth[destination];
    std::size_t bit = 0;
    while (difference != 0) {
        if (difference & 1) source = ancestor[bit][source];
        difference >>= 1;
        ++bit;
    }
    if (source == destination) return source;
    for (std::size_t level = levels; level > 0; --level) {
        const std::size_t index = level - 1;
        if (ancestor[index][source] != ancestor[index][destination]) {
            source = ancestor[index][source];
            destination = ancestor[index][destination];
        }
    }
    return ancestor[0][source];
}
} // namespace

extern "C" std::int64_t kruskal_reconstruction_tree_bottleneck(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > max_input) return -1;
    const std::int64_t n_value = input[0];
    const std::int64_t m_value = input[1];
    const std::int64_t q_value = input[2];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n)
        || m_value < 0 || m_value > static_cast<std::int64_t>(max_m)
        || q_value < 1 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto m = static_cast<std::size_t>(m_value);
    const auto q = static_cast<std::size_t>(q_value);
    const std::size_t query_start = 3 + 3 * m;
    if (length != query_start + 2 * q) return -1;

    std::array<std::size_t, max_m> edge_u{};
    std::array<std::size_t, max_m> edge_v{};
    std::array<std::int64_t, max_m> edge_weight{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const std::int64_t u = input[3 + 3 * edge];
        const std::int64_t v = input[4 + 3 * edge];
        const std::int64_t weight = input[5 + 3 * edge];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value
            || weight < 0 || weight > 1'000'000) return -1;
        edge_u[edge] = static_cast<std::size_t>(u);
        edge_v[edge] = static_cast<std::size_t>(v);
        edge_weight[edge] = weight;
    }
    for (std::size_t query = 0; query < q; ++query) {
        const std::int64_t source = input[query_start + 2 * query];
        const std::int64_t destination = input[query_start + 2 * query + 1];
        if (source < 0 || source >= n_value || destination < 0 || destination >= n_value)
            return -1;
    }

    for (std::size_t i = 1; i < m; ++i) {
        const auto u = edge_u[i];
        const auto v = edge_v[i];
        const auto weight = edge_weight[i];
        std::size_t position = i;
        while (position > 0 && edge_weight[position - 1] > weight) {
            edge_u[position] = edge_u[position - 1];
            edge_v[position] = edge_v[position - 1];
            edge_weight[position] = edge_weight[position - 1];
            --position;
        }
        edge_u[position] = u;
        edge_v[position] = v;
        edge_weight[position] = weight;
    }

    std::array<std::size_t, max_n> dsu_parent{};
    std::array<std::size_t, max_n> dsu_size{};
    std::array<int, max_n> component_tree{};
    std::array<int, max_tree> tree_parent{};
    std::array<int, max_tree> tree_left{};
    std::array<int, max_tree> tree_right{};
    std::array<std::int64_t, max_tree> tree_weight{};
    tree_parent.fill(-1);
    tree_left.fill(-1);
    tree_right.fill(-1);
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
        component_tree[vertex] = static_cast<int>(vertex);
    }

    std::size_t next_tree_node = n;
    for (std::size_t edge = 0; edge < m; ++edge) {
        auto root_u = find_root(dsu_parent, edge_u[edge]);
        auto root_v = find_root(dsu_parent, edge_v[edge]);
        if (root_u == root_v) continue;
        const int left = component_tree[root_u];
        const int right = component_tree[root_v];
        const std::size_t merge_node = next_tree_node++;
        tree_left[merge_node] = left;
        tree_right[merge_node] = right;
        tree_weight[merge_node] = edge_weight[edge];
        tree_parent[static_cast<std::size_t>(left)] = static_cast<int>(merge_node);
        tree_parent[static_cast<std::size_t>(right)] = static_cast<int>(merge_node);

        if (dsu_size[root_u] < dsu_size[root_v]) std::swap(root_u, root_v);
        dsu_parent[root_v] = root_u;
        dsu_size[root_u] += dsu_size[root_v];
        component_tree[root_u] = static_cast<int>(merge_node);
    }

    std::array<std::size_t, max_tree> depth{};
    std::array<std::array<std::size_t, max_tree>, levels> ancestor{};
    for (std::size_t node = next_tree_node; node > 0; --node) {
        const std::size_t current = node - 1;
        if (tree_parent[current] < 0) {
            ancestor[0][current] = current;
        } else {
            const auto parent = static_cast<std::size_t>(tree_parent[current]);
            ancestor[0][current] = parent;
            depth[current] = depth[parent] + 1;
        }
    }
    for (std::size_t level = 1; level < levels; ++level)
        for (std::size_t node = 0; node < next_tree_node; ++node)
            ancestor[level][node] = ancestor[level - 1][ancestor[level - 1][node]];

    std::int64_t checksum = 0;
    for (std::size_t query = 0; query < q; ++query) {
        const auto source = static_cast<std::size_t>(input[query_start + 2 * query]);
        const auto destination = static_cast<std::size_t>(input[query_start + 2 * query + 1]);
        std::int64_t answer;
        if (source == destination) answer = 0;
        else if (find_root(dsu_parent, source) != find_root(dsu_parent, destination)) answer = -1;
        else answer = tree_weight[lca(source, destination, depth, ancestor)];
        checksum += static_cast<std::int64_t>(query + 1) * (answer + 2);
    }
    return checksum;
}
