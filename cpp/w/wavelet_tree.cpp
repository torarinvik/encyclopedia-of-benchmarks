#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr std::size_t MAX_ITEMS = 64;
constexpr std::size_t MAX_QUERIES = 128;
constexpr std::size_t MAX_NODES = 12 * MAX_ITEMS;
constexpr std::size_t MAX_PACKED_LENGTH = MAX_ITEMS + 2 + 5 * MAX_QUERIES;
constexpr std::int64_t CHECKSUM_OFFSET = 1'000'001;

struct WaveletNode {
    std::int64_t low = 0;
    std::int64_t high = 0;
    int left = -1;
    int right = -1;
    std::vector<std::size_t> prefix_left;
};

WaveletNode nodes[MAX_NODES];
int used_nodes = 0;

// Build a stable value partition. prefix_left[k] counts left values in [0,k).
int build_tree(const std::int64_t *values, std::size_t length,
               std::int64_t low, std::int64_t high)
{
    const int node_id = used_nodes++;
    WaveletNode &node = nodes[node_id];
    node.low = low;
    node.high = high;
    node.left = -1;
    node.right = -1;
    node.prefix_left.assign(length + 1, 0);

    if (low == high || length == 0) {
        return node_id;
    }

    const std::int64_t middle = low + (high - low) / 2;
    std::vector<std::int64_t> left_values;
    std::vector<std::int64_t> right_values;
    left_values.reserve(length);
    right_values.reserve(length);

    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] <= middle) {
            left_values.push_back(values[i]);
        } else {
            right_values.push_back(values[i]);
        }
        node.prefix_left[i + 1] = left_values.size();
    }

    if (!left_values.empty()) {
        node.left = build_tree(left_values.data(), left_values.size(), low, middle);
    }
    if (!right_values.empty()) {
        node.right = build_tree(right_values.data(), right_values.size(), middle + 1, high);
    }
    return node_id;
}

// Count value occurrences in the first `count` positions of this node.
std::int64_t rank_prefix(int node_id, std::int64_t value, std::size_t count)
{
    if (node_id < 0 || count == 0) {
        return 0;
    }
    const WaveletNode &node = nodes[node_id];
    if (node.low == node.high) {
        return node.low == value ? static_cast<std::int64_t>(count) : 0;
    }

    const std::size_t left_count = node.prefix_left[count];
    const std::int64_t middle = node.low + (node.high - node.low) / 2;
    if (value <= middle) {
        return rank_prefix(node.left, value, left_count);
    }
    return rank_prefix(node.right, value, count - left_count);
}

// Return the zero-based kth value in the remapped half-open interval [left,right).
std::int64_t quantile(int node_id, std::size_t left, std::size_t right, std::size_t k)
{
    const WaveletNode &node = nodes[node_id];
    if (node.low == node.high) {
        return node.low;
    }

    const std::size_t left_before = node.prefix_left[left];
    const std::size_t left_after = node.prefix_left[right];
    const std::size_t in_left = left_after - left_before;
    if (k < in_left) {
        return quantile(node.left, left_before, left_after, k);
    }
    return quantile(node.right, left - left_before, right - left_after, k - in_left);
}

// Count values in [value_low,value_high] for the remapped [left,right) interval.
std::int64_t range_count(int node_id, std::size_t left, std::size_t right,
                         std::int64_t value_low, std::int64_t value_high)
{
    if (node_id < 0 || left >= right) {
        return 0;
    }
    const WaveletNode &node = nodes[node_id];
    if (value_high < node.low || value_low > node.high) {
        return 0;
    }
    if (value_low <= node.low && node.high <= value_high) {
        return static_cast<std::int64_t>(right - left);
    }
    if (node.low == node.high) {
        return 0;
    }

    const std::size_t left_before = node.prefix_left[left];
    const std::size_t left_after = node.prefix_left[right];
    return range_count(node.left, left_before, left_after, value_low, value_high)
         + range_count(node.right, left - left_before, right - left_after,
                       value_low, value_high);
}
} // namespace

extern "C" std::int64_t wavelet_tree_benchmark(const std::int64_t *values,
                                                std::size_t length) noexcept
{
    if (values == nullptr || length < 3 || length > MAX_PACKED_LENGTH
        || values[0] < 1 || values[0] > static_cast<std::int64_t>(MAX_ITEMS)) {
        return -1;
    }

    const std::size_t item_count = static_cast<std::size_t>(values[0]);
    if (length < item_count + 2) {
        return -1;
    }

    std::int64_t value_low = values[1];
    std::int64_t value_high = values[1];
    for (std::size_t i = 0; i < item_count; ++i) {
        const std::int64_t value = values[i + 1];
        if (value < -1000 || value > 1000) {
            return -1;
        }
        value_low = std::min(value_low, value);
        value_high = std::max(value_high, value);
    }

    const std::int64_t query_count_value = values[item_count + 1];
    if (query_count_value < 0 || query_count_value > static_cast<std::int64_t>(MAX_QUERIES)
        || length != item_count + 2 + 5 * static_cast<std::size_t>(query_count_value)) {
        return -1;
    }

    used_nodes = 0;
    const int root = build_tree(values + 1, item_count, value_low, value_high);
    const std::size_t query_count = static_cast<std::size_t>(query_count_value);
    std::int64_t checksum = 0;

    for (std::size_t query_index = 0; query_index < query_count; ++query_index) {
        const std::size_t offset = item_count + 2 + 5 * query_index;
        const std::int64_t opcode = values[offset];
        const std::int64_t a = values[offset + 1];
        const std::int64_t b = values[offset + 2];
        const std::int64_t c = values[offset + 3];
        const std::int64_t d = values[offset + 4];
        std::int64_t answer;

        if (opcode == 0) {
            if (a < -1000 || a > 1000 || b < -1 || b >= static_cast<std::int64_t>(item_count)) {
                return -1;
            }
            answer = rank_prefix(root, a, static_cast<std::size_t>(b + 1));
        } else if (opcode == 1) {
            if (a < 0 || b < a || b >= static_cast<std::int64_t>(item_count)
                || c < 0 || c > b - a) {
                return -1;
            }
            answer = quantile(root, static_cast<std::size_t>(a),
                              static_cast<std::size_t>(b) + 1, static_cast<std::size_t>(c));
        } else if (opcode == 2) {
            if (a < 0 || b < a || b >= static_cast<std::int64_t>(item_count)
                || c > d || c < -1000 || d > 1000) {
                return -1;
            }
            answer = range_count(root, static_cast<std::size_t>(a),
                                 static_cast<std::size_t>(b) + 1, c, d);
        } else {
            return -1;
        }

        checksum += static_cast<std::int64_t>(query_index + 1) * (answer + CHECKSUM_OFFSET);
    }
    return checksum;
}
