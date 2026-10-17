#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_OPERATIONS 64
#define MAX_INPUT_LENGTH 259
#define MAX_TREE_LENGTH 128
#define VALUE_MIN (-1000000)
#define VALUE_MAX 1000000

static int32_t query_sum(const int32_t *tree, size_t node,
                         size_t segment_left, size_t segment_right,
                         size_t query_left, size_t query_right)
{
    if (query_left <= segment_left && segment_right <= query_right) return tree[node];
    if (query_right < segment_left || segment_right < query_left) return 0;
    const size_t middle = segment_left + (segment_right - segment_left) / 2;
    return query_sum(tree, node * 2, segment_left, middle, query_left, query_right)
         + query_sum(tree, node * 2 + 1, middle + 1, segment_right, query_left, query_right);
}

static uint64_t hash_i64_word(uint64_t hash, int64_t word)
{
    uint64_t bits = (uint64_t)word;
    for (size_t byte = 0; byte < 8; ++byte) {
        hash ^= bits & UINT64_C(255);
        hash *= UINT64_C(1099511628211);
        bits >>= 8;
    }
    return hash;
}

int64_t segment_tree_update_benchmark(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length < n + 2) return -1;
    if (input[n + 1] < 1 || input[n + 1] > MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)input[n + 1];
    if (length != n + 2 + 3 * operation_count) return -1;

    for (size_t index = 0; index < n; ++index) {
        if (input[index + 1] < VALUE_MIN || input[index + 1] > VALUE_MAX) return -1;
    }
    const size_t operations_start = n + 2;
    size_t query_count = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const size_t offset = operations_start + 3 * operation;
        const int64_t type = input[offset];
        const int64_t first = input[offset + 1];
        const int64_t second = input[offset + 2];
        if (type == 0) {
            if (first < 0 || first > second || second >= (int64_t)n) return -1;
            ++query_count;
        } else if (type == 1) {
            if (first < 0 || first >= (int64_t)n || second < VALUE_MIN || second > VALUE_MAX) return -1;
        } else {
            return -1;
        }
    }
    if (query_count == 0) return -1;

    size_t power = 1;
    while (power < n) power *= 2;
    int32_t tree[MAX_TREE_LENGTH] = {0};
    for (size_t index = 0; index < n; ++index) tree[power + index] = (int32_t)input[index + 1];
    for (size_t node = power - 1; node > 0; --node)
        tree[node] = tree[node * 2] + tree[node * 2 + 1];

    uint64_t hash = UINT64_C(14695981039346656037);
    hash = hash_i64_word(hash, (int64_t)query_count);
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const size_t offset = operations_start + 3 * operation;
        const int64_t type = input[offset];
        const int64_t first = input[offset + 1];
        const int64_t second = input[offset + 2];
        if (type == 0) {
            const int32_t sum = query_sum(tree, 1, 1, power,
                                          (size_t)first + 1, (size_t)second + 1);
            hash = hash_i64_word(hash, (int64_t)sum);
        } else {
            size_t node = power + (size_t)first;
            tree[node] = (int32_t)second;
            while (node > 1) {
                node /= 2;
                tree[node] = tree[node * 2] + tree[node * 2 + 1];
            }
        }
    }
    return (int64_t)(hash & UINT64_C(0x7fffffffffffffff));
}
