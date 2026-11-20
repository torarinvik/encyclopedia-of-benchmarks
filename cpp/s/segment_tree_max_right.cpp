/* Point updates and sum-monoid max_right boundary searches. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t segment_tree_max_right(const std::int64_t *input,
                                                 std::size_t length) noexcept
{
    if (input == nullptr || length < 2 || length > 55) return -1;
    if (input[0] < 0 || input[0] > 16 || input[1] < 0 || input[1] > 12) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto operations = static_cast<std::size_t>(input[1]);
    if (length != 2 + n + 3 * operations) return -1;
    std::int64_t tree[64]{};
    std::size_t size = 1;
    while (size < n) size *= 2;
    for (std::size_t i = 0; i < n; ++i) {
        const auto value = input[2 + i];
        if (value < 0 || value > 1000) return -1;
        tree[size + i] = value;
    }
    for (std::size_t node = size; node > 1; ) {
        --node;
        tree[node] = tree[2 * node] + tree[2 * node + 1];
    }

    std::size_t query_index = 0;
    std::int64_t result = 0;
    std::size_t cursor = 2 + n;
    for (std::size_t operation = 0; operation < operations; ++operation) {
        const auto opcode = input[cursor];
        const auto first = input[cursor + 1];
        const auto second = input[cursor + 2];
        cursor += 3;
        if (opcode == 0) {
            if (first < 0 || first >= static_cast<std::int64_t>(n) || second < 0 || second > 1000) return -1;
            std::size_t node = size + static_cast<std::size_t>(first);
            tree[node] = second;
            while (node > 1) {
                node /= 2;
                tree[node] = tree[2 * node] + tree[2 * node + 1];
            }
        } else if (opcode == 1) {
            if (first < 0 || first > static_cast<std::int64_t>(n) || second < 0 || second > 16000) return -1;
            const auto left = static_cast<std::size_t>(first);
            std::size_t boundary = n;
            if (left < n) {
                std::size_t position = left + size;
                std::int64_t accumulated = 0;
                bool done = false;
                while (!done) {
                    while ((position & 1) == 0) position /= 2;
                    if (accumulated + tree[position] > second) {
                        while (position < size) {
                            position *= 2;
                            if (accumulated + tree[position] <= second) {
                                accumulated += tree[position];
                                ++position;
                            }
                        }
                        boundary = position - size;
                        if (boundary > n) boundary = n;
                        done = true;
                    } else {
                        accumulated += tree[position];
                        ++position;
                        if ((position & (position - 1)) == 0) done = true;
                    }
                }
            }
            result |= static_cast<std::int64_t>(boundary) << (5 * query_index);
            ++query_index;
        } else {
            return -1;
        }
    }
    return result;
}
