#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_Q 32
#define MAX_INPUT_LENGTH 131
#define MAX_NODES 193
#define INVALID_RESULT INT64_MIN

static int lower_bound_i64(const int64_t *values, int length, int64_t target) {
    int low = 0;
    int high = length;
    while (low < high) {
        const int middle = low + (high - low) / 2;
        if (values[middle] < target) low = middle + 1;
        else high = middle;
    }
    return low;
}

int64_t persistent_segment_tree_range_kth(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_Q) return INVALID_RESULT;
    const int n = (int)input[0];
    const int q = (int)input[1];
    if (length != (size_t)(2 + n + 3 * q)) return INVALID_RESULT;

    int64_t coordinates[MAX_N] = {0};
    for (int i = 0; i < n; ++i) {
        const int64_t value = input[2 + i];
        if (value < -1000 || value > 1000) return INVALID_RESULT;
        coordinates[i] = value;
    }
    for (int i = 1; i < n; ++i) {
        const int64_t value = coordinates[i];
        int j = i;
        while (j > 0 && coordinates[j - 1] > value) {
            coordinates[j] = coordinates[j - 1];
            --j;
        }
        coordinates[j] = value;
    }
    int distinct = 0;
    for (int i = 0; i < n; ++i) {
        if (distinct == 0 || coordinates[i] != coordinates[distinct - 1]) {
            coordinates[distinct++] = coordinates[i];
        }
    }
    const size_t query_offset = (size_t)(2 + n);
    for (int qi = 0; qi < q; ++qi) {
        const int64_t left = input[query_offset + (size_t)(3 * qi)];
        const int64_t right = input[query_offset + (size_t)(3 * qi + 1)];
        const int64_t k = input[query_offset + (size_t)(3 * qi + 2)];
        if (left < 0 || right < left || right >= n || k < 1 || k > right - left + 1) return INVALID_RESULT;
    }

    int32_t left_child[MAX_NODES] = {0};
    int32_t right_child[MAX_NODES] = {0};
    int32_t counts[MAX_NODES] = {0};
    int32_t roots[MAX_N + 1] = {0};
    int32_t node_count = 1;
    for (int i = 0; i < n; ++i) {
        const int rank = lower_bound_i64(coordinates, distinct, input[2 + i]);
        const int32_t previous_root = roots[i];
        if (node_count >= MAX_NODES) return INVALID_RESULT;
        const int32_t new_root = node_count++;
        left_child[new_root] = left_child[previous_root];
        right_child[new_root] = right_child[previous_root];
        counts[new_root] = counts[previous_root] + 1;
        int32_t old_node = previous_root;
        int32_t new_node = new_root;
        int low = 0;
        int high = distinct;
        while (high - low > 1) {
            const int middle = low + (high - low) / 2;
            const int32_t old_child = rank < middle ? left_child[old_node] : right_child[old_node];
            if (node_count >= MAX_NODES) return INVALID_RESULT;
            const int32_t new_child = node_count++;
            left_child[new_child] = left_child[old_child];
            right_child[new_child] = right_child[old_child];
            counts[new_child] = counts[old_child] + 1;
            if (rank < middle) {
                left_child[new_node] = new_child;
                high = middle;
            } else {
                right_child[new_node] = new_child;
                low = middle;
            }
            old_node = old_child;
            new_node = new_child;
        }
        roots[i + 1] = new_root;
    }

    int64_t checksum = 0;
    for (int qi = 0; qi < q; ++qi) {
        const size_t offset = query_offset + (size_t)(3 * qi);
        const int left = (int)input[offset];
        const int right = (int)input[offset + 1];
        int k = (int)input[offset + 2];
        int32_t before = roots[left];
        int32_t after = roots[right + 1];
        int low = 0;
        int high = distinct;
        while (high - low > 1) {
            const int middle = low + (high - low) / 2;
            const int32_t in_left = left_child[after];
            const int32_t out_left = left_child[before];
            const int left_count = counts[in_left] - counts[out_left];
            if (k <= left_count) {
                before = out_left;
                after = in_left;
                high = middle;
            } else {
                k -= left_count;
                before = right_child[before];
                after = right_child[after];
                low = middle;
            }
        }
        checksum += (int64_t)(qi + 1) * coordinates[low];
    }
    return checksum;
}
