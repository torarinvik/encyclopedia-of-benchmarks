/* Bounded unbalanced binary search tree with an index-based node pool. */
#include <stddef.h>
#include <stdint.h>

#define CAPACITY 256
#define NONE ((size_t)CAPACITY)
#define OFFSET INT64_C(1000000)

int64_t binary_search_tree_benchmark(const int64_t *values, size_t length)
{
    if (length > 1024 || length % 2 != 0) return -1;
    const size_t operation_count = length / 2;
    int64_t key[CAPACITY];
    size_t left[CAPACITY], right[CAPACITY], free_next[CAPACITY];
    for (size_t i = 0; i < CAPACITY; ++i) free_next[i] = i + 1;
    size_t free_head = 0, root = NONE, count = 0;
    int64_t checksum = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        const int64_t opcode = values[2 * operation], payload = values[2 * operation + 1];
        int64_t observed = 0;
        if (opcode == 0) {
            if (payload < -OFFSET || payload > OFFSET) return -1;
            size_t parent = NONE, node = root;
            while (node != NONE && key[node] != payload) {
                parent = node;
                node = payload < key[node] ? left[node] : right[node];
            }
            if (node == NONE) {
                if (count == CAPACITY || free_head == NONE) return -1;
                node = free_head; free_head = free_next[node];
                key[node] = payload; left[node] = right[node] = NONE;
                if (parent == NONE) root = node;
                else if (payload < key[parent]) left[parent] = node;
                else right[parent] = node;
                ++count; observed = 1;
            }
        } else if (opcode == 1) {
            if (payload < -OFFSET || payload > OFFSET) return -1;
            size_t parent = NONE, node = root;
            while (node != NONE && key[node] != payload) {
                parent = node;
                node = payload < key[node] ? left[node] : right[node];
            }
            observed = (node != NONE);
            if (node != NONE) {
                if (left[node] != NONE && right[node] != NONE) {
                    size_t pred_parent = node, pred = left[node];
                    while (right[pred] != NONE) { pred_parent = pred; pred = right[pred]; }
                    key[node] = key[pred]; parent = pred_parent; node = pred;
                }
                const size_t child = left[node] != NONE ? left[node] : right[node];
                if (parent == NONE) root = child;
                else if (left[parent] == node) left[parent] = child;
                else right[parent] = child;
                free_next[node] = free_head; free_head = node; --count;
            }
        } else if (opcode == 2) {
            if (payload < -OFFSET || payload > OFFSET) return -1;
            size_t node = root;
            while (node != NONE && key[node] != payload) node = payload < key[node] ? left[node] : right[node];
            observed = (node != NONE);
        } else if (opcode == 3 || opcode == 4) {
            if (payload != 0 || root == NONE) return -1;
            size_t node = root;
            const size_t *branch = opcode == 3 ? left : right;
            while (branch[node] != NONE) node = branch[node];
            observed = key[node];
        } else if (opcode == 5) {
            if (payload != 0) return -1;
            observed = (int64_t)count;
        } else return -1;
        checksum += ((int64_t)operation + 1) * (observed + OFFSET);
    }
    size_t stack[CAPACITY], top = 0, node = root, index = 0;
    while (node != NONE || top != 0) {
        while (node != NONE) { stack[top++] = node; node = left[node]; }
        node = stack[--top];
        checksum += ((int64_t)operation_count + (int64_t)index + 1) * (key[node] + OFFSET);
        ++index; node = right[node];
    }
    return checksum;
}
