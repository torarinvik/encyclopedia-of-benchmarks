#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 256, MAX_MERGES = 512, MAX_PARSEABLE_INPUT_LENGTH = 1028 };

int64_t merge_find_set(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_MERGES) return -1;
    const size_t n = (size_t)input[0];
    const size_t merge_count = (size_t)input[1];
    if (length != 2 * merge_count + 3) return -1;

    int64_t parent[MAX_N], rank[MAX_N] = {0};
    for (size_t element = 0; element < n; ++element) parent[element] = (int64_t)element;
    for (size_t operation = 0; operation < merge_count; ++operation) {
        const size_t position = 2 + 2 * operation;
        const int64_t first = input[position], second = input[position + 1];
        if (first < 0 || second < 0 || first >= (int64_t)n || second >= (int64_t)n) return -1;
        int64_t first_root = first, second_root = second;
        while (parent[(size_t)first_root] != first_root) first_root = parent[(size_t)first_root];
        while (parent[(size_t)second_root] != second_root) second_root = parent[(size_t)second_root];
        if (first_root == second_root) continue;
        if (rank[(size_t)first_root] < rank[(size_t)second_root]) {
            parent[(size_t)first_root] = second_root;
        } else if (rank[(size_t)first_root] > rank[(size_t)second_root]) {
            parent[(size_t)second_root] = first_root;
        } else {
            parent[(size_t)first_root] = second_root;
            ++rank[(size_t)second_root];
        }
    }

    int64_t query = input[length - 1];
    if (query < 0 || query >= (int64_t)n) return -1;
    while (parent[(size_t)query] != query) query = parent[(size_t)query];
    return query;
}
