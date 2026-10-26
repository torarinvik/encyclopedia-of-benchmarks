#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxText = 8;
constexpr std::size_t kMaxInput = 10;
constexpr int kMaxSuffixes = kMaxText + 1;
constexpr int kMaxNodes = 2 * kMaxSuffixes - 1;
constexpr int kMaxOutputWords = 1 + 5 * kMaxNodes;

struct TreeRecord {
    std::int64_t parent_rep, parent_depth, node_rep, node_depth, leaf_start;
};

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

int symbol_at(const std::int64_t *input, int text_length, int position)
{
    return position == text_length ? 0 : static_cast<int>(input[position + 1]);
}

bool suffix_less(const std::int64_t *input, int text_length, int left, int right)
{
    const int total = text_length + 1;
    while (left < total && right < total) {
        const int a = symbol_at(input, text_length, left);
        const int b = symbol_at(input, text_length, right);
        if (a != b) return a < b;
        ++left; ++right;
    }
    return left == total && right != total;
}

bool record_less(const TreeRecord &left, const TreeRecord &right)
{
    if (left.node_depth != right.node_depth) return left.node_depth < right.node_depth;
    if (left.node_rep != right.node_rep) return left.node_rep < right.node_rep;
    return left.leaf_start < right.leaf_start;
}
}

extern "C" std::int64_t suffix_tree_from_sa_lcp(const std::int64_t *input,
                                                  std::size_t length,
                                                  std::uint8_t *output,
                                                  std::size_t capacity)
{
    if (input == nullptr || length < 1 || length > kMaxInput) return -1;
    const auto n_raw = input[0];
    if (n_raw < 0 || n_raw > kMaxText || length != static_cast<std::size_t>(n_raw) + 1) return -1;
    const int n = static_cast<int>(n_raw);
    for (int i = 0; i < n; ++i) if (input[i + 1] < 1 || input[i + 1] > 255) return -1;

    const int suffix_count = n + 1;
    int suffix_array[kMaxSuffixes];
    int lcp[kMaxSuffixes]{};
    for (int i = 0; i < suffix_count; ++i) suffix_array[i] = i;
    for (int i = 1; i < suffix_count; ++i) {
        const int value = suffix_array[i];
        int j = i;
        while (j > 0 && suffix_less(input, n, value, suffix_array[j - 1])) {
            suffix_array[j] = suffix_array[j - 1];
            --j;
        }
        suffix_array[j] = value;
    }
    for (int rank = 1; rank < suffix_count; ++rank) {
        int left = suffix_array[rank - 1], right = suffix_array[rank], common = 0;
        while (left + common < suffix_count && right + common < suffix_count
            && symbol_at(input, n, left + common) == symbol_at(input, n, right + common)) ++common;
        lcp[rank] = common;
    }

    int parent[kMaxNodes], depth[kMaxNodes], representative[kMaxNodes], leaf[kMaxNodes], last_child[kMaxNodes];
    int stack[kMaxNodes];
    int node_count = 1, stack_size = 1;
    parent[0] = -1; depth[0] = 0; representative[0] = -1; leaf[0] = -1; last_child[0] = -1;
    stack[0] = 0;
    for (int rank = 0; rank < suffix_count; ++rank) {
        if (rank > 0) {
            const int common = lcp[rank];
            while (stack_size > 1 && depth[stack[stack_size - 1]] > common) --stack_size;
            const int top = stack[stack_size - 1];
            if (depth[top] < common) {
                const int old_child = last_child[top];
                if (old_child < 0) return -1;
                const int internal = node_count++;
                parent[internal] = top; depth[internal] = common;
                representative[internal] = representative[old_child]; leaf[internal] = -1;
                last_child[internal] = old_child;
                parent[old_child] = internal;
                last_child[top] = internal;
                stack[stack_size++] = internal;
            }
        }
        const int owner = stack[stack_size - 1];
        const int suffix_start = suffix_array[rank];
        const int new_leaf = node_count++;
        parent[new_leaf] = owner; depth[new_leaf] = suffix_count - suffix_start;
        representative[new_leaf] = suffix_start; leaf[new_leaf] = suffix_start;
        last_child[new_leaf] = -1;
        last_child[owner] = new_leaf;
    }

    TreeRecord records[kMaxNodes];
    for (int node = 0; node < node_count; ++node) {
        if (node == 0) records[node] = {-1, -1, -1, 0, -1};
        else {
            const int p = parent[node];
            records[node] = {representative[p], depth[p], representative[node], depth[node], leaf[node]};
        }
    }
    for (int i = 1; i < node_count; ++i) {
        const auto value = records[i];
        int j = i;
        while (j > 0 && record_less(value, records[j - 1])) { records[j] = records[j - 1]; --j; }
        records[j] = value;
    }
    std::int64_t staged[kMaxOutputWords]{};
    staged[0] = node_count;
    std::size_t words = 1;
    for (int node = 0; node < node_count; ++node) {
        staged[words++] = records[node].parent_rep;
        staged[words++] = records[node].parent_depth;
        staged[words++] = records[node].node_rep;
        staged[words++] = records[node].node_depth;
        staged[words++] = records[node].leaf_start;
    }
    const auto bytes = words * 8;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t word = 0; word < words; ++word) store_i64_le(output, word * 8, staged[word]);
    return static_cast<std::int64_t>(bytes);
}
