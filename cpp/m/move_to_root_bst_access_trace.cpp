#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t move_to_root_bst_access_trace(const std::int64_t *values,
                                                        std::size_t length) {
    constexpr std::size_t max_initial = 16;
    constexpr std::size_t max_accesses = 32;
    if (values == nullptr || length < 2 || length > 51) return -1;
    const auto initial_count = values[0];
    if (initial_count < 0 || initial_count > static_cast<std::int64_t>(max_initial)) return -1;
    const auto query_count_index = 1 + static_cast<std::size_t>(initial_count);
    if (length < query_count_index + 1) return -1;
    const auto access_count = values[query_count_index];
    if (access_count < 0 || access_count > static_cast<std::int64_t>(max_accesses)
        || length != query_count_index + 1 + static_cast<std::size_t>(access_count)) return -1;

    std::array<std::int64_t, max_initial> keys{};
    std::array<std::int32_t, max_initial> left;
    std::array<std::int32_t, max_initial> right;
    std::array<std::int32_t, max_initial> parent;
    left.fill(-1);
    right.fill(-1);
    parent.fill(-1);
    for (std::size_t index = 0; index < static_cast<std::size_t>(initial_count); ++index) {
        const auto key = values[1 + index];
        if (key < -100 || key > 100) return -1;
        for (std::size_t earlier = 0; earlier < index; ++earlier) {
            if (values[1 + earlier] == key) return -1;
        }
        keys[index] = key;
    }
    for (std::size_t query = 0; query < static_cast<std::size_t>(access_count); ++query) {
        const auto key = values[query_count_index + 1 + query];
        if (key < -100 || key > 100) return -1;
    }

    std::int32_t root = -1;
    for (std::int32_t node = 0; node < initial_count; ++node) {
        if (root == -1) {
            root = node;
            continue;
        }
        auto current = root;
        for (;;) {
            if (keys[node] < keys[static_cast<std::size_t>(current)]) {
                if (left[static_cast<std::size_t>(current)] == -1) {
                    left[static_cast<std::size_t>(current)] = node;
                    parent[static_cast<std::size_t>(node)] = current;
                    break;
                }
                current = left[static_cast<std::size_t>(current)];
            } else {
                if (right[static_cast<std::size_t>(current)] == -1) {
                    right[static_cast<std::size_t>(current)] = node;
                    parent[static_cast<std::size_t>(node)] = current;
                    break;
                }
                current = right[static_cast<std::size_t>(current)];
            }
        }
    }

    std::int64_t result = 0;
    for (std::size_t query_number = 1; query_number <= static_cast<std::size_t>(access_count); ++query_number) {
        const auto key = values[query_count_index + query_number];
        auto node = root;
        std::int64_t comparisons = 0;
        while (node != -1) {
            ++comparisons;
            if (key == keys[static_cast<std::size_t>(node)]) break;
            node = key < keys[static_cast<std::size_t>(node)]
                ? left[static_cast<std::size_t>(node)] : right[static_cast<std::size_t>(node)];
        }
        while (node != -1 && parent[static_cast<std::size_t>(node)] != -1) {
            const auto old_parent = parent[static_cast<std::size_t>(node)];
            const auto grandparent = parent[static_cast<std::size_t>(old_parent)];
            if (left[static_cast<std::size_t>(old_parent)] == node) {
                const auto middle = right[static_cast<std::size_t>(node)];
                right[static_cast<std::size_t>(node)] = old_parent;
                left[static_cast<std::size_t>(old_parent)] = middle;
                if (middle != -1) parent[static_cast<std::size_t>(middle)] = old_parent;
            } else {
                const auto middle = left[static_cast<std::size_t>(node)];
                left[static_cast<std::size_t>(node)] = old_parent;
                right[static_cast<std::size_t>(old_parent)] = middle;
                if (middle != -1) parent[static_cast<std::size_t>(middle)] = old_parent;
            }
            parent[static_cast<std::size_t>(old_parent)] = node;
            parent[static_cast<std::size_t>(node)] = grandparent;
            if (grandparent == -1) root = node;
            else if (left[static_cast<std::size_t>(grandparent)] == old_parent)
                left[static_cast<std::size_t>(grandparent)] = node;
            else right[static_cast<std::size_t>(grandparent)] = node;
        }
        result += static_cast<std::int64_t>(query_number) * comparisons;
    }
    return result;
}
