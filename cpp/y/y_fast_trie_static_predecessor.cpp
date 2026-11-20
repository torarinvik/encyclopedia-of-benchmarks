#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_keys = 256;
constexpr std::size_t max_queries = 256;
constexpr std::size_t cluster_size = 16;
constexpr std::size_t max_separators = 16;
constexpr std::size_t max_trie_nodes = 257;
constexpr int universe_bits = 16;
constexpr std::size_t max_input = 514;
constexpr std::size_t max_parseable = 515;

struct TrieNode {
    std::array<int, 2> child{};
    int min_rank = -1;
    int terminal_rank = -1;
};

int bucket_for(const std::array<TrieNode, max_trie_nodes> &trie,
               std::size_t separator_count, std::int64_t query) noexcept {
    int node = 0;
    int candidate = -1;
    for (int bit = universe_bits - 1; bit >= 0; --bit) {
        const int query_bit = static_cast<int>((query >> bit) & 1);
        if (query_bit == 0) {
            const int right = trie[static_cast<std::size_t>(node)].child[1];
            if (right >= 0 && (candidate < 0 ||
                               trie[static_cast<std::size_t>(right)].min_rank < candidate))
                candidate = trie[static_cast<std::size_t>(right)].min_rank;
            const int left = trie[static_cast<std::size_t>(node)].child[0];
            if (left < 0) return candidate;
            node = left;
        } else {
            const int right = trie[static_cast<std::size_t>(node)].child[1];
            if (right < 0) return candidate;
            node = right;
        }
    }
    const auto terminal = trie[static_cast<std::size_t>(node)].terminal_rank;
    if (terminal >= 0) return terminal;
    if (candidate >= 0) return candidate;
    return static_cast<int>(separator_count) - 1;
}
} // namespace

extern "C" std::int64_t y_fast_trie_static_predecessor(const std::int64_t *input,
                                                        std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable) return -1;
    const std::int64_t n_value = input[0];
    const std::int64_t q_value = input[1];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(max_keys) ||
        q_value < 0 || q_value > static_cast<std::int64_t>(max_queries)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto query_count = static_cast<std::size_t>(q_value);
    if (length != 2 + n + query_count || length > max_input) return -1;

    std::array<std::int64_t, max_keys> keys{};
    std::array<std::int64_t, max_queries> queries{};
    for (std::size_t index = 0; index < n; ++index) {
        keys[index] = input[2 + index];
        if (keys[index] < 0 || keys[index] > 65535) return -1;
    }
    for (std::size_t index = 1; index < n; ++index) {
        const auto key = keys[index];
        std::size_t position = index;
        while (position > 0 && key < keys[position - 1]) {
            keys[position] = keys[position - 1];
            --position;
        }
        keys[position] = key;
    }
    for (std::size_t index = 1; index < n; ++index)
        if (keys[index] == keys[index - 1]) return -1;
    for (std::size_t index = 0; index < query_count; ++index) {
        queries[index] = input[2 + n + index];
        if (queries[index] < 0 || queries[index] > 65535) return -1;
    }
    if (n == 0 || query_count == 0) return 0;

    const std::size_t separator_count = (n + cluster_size - 1) / cluster_size;
    std::array<std::int64_t, max_separators> separators{};
    for (std::size_t rank = 0; rank < separator_count; ++rank) {
        std::size_t end = (rank + 1) * cluster_size;
        if (end > n) end = n;
        separators[rank] = keys[end - 1];
    }

    std::array<TrieNode, max_trie_nodes> trie{};
    for (auto &node : trie) {
        node.child = {-1, -1};
        node.min_rank = -1;
        node.terminal_rank = -1;
    }
    std::size_t trie_size = 1;
    for (std::size_t rank = 0; rank < separator_count; ++rank) {
        int node = 0;
        auto &root_minimum = trie[0].min_rank;
        if (root_minimum < 0 || static_cast<int>(rank) < root_minimum)
            root_minimum = static_cast<int>(rank);
        for (int bit = universe_bits - 1; bit >= 0; --bit) {
            const int branch = static_cast<int>((separators[rank] >> bit) & 1);
            int next = trie[static_cast<std::size_t>(node)].child[static_cast<std::size_t>(branch)];
            if (next < 0) {
                next = static_cast<int>(trie_size++);
                trie[static_cast<std::size_t>(node)].child[static_cast<std::size_t>(branch)] = next;
            }
            node = next;
            auto &minimum = trie[static_cast<std::size_t>(node)].min_rank;
            if (minimum < 0 || static_cast<int>(rank) < minimum)
                minimum = static_cast<int>(rank);
        }
        trie[static_cast<std::size_t>(node)].terminal_rank = static_cast<int>(rank);
    }

    std::int64_t checksum = 0;
    for (std::size_t query_index = 0; query_index < query_count; ++query_index) {
        const std::int64_t query = queries[query_index];
        int bucket = bucket_for(trie, separator_count, query);
        if (bucket < 0) bucket = static_cast<int>(separator_count) - 1;
        const std::size_t start = static_cast<std::size_t>(bucket) * cluster_size;
        std::size_t end = start + cluster_size;
        if (end > n) end = n;

        std::size_t low = start, high = end;
        while (low < high) {
            const auto middle = low + (high - low) / 2;
            if (keys[middle] < query) low = middle + 1;
            else high = middle;
        }
        const std::int64_t predecessor = low > start ? keys[low - 1] :
            (start > 0 ? keys[start - 1] : -1);

        low = start;
        high = end;
        while (low < high) {
            const auto middle = low + (high - low) / 2;
            if (keys[middle] <= query) low = middle + 1;
            else high = middle;
        }
        const std::int64_t successor = low < end ? keys[low] : (end < n ? keys[end] : -1);
        const std::int64_t contribution = (predecessor + 1) +
            INT64_C(65537) * (successor + 1);
        checksum += static_cast<std::int64_t>(query_index + 1) * contribution;
    }
    return checksum;
}
