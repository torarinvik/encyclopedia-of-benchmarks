#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

int64_t schorr_waite_graph_marking(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > 66) return -1;

    const int64_t node_count_value = input[0];
    const int64_t root = input[1];
    if (node_count_value < 1 || node_count_value > 32) return -1;
    const size_t node_count = (size_t)node_count_value;
    if (length != 2 + 2 * node_count || root < 0 || root >= node_count_value) {
        return -1;
    }

    int64_t left[32];
    int64_t right[32];
    bool marked[32] = {false};
    bool phase[32] = {false};
    for (size_t node = 0; node < node_count; ++node) {
        const int64_t left_child = input[2 + 2 * node];
        const int64_t right_child = input[3 + 2 * node];
        if (left_child < -1 || left_child >= node_count_value
            || right_child < -1 || right_child >= node_count_value) {
            return -1;
        }
        left[node] = left_child;
        right[node] = right_child;
    }

    int64_t parent = -1;
    int64_t current = root;
    int64_t temporary;
    while (parent != -1 || (current != -1 && !marked[(size_t)current])) {
        if (current == -1 || marked[(size_t)current]) {
            const size_t frame = (size_t)parent;
            if (phase[frame]) {
                temporary = current;
                current = parent;
                parent = right[frame];
                right[frame] = temporary;
            } else {
                temporary = current;
                current = right[frame];
                right[frame] = left[frame];
                left[frame] = temporary;
                phase[frame] = true;
            }
        } else {
            temporary = parent;
            parent = current;
            current = left[(size_t)parent];
            left[(size_t)parent] = temporary;
            marked[(size_t)parent] = true;
            phase[(size_t)parent] = false;
        }
    }

    int64_t reachable = 0;
    for (size_t node = 0; node < node_count; ++node) {
        if (marked[node]) reachable |= INT64_C(1) << node;
    }
    return reachable;
}
