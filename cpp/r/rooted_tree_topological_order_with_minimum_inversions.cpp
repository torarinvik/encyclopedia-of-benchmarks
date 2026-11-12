#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxN = 12;
constexpr std::size_t kMaxInputValues = 3 * kMaxN + 1;
constexpr std::size_t kMaxOutputWords = kMaxN + 1;
constexpr std::int64_t kMaxWeight = 1'000'000;

int find_root(int parent[kMaxN], int vertex) {
    int root = vertex;
    while (parent[root] != root) root = parent[root];
    while (parent[vertex] != vertex) {
        const int next = parent[vertex];
        parent[vertex] = root;
        vertex = next;
    }
    return root;
}

int compare_ratio(std::int64_t left_c, std::int64_t left_d,
                  std::int64_t right_c, std::int64_t right_d) {
    const bool left_zero = left_c == 0 && left_d == 0;
    const bool right_zero = right_c == 0 && right_d == 0;
    if (left_zero != right_zero) return left_zero ? -1 : 1;
    const auto lhs = left_c * right_d;
    const auto rhs = left_d * right_c;
    return (lhs > rhs) - (lhs < rhs);
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t rooted_tree_topological_order_with_minimum_inversions(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 3 || length > kMaxInputValues) return -1;
    const auto n_value = input[0];
    if (n_value < 1 || n_value > kMaxN || length != static_cast<std::size_t>(3 * n_value)) return -1;
    const int n = static_cast<int>(n_value);

    int tree_parent[kMaxN];
    tree_parent[0] = -1;
    for (int vertex = 1; vertex < n; ++vertex) {
        const auto p = input[vertex];
        if (p < 0 || p >= vertex) return -1;
        tree_parent[vertex] = static_cast<int>(p);
    }

    std::int64_t original_c[kMaxN], original_d[kMaxN];
    std::int64_t aggregate_c[kMaxN], aggregate_d[kMaxN];
    std::int64_t sum_c = 0, sum_d = 0;
    for (int vertex = 0; vertex < n; ++vertex) {
        const auto c = input[n + vertex];
        const auto d = input[2 * n + vertex];
        if (c < 0 || c > kMaxWeight || d < 0 || d > kMaxWeight) return -1;
        sum_c += c;
        sum_d += d;
        if (sum_c > kMaxWeight || sum_d > kMaxWeight) return -1;
        original_c[vertex] = aggregate_c[vertex] = c;
        original_d[vertex] = aggregate_d[vertex] = d;
    }

    int dsu_parent[kMaxN], component_label[kMaxN], active[kMaxN], link[kMaxN];
    for (int vertex = 0; vertex < n; ++vertex) {
        dsu_parent[vertex] = component_label[vertex] = link[vertex] = vertex;
        active[vertex] = vertex != 0;
    }

    for (int step = 0; step < n - 1; ++step) {
        int selected = -1;
        for (int candidate = 1; candidate < n; ++candidate) {
            if (!active[candidate]) continue;
            if (selected < 0) { selected = candidate; continue; }
            const int comparison = compare_ratio(aggregate_c[candidate], aggregate_d[candidate],
                                                 aggregate_c[selected], aggregate_d[selected]);
            if (comparison > 0 || (comparison == 0 && candidate > selected)) selected = candidate;
        }
        if (selected < 0) return -1;
        const int parent_component = find_root(dsu_parent, tree_parent[selected]);
        const int target = component_label[parent_component];
        const int selected_component = find_root(dsu_parent, selected);
        if (selected_component == parent_component) return -1;
        aggregate_c[target] += aggregate_c[selected];
        aggregate_d[target] += aggregate_d[selected];
        dsu_parent[selected_component] = parent_component;
        component_label[parent_component] = target;
        active[selected] = 0;
        if (target != 0) active[target] = 1;
        const int next = link[selected];
        link[selected] = link[target];
        link[target] = next;
    }

    int traversal[kMaxN];
    int count = 0, vertex = link[0];
    while (count < n) {
        traversal[count++] = vertex;
        if (vertex == 0) break;
        vertex = link[vertex];
    }
    if (count != n || traversal[count - 1] != 0) return -1;

    std::int64_t words[kMaxOutputWords];
    std::int64_t prefix_d = 0, objective = 0;
    for (int index = 0; index < n; ++index) {
        const int ordered_vertex = traversal[n - 1 - index];
        words[index + 1] = ordered_vertex;
        objective += prefix_d * original_c[ordered_vertex];
        prefix_d += original_d[ordered_vertex];
    }
    words[0] = objective;
    const std::size_t output_bytes = static_cast<std::size_t>(n + 1) * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t word = 0; word < static_cast<std::size_t>(n + 1); ++word)
        store_i64_le(output, word * 8, words[word]);
    return static_cast<std::int64_t>(output_bytes);
}
