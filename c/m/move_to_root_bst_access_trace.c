#include <stddef.h>
#include <stdint.h>

#define MOVE_TO_ROOT_MAX_INITIAL 16
#define MOVE_TO_ROOT_MAX_ACCESSES 32

int64_t move_to_root_bst_access_trace(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > 51) return -1;
    const int64_t initial_count = values[0];
    if (initial_count < 0 || initial_count > MOVE_TO_ROOT_MAX_INITIAL) return -1;
    const size_t query_count_index = 1 + (size_t)initial_count;
    if (length < query_count_index + 1) return -1;
    const int64_t access_count = values[query_count_index];
    if (access_count < 0 || access_count > MOVE_TO_ROOT_MAX_ACCESSES
        || length != query_count_index + 1 + (size_t)access_count) return -1;

    int64_t keys[MOVE_TO_ROOT_MAX_INITIAL];
    int32_t left[MOVE_TO_ROOT_MAX_INITIAL];
    int32_t right[MOVE_TO_ROOT_MAX_INITIAL];
    int32_t parent[MOVE_TO_ROOT_MAX_INITIAL];
    for (size_t index = 0; index < MOVE_TO_ROOT_MAX_INITIAL; ++index) {
        left[index] = -1;
        right[index] = -1;
        parent[index] = -1;
    }
    for (size_t index = 0; index < (size_t)initial_count; ++index) {
        const int64_t key = values[1 + index];
        if (key < -100 || key > 100) return -1;
        for (size_t earlier = 0; earlier < index; ++earlier) {
            if (values[1 + earlier] == key) return -1;
        }
        keys[index] = key;
    }
    for (size_t query = 0; query < (size_t)access_count; ++query) {
        const int64_t key = values[query_count_index + 1 + query];
        if (key < -100 || key > 100) return -1;
    }

    int32_t root = -1;
    for (int32_t node = 0; node < (int32_t)initial_count; ++node) {
        if (root == -1) {
            root = node;
            continue;
        }
        int32_t current = root;
        for (;;) {
            if (keys[node] < keys[current]) {
                if (left[current] == -1) {
                    left[current] = node;
                    parent[node] = current;
                    break;
                }
                current = left[current];
            } else {
                if (right[current] == -1) {
                    right[current] = node;
                    parent[node] = current;
                    break;
                }
                current = right[current];
            }
        }
    }

    int64_t result = 0;
    for (size_t query_number = 1; query_number <= (size_t)access_count; ++query_number) {
        const int64_t key = values[query_count_index + query_number];
        int32_t node = root;
        int64_t comparisons = 0;
        while (node != -1) {
            ++comparisons;
            if (key == keys[node]) break;
            node = key < keys[node] ? left[node] : right[node];
        }
        while (node != -1 && parent[node] != -1) {
            const int32_t old_parent = parent[node];
            const int32_t grandparent = parent[old_parent];
            if (left[old_parent] == node) {
                const int32_t middle = right[node];
                right[node] = old_parent;
                left[old_parent] = middle;
                if (middle != -1) parent[middle] = old_parent;
            } else {
                const int32_t middle = left[node];
                left[node] = old_parent;
                right[old_parent] = middle;
                if (middle != -1) parent[middle] = old_parent;
            }
            parent[old_parent] = node;
            parent[node] = grandparent;
            if (grandparent == -1) root = node;
            else if (left[grandparent] == old_parent) left[grandparent] = node;
            else right[grandparent] = node;
        }
        result += (int64_t)query_number * comparisons;
    }
    return result;
}
