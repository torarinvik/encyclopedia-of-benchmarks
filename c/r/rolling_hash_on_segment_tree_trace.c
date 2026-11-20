#include <stddef.h>
#include <stdint.h>

enum {
    MAX_N = 20,
    MAX_Q = 20,
    MAX_PARSEABLE_INPUT = 123,
    TREE_CAPACITY = 64,
    HASH_MOD = 1000000007,
    HASH_BASE = 911382323
};

typedef struct {
    int64_t hash;
    int length;
} Node;

static int64_t concatenate_hash(int64_t left_hash, int64_t right_hash,
                                int right_length,
                                const int64_t powers[MAX_N + 1]) {
    return (left_hash * powers[right_length] + right_hash) % HASH_MOD;
}

static void pull(Node tree[TREE_CAPACITY], int node,
                 const int64_t powers[MAX_N + 1]) {
    const Node left = tree[2 * node];
    const Node right = tree[2 * node + 1];
    tree[node].hash = concatenate_hash(left.hash, right.hash, right.length, powers);
    tree[node].length = left.length + right.length;
}

static int64_t range_hash(const Node tree[TREE_CAPACITY], int tree_size,
                          int left, int right,
                          const int64_t powers[MAX_N + 1]) {
    int64_t left_hash = 0, right_hash = 0;
    int right_length = 0;
    left += tree_size;
    right += tree_size;
    while (left < right) {
        if ((left & 1) != 0) {
            const Node part = tree[left++];
            left_hash = concatenate_hash(left_hash, part.hash, part.length, powers);
        }
        if ((right & 1) != 0) {
            const Node part = tree[--right];
            right_hash = concatenate_hash(part.hash, right_hash, right_length, powers);
            right_length += part.length;
        }
        left /= 2;
        right /= 2;
    }
    return concatenate_hash(left_hash, right_hash, right_length, powers);
}

int64_t rolling_hash_on_segment_tree_trace(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT) return -1;
    if (input[0] < 0 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_Q) return -1;
    const int n = (int)input[0], q = (int)input[1];
    if (length != 2 + (size_t)n + 5 * (size_t)q) return -1;

    int64_t powers[MAX_N + 1];
    powers[0] = 1;
    for (int i = 1; i <= MAX_N; ++i) powers[i] = (powers[i - 1] * HASH_BASE) % HASH_MOD;

    int tree_size = 1;
    while (tree_size < n) tree_size *= 2;
    Node tree[TREE_CAPACITY] = {0};
    for (int i = 0; i < n; ++i) {
        const int64_t symbol = input[2 + (size_t)i];
        if (symbol < 0 || symbol > 25) return -1;
        tree[tree_size + i].hash = symbol;
        tree[tree_size + i].length = 1;
    }
    for (int node = tree_size - 1; node > 0; --node) pull(tree, node, powers);

    int64_t checksum = 0;
    for (int operation = 0; operation < q; ++operation) {
        const size_t at = 2 + (size_t)n + 5 * (size_t)operation;
        const int64_t opcode = input[at];
        const int64_t a = input[at + 1], b = input[at + 2];
        const int64_t c = input[at + 3], d = input[at + 4];
        int response = 0;

        if (opcode == 0) {
            if (a < 0 || a >= n || b < 0 || b > 25 || c != 0 || d != 0) return -1;
            int node = tree_size + (int)a;
            tree[node].hash = b;
            tree[node].length = 1;
            while (node > 1) {
                node /= 2;
                pull(tree, node, powers);
            }
        } else if (opcode == 1) {
            if (a < 0 || a > b || b > n || c < 0 || c > d || d > n) return -1;
            if (b - a == d - c)
                response = range_hash(tree, tree_size, (int)a, (int)b, powers) ==
                           range_hash(tree, tree_size, (int)c, (int)d, powers);
        } else {
            return -1;
        }
        checksum += (int64_t)(operation + 1) * (opcode * 2 + response + 1);
    }
    return checksum;
}
