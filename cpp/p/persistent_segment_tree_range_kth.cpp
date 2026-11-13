#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 32;
constexpr int max_q = 32;
constexpr std::size_t max_input_length = 131;
constexpr int max_nodes = 193;
constexpr std::int64_t invalid_result = INT64_MIN;

int lower_bound_i64(const std::int64_t* values, int length, std::int64_t target) {
    int low = 0;
    int high = length;
    while (low < high) {
        const int middle = low + (high - low) / 2;
        if (values[middle] < target) low = middle + 1;
        else high = middle;
    }
    return low;
}

std::int64_t solve(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 2 || length > max_input_length) return invalid_result;
    if (input[0] < 1 || input[0] > max_n || input[1] < 0 || input[1] > max_q) return invalid_result;
    const int n = static_cast<int>(input[0]);
    const int q = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(2 + n + 3 * q)) return invalid_result;

    std::int64_t coordinates[max_n]{};
    for (int i = 0; i < n; ++i) {
        const auto value = input[2 + i];
        if (value < -1000 || value > 1000) return invalid_result;
        coordinates[i] = value;
    }
    for (int i = 1; i < n; ++i) {
        const auto value = coordinates[i];
        int j = i;
        while (j > 0 && coordinates[j - 1] > value) {
            coordinates[j] = coordinates[j - 1];
            --j;
        }
        coordinates[j] = value;
    }
    int distinct = 0;
    for (int i = 0; i < n; ++i) {
        if (distinct == 0 || coordinates[i] != coordinates[distinct - 1]) coordinates[distinct++] = coordinates[i];
    }
    const std::size_t query_offset = static_cast<std::size_t>(2 + n);
    for (int qi = 0; qi < q; ++qi) {
        const auto left = input[query_offset + static_cast<std::size_t>(3 * qi)];
        const auto right = input[query_offset + static_cast<std::size_t>(3 * qi + 1)];
        const auto k = input[query_offset + static_cast<std::size_t>(3 * qi + 2)];
        if (left < 0 || right < left || right >= n || k < 1 || k > right - left + 1) return invalid_result;
    }

    std::int32_t left_child[max_nodes]{};
    std::int32_t right_child[max_nodes]{};
    std::int32_t counts[max_nodes]{};
    std::int32_t roots[max_n + 1]{};
    std::int32_t node_count = 1;
    for (int i = 0; i < n; ++i) {
        const int rank = lower_bound_i64(coordinates, distinct, input[2 + i]);
        const std::int32_t previous_root = roots[i];
        if (node_count >= max_nodes) return invalid_result;
        const std::int32_t new_root = node_count++;
        left_child[new_root] = left_child[previous_root];
        right_child[new_root] = right_child[previous_root];
        counts[new_root] = counts[previous_root] + 1;
        std::int32_t old_node = previous_root;
        std::int32_t new_node = new_root;
        int low = 0;
        int high = distinct;
        while (high - low > 1) {
            const int middle = low + (high - low) / 2;
            const std::int32_t old_child = rank < middle ? left_child[old_node] : right_child[old_node];
            if (node_count >= max_nodes) return invalid_result;
            const std::int32_t new_child = node_count++;
            left_child[new_child] = left_child[old_child];
            right_child[new_child] = right_child[old_child];
            counts[new_child] = counts[old_child] + 1;
            if (rank < middle) {
                left_child[new_node] = new_child;
                high = middle;
            } else {
                right_child[new_node] = new_child;
                low = middle;
            }
            old_node = old_child;
            new_node = new_child;
        }
        roots[i + 1] = new_root;
    }

    std::int64_t checksum = 0;
    for (int qi = 0; qi < q; ++qi) {
        const auto offset = query_offset + static_cast<std::size_t>(3 * qi);
        const int left = static_cast<int>(input[offset]);
        const int right = static_cast<int>(input[offset + 1]);
        int k = static_cast<int>(input[offset + 2]);
        std::int32_t before = roots[left];
        std::int32_t after = roots[right + 1];
        int low = 0;
        int high = distinct;
        while (high - low > 1) {
            const int middle = low + (high - low) / 2;
            const auto in_left = left_child[after];
            const auto out_left = left_child[before];
            const int left_count = counts[in_left] - counts[out_left];
            if (k <= left_count) {
                before = out_left;
                after = in_left;
                high = middle;
            } else {
                k -= left_count;
                before = right_child[before];
                after = right_child[after];
                low = middle;
            }
        }
        checksum += static_cast<std::int64_t>(qi + 1) * coordinates[low];
    }
    return checksum;
}
}

extern "C" std::int64_t persistent_segment_tree_range_kth(const std::int64_t* input, std::size_t length) noexcept {
    return solve(input, length);
}
