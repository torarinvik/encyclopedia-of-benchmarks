#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 164
#define MAX_NODES 64

typedef struct {
    int64_t key;
    int left;
    int right;
    int size;
} Node;

typedef struct {
    Node nodes[MAX_NODES];
    int used;
    uint32_t random_state;
} State;

static int node_size(const State *state, int root) {
    return root < 0 ? 0 : state->nodes[root].size;
}

static void refresh(State *state, int root) {
    state->nodes[root].size = 1 + node_size(state, state->nodes[root].left) +
                              node_size(state, state->nodes[root].right);
}

static uint32_t randbelow(State *state, uint32_t bound) {
    const uint64_t threshold = UINT64_C(0x100000000) % bound;
    for (;;) {
        state->random_state = state->random_state * UINT32_C(1664525) + UINT32_C(1013904223);
        const uint32_t raw = state->random_state;
        if ((uint64_t)raw >= threshold) return raw % bound;
    }
}

static int make_node(State *state, int64_t key, int left, int right) {
    const int node = state->used++;
    state->nodes[node].key = key;
    state->nodes[node].left = left;
    state->nodes[node].right = right;
    refresh(state, node);
    return node;
}

static void split_tree(State *state, int root, int64_t pivot, int *low, int *high) {
    if (root < 0) {
        *low = -1;
        *high = -1;
    } else if (state->nodes[root].key < pivot) {
        int right_low;
        int right_high;
        split_tree(state, state->nodes[root].right, pivot, &right_low, &right_high);
        state->nodes[root].right = right_low;
        refresh(state, root);
        *low = root;
        *high = right_high;
    } else {
        int left_low;
        int left_high;
        split_tree(state, state->nodes[root].left, pivot, &left_low, &left_high);
        state->nodes[root].left = left_high;
        refresh(state, root);
        *low = left_low;
        *high = root;
    }
}

static int join_trees(State *state, int left, int right) {
    if (left < 0) return right;
    if (right < 0) return left;
    const uint32_t left_size = (uint32_t)node_size(state, left);
    const uint32_t total = left_size + (uint32_t)node_size(state, right);
    if (randbelow(state, total) < left_size) {
        state->nodes[left].right = join_trees(state, state->nodes[left].right, right);
        refresh(state, left);
        return left;
    }
    state->nodes[right].left = join_trees(state, left, state->nodes[right].left);
    refresh(state, right);
    return right;
}

static int contains(const State *state, int root, int64_t key) {
    while (root >= 0) {
        if (key == state->nodes[root].key) return 1;
        root = key < state->nodes[root].key ? state->nodes[root].left : state->nodes[root].right;
    }
    return 0;
}

static int insert_absent(State *state, int root, int64_t key) {
    if (root < 0) return make_node(state, key, -1, -1);
    if (randbelow(state, (uint32_t)(node_size(state, root) + 1)) == 0) {
        int left;
        int right;
        split_tree(state, root, key, &left, &right);
        return make_node(state, key, left, right);
    }
    if (key < state->nodes[root].key) {
        state->nodes[root].left = insert_absent(state, state->nodes[root].left, key);
    } else {
        state->nodes[root].right = insert_absent(state, state->nodes[root].right, key);
    }
    refresh(state, root);
    return root;
}

static int erase_key(State *state, int root, int64_t key) {
    if (root < 0) return -1;
    if (key == state->nodes[root].key) {
        return join_trees(state, state->nodes[root].left, state->nodes[root].right);
    }
    if (key < state->nodes[root].key) {
        state->nodes[root].left = erase_key(state, state->nodes[root].left, key);
    } else {
        state->nodes[root].right = erase_key(state, state->nodes[root].right, key);
    }
    refresh(state, root);
    return root;
}

static int64_t kth(const State *state, int root, int rank) {
    if (rank > node_size(state, root)) return -1;
    while (root >= 0) {
        const int left_size = node_size(state, state->nodes[root].left);
        if (rank == left_size + 1) return state->nodes[root].key;
        if (rank <= left_size) root = state->nodes[root].left;
        else {
            rank -= left_size + 1;
            root = state->nodes[root].right;
        }
    }
    return -1;
}

static int64_t minimum(const State *state, int root) {
    if (root < 0) return -1;
    while (state->nodes[root].left >= 0) root = state->nodes[root].left;
    return state->nodes[root].key;
}

static int64_t maximum(const State *state, int root) {
    if (root < 0) return -1;
    while (state->nodes[root].right >= 0) root = state->nodes[root].right;
    return state->nodes[root].key;
}

static int valid_operation(const int64_t *input, size_t offset) {
    const int64_t opcode = input[offset];
    const int64_t a = input[offset + 1];
    const int64_t b = input[offset + 2];
    const int64_t c = input[offset + 3];
    if (opcode == 0 || opcode == 1) return (a == 0 || a == 1) && b >= 0 && b <= 1000 && c == 0;
    if (opcode == 2) return (a == 0 || a == 1) && b >= 1 && b <= 65 && c == 0;
    if (opcode == 3) return (a == 0 || a == 1) && (b == 0 || b == 1) && a != b && c >= 0 && c <= 1001;
    if (opcode == 4) return (a == 0 || a == 1) && (b == 0 || b == 1) && a != b && c == 0;
    return 0;
}

int64_t randomized_binary_search_tree_order_statistics_split_join(const int64_t *input,
                                                                    size_t length) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    const int64_t q_value = input[1];
    const int64_t seed_value = input[2];
    if (n_value < 0 || n_value > 32 || q_value < 0 || q_value > 32 ||
        seed_value < 0 || seed_value > INT64_C(4294967295)) return -1;
    const size_t n = (size_t)n_value;
    const size_t q = (size_t)q_value;
    if (length != 3 + n + 4 * q) return -1;
    for (size_t i = 0; i < n; ++i) {
        const int64_t key = input[3 + i];
        if (key < 0 || key > 1000 || (i > 0 && input[2 + i] >= key)) return -1;
    }
    const size_t operations_start = 3 + n;
    for (size_t operation = 0; operation < q; ++operation) {
        if (!valid_operation(input, operations_start + 4 * operation)) return -1;
    }

    State state = {0};
    state.random_state = (uint32_t)seed_value;
    int roots[2] = {-1, -1};
    for (size_t i = 0; i < n; ++i) roots[0] = insert_absent(&state, roots[0], input[3 + i]);

    int64_t checksum = 0;
    int64_t query_number = 0;
    for (size_t operation = 0; operation < q; ++operation) {
        const size_t offset = operations_start + 4 * operation;
        const int64_t opcode = input[offset];
        const int tree_a = (int)input[offset + 1];
        const int64_t argument = input[offset + 2];
        const int64_t extra = input[offset + 3];
        if (opcode == 0) {
            if (!contains(&state, roots[tree_a], argument)) roots[tree_a] = insert_absent(&state, roots[tree_a], argument);
        } else if (opcode == 1) {
            roots[tree_a] = erase_key(&state, roots[tree_a], argument);
        } else if (opcode == 2) {
            ++query_number;
            checksum += query_number * (kth(&state, roots[tree_a], (int)argument) + 1);
        } else if (opcode == 3) {
            const int tree_b = (int)argument;
            if (roots[tree_b] >= 0) return -1;
            split_tree(&state, roots[tree_a], extra, &roots[tree_a], &roots[tree_b]);
        } else {
            const int tree_b = (int)argument;
            const int64_t left_max = maximum(&state, roots[tree_a]);
            const int64_t right_min = minimum(&state, roots[tree_b]);
            if (left_max >= 0 && right_min >= 0 && left_max >= right_min) return -1;
            roots[tree_a] = join_trees(&state, roots[tree_a], roots[tree_b]);
            roots[tree_b] = -1;
        }
    }
    return checksum;
}
