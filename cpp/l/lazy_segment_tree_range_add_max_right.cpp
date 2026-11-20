/* Lazy range addition and sum-monoid max_right boundary searches. */
#include <cstddef>
#include <cstdint>

namespace {
void apply(std::int64_t *tree, std::int64_t *lazy, std::size_t node,
           std::size_t segment_length, std::int64_t delta) noexcept
{
    tree[node] += delta * static_cast<std::int64_t>(segment_length);
    lazy[node] += delta;
}

void push(std::int64_t *tree, std::int64_t *lazy, std::size_t node,
          std::size_t segment_length) noexcept
{
    if (segment_length > 1 && lazy[node] != 0) {
        const auto child_length = segment_length / 2;
        apply(tree, lazy, 2 * node, child_length, lazy[node]);
        apply(tree, lazy, 2 * node + 1, child_length, lazy[node]);
        lazy[node] = 0;
    }
}

void range_add(std::int64_t *tree, std::int64_t *lazy, std::size_t node,
               std::size_t low, std::size_t high, std::size_t query_low,
               std::size_t query_high, std::int64_t delta) noexcept
{
    if (query_low >= query_high) return;
    if (query_high <= low || high <= query_low) return;
    if (query_low <= low && high <= query_high) {
        apply(tree, lazy, node, high - low, delta);
        return;
    }
    push(tree, lazy, node, high - low);
    const auto middle = (low + high) / 2;
    if (query_low < middle)
        range_add(tree, lazy, 2 * node, low, middle, query_low, query_high, delta);
    if (query_high > middle)
        range_add(tree, lazy, 2 * node + 1, middle, high, query_low, query_high, delta);
    tree[node] = tree[2 * node] + tree[2 * node + 1];
}

std::size_t max_right(std::int64_t *tree, std::int64_t *lazy,
                      std::size_t node, std::size_t low, std::size_t high,
                      std::size_t n, std::size_t left, std::int64_t limit,
                      std::int64_t &accumulated) noexcept
{
    if (high <= left) return high;
    if (low >= n) return n;
    if (left <= low && high <= n && accumulated + tree[node] <= limit) {
        accumulated += tree[node];
        return high;
    }
    if (high - low == 1) return low;
    push(tree, lazy, node, high - low);
    const auto middle = (low + high) / 2;
    const auto first = max_right(tree, lazy, 2 * node, low, middle,
                                 n, left, limit, accumulated);
    if (first < middle && first >= left) return first;
    return max_right(tree, lazy, 2 * node + 1, middle, high,
                     n, left, limit, accumulated);
}
}

extern "C" std::int64_t lazy_segment_tree_range_add_max_right(
    const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 3 || length > 67) return -1;
    if (input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 12) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto operations = static_cast<std::size_t>(input[1]);
    if (length != 2 + n + 4 * operations) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 31) return -1;
    for (std::size_t operation = 0; operation < operations; ++operation) {
        const auto position = 2 + n + 4 * operation;
        const auto opcode = input[position];
        const auto left = input[position + 1];
        const auto right = input[position + 2];
        const auto extra = input[position + 3];
        if (opcode == 0) {
            if (left < 0 || left > static_cast<std::int64_t>(n) || right < left
                || right > static_cast<std::int64_t>(n) || extra < 0 || extra > 31) return -1;
        } else if (opcode == 1) {
            if (left < 0 || left > static_cast<std::int64_t>(n) || right < 0
                || right > 8192 || extra != 0) return -1;
        } else return -1;
    }

    std::size_t size = 1;
    while (size < n) size *= 2;
    std::int64_t tree[64]{};
    std::int64_t lazy[64]{};
    for (std::size_t i = 0; i < n; ++i) tree[size + i] = input[2 + i];
    for (std::size_t node = size; node > 1; ) {
        --node;
        tree[node] = tree[2 * node] + tree[2 * node + 1];
    }
    std::size_t query_index = 0;
    std::int64_t result = 0;
    for (std::size_t operation = 0; operation < operations; ++operation) {
        const auto position = 2 + n + 4 * operation;
        const auto left = static_cast<std::size_t>(input[position + 1]);
        const auto right = static_cast<std::size_t>(input[position + 2]);
        if (input[position] == 0) {
            range_add(tree, lazy, 1, 0, size, left, right, input[position + 3]);
        } else {
            std::int64_t accumulated = 0;
            const auto boundary = max_right(tree, lazy, 1, 0, size, n,
                                            left, static_cast<std::int64_t>(right), accumulated);
            result |= static_cast<std::int64_t>(boundary) << (5 * query_index);
            ++query_index;
        }
    }
    return result;
}
