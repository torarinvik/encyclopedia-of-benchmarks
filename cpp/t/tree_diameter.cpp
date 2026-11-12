#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_input_values = 1 + 3 * (max_n - 1);
constexpr std::size_t max_output_values = 2 + max_n;

std::size_t find_root(std::array<std::size_t, max_n> &parent, std::size_t item) noexcept {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

void traverse(std::size_t n, std::size_t start,
    const std::array<std::array<bool, max_n>, max_n> &adjacent,
    const std::array<std::array<std::int64_t, max_n>, max_n> &weight,
    std::array<std::int64_t, max_n> &distance,
    std::array<std::int64_t, max_n> &parent) {
    std::array<std::size_t, max_n> stack{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        distance[vertex] = -1;
        parent[vertex] = -1;
    }
    std::size_t top = 0;
    stack[top++] = start;
    distance[start] = 0;
    while (top > 0) {
        const auto vertex = stack[--top];
        for (std::size_t neighbor = 0; neighbor < n; ++neighbor) {
            if (!adjacent[vertex][neighbor] || distance[neighbor] >= 0) continue;
            distance[neighbor] = distance[vertex] + weight[vertex][neighbor];
            parent[neighbor] = static_cast<std::int64_t>(vertex);
            stack[top++] = neighbor;
        }
    }
}

std::size_t farthest(std::size_t n, const std::array<std::int64_t, max_n> &distance) noexcept {
    std::size_t best = 0;
    for (std::size_t vertex = 1; vertex < n; ++vertex) {
        if (distance[vertex] > distance[best] ||
            (distance[vertex] == distance[best] && vertex < best)) best = vertex;
    }
    return best;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t tree_diameter(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_input_values) return -1;
    const auto n_value = input[0];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != 1 + 3 * (n - 1)) return -1;

    std::array<std::array<bool, max_n>, max_n> adjacent{};
    std::array<std::array<std::int64_t, max_n>, max_n> weight{};
    std::array<std::size_t, max_n> dsu_parent{}, dsu_size{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    for (std::size_t edge = 0; edge + 1 < n; ++edge) {
        const auto offset = 1 + 3 * edge;
        const auto left_value = input[offset];
        const auto right_value = input[offset + 1];
        const auto edge_weight = input[offset + 2];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value ||
            edge_weight < 1 || edge_weight > 1'000'000'000) return -1;
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
        weight[left][right] = weight[right][left] = edge_weight;
    }

    std::array<std::int64_t, max_n> distance{}, parent{};
    traverse(n, 0, adjacent, weight, distance, parent);
    const auto first_endpoint = farthest(n, distance);
    traverse(n, first_endpoint, adjacent, weight, distance, parent);
    const auto second_endpoint = farthest(n, distance);
    std::array<std::size_t, max_n> reverse_path{};
    std::size_t path_length = 0;
    auto current = static_cast<std::int64_t>(second_endpoint);
    while (current >= 0) {
        reverse_path[path_length++] = static_cast<std::size_t>(current);
        if (static_cast<std::size_t>(current) == first_endpoint) break;
        current = parent[static_cast<std::size_t>(current)];
    }

    std::array<std::int64_t, max_output_values> staged{};
    std::size_t used = 0;
    staged[used++] = distance[second_endpoint];
    staged[used++] = static_cast<std::int64_t>(path_length);
    for (std::size_t position = 0; position < path_length; ++position)
        staged[used++] = static_cast<std::int64_t>(reverse_path[path_length - 1 - position]);
    const auto required = 8 * used;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < used; ++index)
        store_i64_le(output, 8 * index, staged[index]);
    return static_cast<std::int64_t>(required);
}
