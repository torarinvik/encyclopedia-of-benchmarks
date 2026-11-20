#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t kMaxN = 64;
constexpr std::size_t kMaxInputLength = 1 + 2 * (kMaxN - 1);

std::size_t find_root(std::array<std::size_t, kMaxN>& parent,
                      std::size_t item) noexcept {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

void store_i64_le(std::uint8_t* output, std::size_t offset,
                  std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t tree_center(const std::int64_t* input,
                                    std::size_t length, std::uint8_t* output,
                                    std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > kMaxInputLength) return -1;
    const std::int64_t n_value = input[0];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != 1 + 2 * (n - 1)) return -1;

    std::array<std::array<std::size_t, kMaxN>, kMaxN> adjacency{};
    std::array<std::size_t, kMaxN> adjacency_count{};
    std::array<std::size_t, kMaxN> degree{};
    std::array<std::size_t, kMaxN> parent{}, component_size{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        parent[vertex] = vertex;
        component_size[vertex] = 1;
    }
    for (std::size_t edge = 0; edge + 1 < n; ++edge) {
        const std::size_t offset = 1 + 2 * edge;
        const std::int64_t left_value = input[offset], right_value = input[offset + 1];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value) return -1;
        const auto left = static_cast<std::size_t>(left_value);
        const auto right = static_cast<std::size_t>(right_value);
        auto root_left = find_root(parent, left), root_right = find_root(parent, right);
        if (root_left == root_right) return -1;
        if (component_size[root_left] < component_size[root_right])
            std::swap(root_left, root_right);
        parent[root_right] = root_left;
        component_size[root_left] += component_size[root_right];
        adjacency[left][adjacency_count[left]++] = right;
        adjacency[right][adjacency_count[right]++] = left;
        ++degree[left];
        ++degree[right];
    }
    if (n > 1 && component_size[find_root(parent, 0)] != n) return -1;

    std::array<bool, kMaxN> active{};
    std::array<std::size_t, kMaxN> leaves{};
    std::size_t leaf_count = 0;
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        active[vertex] = true;
        if (degree[vertex] <= 1) leaves[leaf_count++] = vertex;
    }
    std::size_t remaining = n;
    while (remaining > 2) {
        for (std::size_t index = 0; index < leaf_count; ++index)
            active[leaves[index]] = false;
        remaining -= leaf_count;
        for (std::size_t index = 0; index < leaf_count; ++index) {
            const auto leaf = leaves[index];
            for (std::size_t edge = 0; edge < adjacency_count[leaf]; ++edge) {
                const auto neighbor = adjacency[leaf][edge];
                if (active[neighbor]) --degree[neighbor];
            }
        }
        if (remaining <= 2) break;
        leaf_count = 0;
        for (std::size_t vertex = 0; vertex < n; ++vertex)
            if (active[vertex] && degree[vertex] == 1) leaves[leaf_count++] = vertex;
    }

    std::array<std::int64_t, 2> centers{};
    std::size_t center_count = 0;
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        if (active[vertex]) centers[center_count++] = static_cast<std::int64_t>(vertex);
    const std::size_t required = 8 * center_count;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < center_count; ++index)
        store_i64_le(output, 8 * index, centers[index]);
    return static_cast<std::int64_t>(required);
}
