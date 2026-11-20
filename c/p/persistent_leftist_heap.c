#include <stddef.h>
#include <stdint.h>

#define PLH_MAX_OPERATIONS 64
#define PLH_MAX_INPUT_LENGTH 193
#define PLH_MAX_NODES 1024
#define PLH_MAX_HEAP_SIZE 128
#define PLH_EMPTY_RANK INT64_C(20001)

typedef struct {
    int64_t key;
    int left;
    int right;
    int npl;
} PlhNode;

static int plh_allocate(PlhNode nodes[PLH_MAX_NODES], int *used,
                        int64_t key, int left, int right, int npl) {
    if (*used >= PLH_MAX_NODES) return -1;
    const int node = (*used)++;
    nodes[node] = (PlhNode){key, left, right, npl};
    return node;
}

static int plh_meld(PlhNode nodes[PLH_MAX_NODES], int *used, int left_root, int right_root) {
    if (left_root < 0 || right_root < 0) return -1;
    if (left_root == 0) return right_root;
    if (right_root == 0) return left_root;
    if (nodes[left_root].key > nodes[right_root].key) {
        const int temporary = left_root;
        left_root = right_root;
        right_root = temporary;
    }

    const PlhNode winner = nodes[left_root];
    const int copy = plh_allocate(nodes, used, winner.key, winner.left, winner.right, winner.npl);
    if (copy < 0) return -1;
    const int merged_right = plh_meld(nodes, used, winner.right, right_root);
    if (merged_right < 0) return -1;
    nodes[copy].right = merged_right;
    if (nodes[nodes[copy].left].npl < nodes[nodes[copy].right].npl) {
        const int temporary = nodes[copy].left;
        nodes[copy].left = nodes[copy].right;
        nodes[copy].right = temporary;
    }
    nodes[copy].npl = nodes[nodes[copy].right].npl + 1;
    return copy;
}

int64_t persistent_leftist_heap(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > PLH_MAX_INPUT_LENGTH) return -1;
    const int64_t raw_operations = input[0];
    if (raw_operations < 0 || raw_operations > PLH_MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)raw_operations;

    PlhNode nodes[PLH_MAX_NODES] = {{0}};
    nodes[0].npl = -1;
    int used = 1;
    int roots[PLH_MAX_OPERATIONS + 1] = {0};
    int sizes[PLH_MAX_OPERATIONS + 1] = {0};
    int64_t observation_sum = 0;
    int64_t observation_xor = 0;
    size_t cursor = 1;

    for (size_t operation_index = 0; operation_index < operation_count; ++operation_index) {
        if (cursor >= length) return -1;
        const int64_t operation = input[cursor++];
        int64_t first;
        int64_t second = 0;
        if (operation == 0 || operation == 1) {
            if (length - cursor < 2) return -1;
            first = input[cursor++];
            second = input[cursor++];
        } else if (operation == 2 || operation == 3) {
            if (length - cursor < 1) return -1;
            first = input[cursor++];
        } else {
            return -1;
        }

        int new_root = 0;
        int new_size = 0;
        if (operation == 0) {
            if (first < 0 || first > (int64_t)operation_index || second < -10000 || second > 10000)
                return -1;
            const int base = (int)first;
            if (sizes[base] >= PLH_MAX_HEAP_SIZE) return -1;
            const int singleton = plh_allocate(nodes, &used, second, 0, 0, 0);
            if (singleton < 0) return -1;
            new_root = plh_meld(nodes, &used, roots[base], singleton);
            if (new_root < 0) return -1;
            new_size = sizes[base] + 1;
        } else if (operation == 1) {
            if (first < 0 || first > (int64_t)operation_index ||
                second < 0 || second > (int64_t)operation_index)
                return -1;
            const int left_version = (int)first;
            const int right_version = (int)second;
            new_size = sizes[left_version] + sizes[right_version];
            if (new_size > PLH_MAX_HEAP_SIZE) return -1;
            new_root = plh_meld(nodes, &used, roots[left_version], roots[right_version]);
            if (new_root < 0) return -1;
        } else {
            if (first < 0 || first > (int64_t)operation_index) return -1;
            const int version = (int)first;
            const int root = roots[version];
            const int64_t rank = root == 0 ? PLH_EMPTY_RANK : nodes[root].key + 10000;
            observation_sum += rank;
            observation_xor ^= rank;
            if (operation == 3) {
                new_root = root;
                new_size = sizes[version];
            } else if (root != 0) {
                new_root = plh_meld(nodes, &used, nodes[root].left, nodes[root].right);
                if (new_root < 0) return -1;
                new_size = sizes[version] - 1;
            }
        }

        if (new_size > PLH_MAX_HEAP_SIZE) return -1;
        roots[operation_index + 1] = new_root;
        sizes[operation_index + 1] = new_size;
    }
    if (cursor != length) return -1;
    return (observation_sum << 15) | observation_xor;
}
