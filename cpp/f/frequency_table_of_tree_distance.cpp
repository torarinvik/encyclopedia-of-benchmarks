#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_input_values = 1 + 2 * (max_n - 1);

struct WalkItem {
    std::size_t vertex;
    std::size_t parent;
    std::size_t depth;
};

std::size_t find_root(std::array<std::size_t, max_n> &parent, std::size_t item) noexcept {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

void solve_component(std::size_t n,
    const std::array<std::array<bool, max_n>, max_n> &adjacent,
    std::array<bool, max_n> &removed, std::array<std::int64_t, max_n> &answer,
    std::size_t start) {
    std::array<std::size_t, max_n> order{}, parent{}, subtree{};
    std::array<std::size_t, max_n> stack{};
    std::size_t order_count = 0, top = 0;
    stack[top++] = start;
    parent[start] = start;
    subtree[start] = 1;
    order[order_count++] = start;
    while (top > 0) {
        const auto vertex = stack[--top];
        for (std::size_t neighbor = 0; neighbor < n; ++neighbor) {
            if (!adjacent[vertex][neighbor] || removed[neighbor] || neighbor == parent[vertex]) continue;
            parent[neighbor] = vertex;
            subtree[neighbor] = 1;
            order[order_count++] = neighbor;
            stack[top++] = neighbor;
        }
    }
    for (std::size_t position = order_count; position > 1; --position) {
        const auto vertex = order[position - 1];
        subtree[parent[vertex]] += subtree[vertex];
    }

    std::size_t centroid = max_n;
    for (std::size_t position = 0; position < order_count; ++position) {
        const auto vertex = order[position];
        auto largest_part = order_count - subtree[vertex];
        for (std::size_t neighbor = 0; neighbor < n; ++neighbor) {
            if (adjacent[vertex][neighbor] && !removed[neighbor] && parent[neighbor] == vertex &&
                subtree[neighbor] > largest_part) largest_part = subtree[neighbor];
        }
        if (2 * largest_part <= order_count && (centroid == max_n || vertex < centroid))
            centroid = vertex;
    }

    std::array<std::int64_t, max_n> frequency{};
    std::size_t frequency_max = 0;
    frequency[0] = 1;
    removed[centroid] = true;
    for (std::size_t child = 0; child < n; ++child) {
        if (!adjacent[centroid][child] || removed[child]) continue;
        std::array<std::size_t, max_n> local_frequency{};
        std::array<WalkItem, max_n> walk{};
        std::size_t local_max = 0, walk_top = 0;
        walk[walk_top++] = {child, centroid, 1};
        while (walk_top > 0) {
            const auto item = walk[--walk_top];
            ++local_frequency[item.depth];
            if (item.depth > local_max) local_max = item.depth;
            for (std::size_t neighbor = 0; neighbor < n; ++neighbor)
                if (adjacent[item.vertex][neighbor] && !removed[neighbor] && neighbor != item.parent)
                    walk[walk_top++] = {neighbor, item.vertex, item.depth + 1};
        }
        for (std::size_t depth = 1; depth <= local_max; ++depth)
            for (std::size_t other = 0; other <= frequency_max && depth + other < n; ++other)
                answer[depth + other] += static_cast<std::int64_t>(local_frequency[depth]) * frequency[other];
        for (std::size_t depth = 1; depth <= local_max; ++depth)
            frequency[depth] += static_cast<std::int64_t>(local_frequency[depth]);
        if (local_max > frequency_max) frequency_max = local_max;
    }

    for (std::size_t child = 0; child < n; ++child)
        if (adjacent[centroid][child] && !removed[child])
            solve_component(n, adjacent, removed, answer, child);
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t frequency_table_of_tree_distance(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_input_values) return -1;
    const auto n_value = input[0];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != 1 + 2 * (n - 1)) return -1;

    std::array<std::array<bool, max_n>, max_n> adjacent{};
    std::array<std::size_t, max_n> dsu_parent{}, dsu_size{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    for (std::size_t edge = 0; edge + 1 < n; ++edge) {
        const auto offset = 1 + 2 * edge;
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

    std::array<bool, max_n> removed{};
    std::array<std::int64_t, max_n> answer{};
    solve_component(n, adjacent, removed, answer, 0);
    const auto required = 8 * (n - 1);
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t distance = 1; distance < n; ++distance)
        store_i64_le(output, 8 * (distance - 1), answer[distance]);
    return static_cast<std::int64_t>(required);
}
