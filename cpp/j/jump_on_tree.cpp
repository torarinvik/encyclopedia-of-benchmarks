#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_q = 64;
constexpr std::size_t max_levels = 7;
constexpr std::size_t max_input_values = 2 + 2 * (max_n - 1) + 3 * max_q;

std::size_t find_root(std::array<std::size_t, max_n> &parent, std::size_t item) noexcept {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

std::size_t lift(const std::array<std::array<std::size_t, max_levels>, max_n> &ancestors,
                 std::size_t vertex, std::size_t distance) noexcept {
    for (std::size_t bit = 0; bit < max_levels; ++bit)
        if ((distance >> bit) & 1U) vertex = ancestors[vertex][bit];
    return vertex;
}

std::size_t lowest_common_ancestor(
    const std::array<std::array<std::size_t, max_levels>, max_n> &ancestors,
    const std::array<std::size_t, max_n> &depth, std::size_t left,
    std::size_t right) noexcept {
    if (depth[left] < depth[right]) {
        const auto temporary = left;
        left = right;
        right = temporary;
    }
    left = lift(ancestors, left, depth[left] - depth[right]);
    if (left == right) return left;
    for (std::size_t level = max_levels; level > 0; --level) {
        const auto bit = level - 1;
        if (ancestors[left][bit] != ancestors[right][bit]) {
            left = ancestors[left][bit];
            right = ancestors[right][bit];
        }
    }
    return ancestors[left][0];
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t jump_on_tree(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input_values) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 2 || n_value > static_cast<std::int64_t>(max_n) ||
        q_value < 1 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);
    const auto query_start = 2 + 2 * (n - 1);
    if (length != query_start + 3 * q) return -1;

    std::array<std::array<bool, max_n>, max_n> adjacent{};
    std::array<std::size_t, max_n> dsu_parent{}, dsu_size{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    for (std::size_t edge = 0; edge + 1 < n; ++edge) {
        const auto offset = 2 + 2 * edge;
        const auto left_value = input[offset], right_value = input[offset + 1];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value) return -1;
        const auto left = static_cast<std::size_t>(left_value);
        const auto right = static_cast<std::size_t>(right_value);
        auto root_left = find_root(dsu_parent, left);
        auto root_right = find_root(dsu_parent, right);
        if (root_left == root_right) return -1;
        if (dsu_size[root_left] < dsu_size[root_right]) {
            const auto temporary = root_left;
            root_left = root_right;
            root_right = temporary;
        }
        dsu_parent[root_right] = root_left;
        dsu_size[root_left] += dsu_size[root_right];
        adjacent[left][right] = adjacent[right][left] = true;
    }

    std::array<std::array<std::size_t, max_levels>, max_n> ancestors{};
    std::array<std::size_t, max_n> depth{};
    std::array<bool, max_n> visited{};
    std::array<std::size_t, max_n> stack{};
    std::size_t top = 0;
    stack[top++] = 0;
    visited[0] = true;
    while (top > 0) {
        const auto vertex = stack[--top];
        for (std::size_t neighbor = 0; neighbor < n; ++neighbor) {
            if (!adjacent[vertex][neighbor] || visited[neighbor]) continue;
            visited[neighbor] = true;
            ancestors[neighbor][0] = vertex;
            depth[neighbor] = depth[vertex] + 1;
            stack[top++] = neighbor;
        }
    }
    for (std::size_t level = 1; level < max_levels; ++level)
        for (std::size_t vertex = 0; vertex < n; ++vertex)
            ancestors[vertex][level] = ancestors[ancestors[vertex][level - 1]][level - 1];

    std::array<std::int64_t, max_q> answers{};
    for (std::size_t query = 0; query < q; ++query) {
        const auto offset = query_start + 3 * query;
        const auto start_value = input[offset], target_value = input[offset + 1];
        const auto index_value = input[offset + 2];
        if (start_value < 0 || start_value >= n_value || target_value < 0 ||
            target_value >= n_value || index_value < 0 || index_value >= n_value) return -1;
        const auto start = static_cast<std::size_t>(start_value);
        const auto target = static_cast<std::size_t>(target_value);
        const auto index = static_cast<std::size_t>(index_value);
        const auto common = lowest_common_ancestor(ancestors, depth, start, target);
        const auto upward = depth[start] - depth[common];
        const auto path_length = upward + depth[target] - depth[common];
        if (index > path_length) answers[query] = -1;
        else if (index <= upward) answers[query] = static_cast<std::int64_t>(lift(ancestors, start, index));
        else answers[query] = static_cast<std::int64_t>(lift(ancestors, target, path_length - index));
    }

    const auto required = 8 * q;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t query = 0; query < q; ++query)
        store_i64_le(output, 8 * query, answers[query]);
    return static_cast<std::int64_t>(required);
}
