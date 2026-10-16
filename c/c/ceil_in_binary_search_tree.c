#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 127
#define MAX_INPUT_LENGTH (3 + 3 * MAX_NODE_COUNT)
#define VALUE_MIN (-1000000)
#define VALUE_MAX 1000000
#define INVALID_RESULT (INT64_MIN + 1)
#define NO_CEIL_RESULT INT64_MIN

int64_t ceil_in_binary_search_tree(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) {
        return INVALID_RESULT;
    }
    const int64_t node_count_value = input[0];
    const int64_t root_index_value = input[1];
    const int64_t key = input[2];
    if (node_count_value < 0 || node_count_value > MAX_NODE_COUNT ||
        key < VALUE_MIN || key > VALUE_MAX) {
        return INVALID_RESULT;
    }
    const size_t node_count = (size_t)node_count_value;
    if (length != 3 + 3 * node_count) {
        return INVALID_RESULT;
    }
    if (node_count == 0) {
        return root_index_value == -1 ? NO_CEIL_RESULT : INVALID_RESULT;
    }
    if (root_index_value < 0 || (uint64_t)root_index_value >= node_count) {
        return INVALID_RESULT;
    }

    size_t current = (size_t)root_index_value;
    int64_t best = NO_CEIL_RESULT;
    for (size_t steps = 0; current != SIZE_MAX; ++steps) {
        if (steps >= node_count) {
            return INVALID_RESULT;
        }
        const size_t offset = 3 + 3 * current;
        const int64_t value = input[offset];
        const int64_t left = input[offset + 1];
        const int64_t right = input[offset + 2];
        if (value < VALUE_MIN || value > VALUE_MAX || left < -1 || right < -1 ||
            left >= node_count_value || right >= node_count_value) {
            return INVALID_RESULT;
        }
        if (value == key) {
            return value;
        }
        if (value < key) {
            current = right == -1 ? SIZE_MAX : (size_t)right;
        } else {
            best = value;
            current = left == -1 ? SIZE_MAX : (size_t)left;
        }
    }
    return best;
}
