/* Point updates and sum-monoid max_right boundary searches. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

int64_t segment_tree_max_right(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > 55) return -1;
    if (input[0] < 0 || input[0] > 16 || input[1] < 0 || input[1] > 12) return -1;
    const size_t n = (size_t)input[0];
    const size_t operations = (size_t)input[1];
    if (length != 2 + n + 3 * operations) return -1;
    int64_t tree[64] = {0};
    size_t size = 1;
    while (size < n) size *= 2;
    for (size_t i = 0; i < n; ++i) {
        const int64_t value = input[2 + i];
        if (value < 0 || value > 1000) return -1;
        tree[size + i] = value;
    }
    for (size_t node = size; node > 1; ) {
        --node;
        tree[node] = tree[node * 2] + tree[node * 2 + 1];
    }

    size_t query_index = 0;
    int64_t result = 0;
    size_t cursor = 2 + n;
    for (size_t operation = 0; operation < operations; ++operation) {
        const int64_t opcode = input[cursor];
        const int64_t first = input[cursor + 1];
        const int64_t second = input[cursor + 2];
        cursor += 3;
        if (opcode == 0) {
            if (first < 0 || first >= (int64_t)n || second < 0 || second > 1000) return -1;
            size_t node = size + (size_t)first;
            tree[node] = second;
            while (node > 1) {
                node /= 2;
                tree[node] = tree[node * 2] + tree[node * 2 + 1];
            }
        } else if (opcode == 1) {
            if (first < 0 || first > (int64_t)n || second < 0 || second > 16000) return -1;
            const size_t left = (size_t)first;
            const int64_t limit = second;
            size_t boundary = n;
            if (left < n) {
                size_t position = left + size;
                int64_t accumulated = 0;
                bool done = false;
                while (!done) {
                    while ((position & 1) == 0) position /= 2;
                    if (accumulated + tree[position] > limit) {
                        while (position < size) {
                            position *= 2;
                            if (accumulated + tree[position] <= limit) {
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
            result |= (int64_t)boundary << (5 * query_index);
            ++query_index;
        } else {
            return -1;
        }
    }
    return result;
}
