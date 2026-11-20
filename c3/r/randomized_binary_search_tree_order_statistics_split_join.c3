module randomized_binary_search_tree_order_statistics_split_join;

const usz MAX_INPUT_LENGTH = 164;
const int MAX_NODES = 64;

struct RbstNode { long key; int left; int right; int size; }

fn int tree_size(RbstNode* nodes, int root) {
    return root < 0 ? 0 : nodes[root].size;
}

fn void refresh(RbstNode* nodes, int root) {
    nodes[root].size = 1 + tree_size(nodes, nodes[root].left) + tree_size(nodes, nodes[root].right);
}

fn uint randbelow(uint* state, uint bound) {
    uint threshold = (uint)(0x100000000L % (long)bound);
    while (true) {
        *state = *state * 1664525 + 1013904223;
        uint raw = *state;
        if (raw >= threshold) return raw % bound;
    }
    return 0;
}

fn int make_node(RbstNode* nodes, int* used, long key, int left, int right) {
    int node = *used;
    *used = *used + 1;
    nodes[node].key = key;
    nodes[node].left = left;
    nodes[node].right = right;
    refresh(nodes, node);
    return node;
}

fn void split_tree(RbstNode* nodes, int root, long pivot, int* low, int* high) {
    if (root < 0) {
        *low = -1;
        *high = -1;
    } else if (nodes[root].key < pivot) {
        int child_low, child_high;
        split_tree(nodes, nodes[root].right, pivot, &child_low, &child_high);
        nodes[root].right = child_low;
        refresh(nodes, root);
        *low = root;
        *high = child_high;
    } else {
        int child_low, child_high;
        split_tree(nodes, nodes[root].left, pivot, &child_low, &child_high);
        nodes[root].left = child_high;
        refresh(nodes, root);
        *low = child_low;
        *high = root;
    }
}

fn int join_trees(RbstNode* nodes, uint* random_state, int left, int right) {
    if (left < 0) return right;
    if (right < 0) return left;
    uint left_size = (uint)tree_size(nodes, left);
    uint total = left_size + (uint)tree_size(nodes, right);
    if (randbelow(random_state, total) < left_size) {
        nodes[left].right = join_trees(nodes, random_state, nodes[left].right, right);
        refresh(nodes, left);
        return left;
    }
    nodes[right].left = join_trees(nodes, random_state, left, nodes[right].left);
    refresh(nodes, right);
    return right;
}

fn bool contains(RbstNode* nodes, int root, long key) {
    while (root >= 0) {
        if (key == nodes[root].key) return true;
        root = key < nodes[root].key ? nodes[root].left : nodes[root].right;
    }
    return false;
}

fn int insert_absent(RbstNode* nodes, int* used, uint* random_state, int root, long key) {
    if (root < 0) return make_node(nodes, used, key, -1, -1);
    if (randbelow(random_state, (uint)(tree_size(nodes, root) + 1)) == 0) {
        int left, right;
        split_tree(nodes, root, key, &left, &right);
        return make_node(nodes, used, key, left, right);
    }
    if (key < nodes[root].key) nodes[root].left = insert_absent(nodes, used, random_state, nodes[root].left, key);
    else nodes[root].right = insert_absent(nodes, used, random_state, nodes[root].right, key);
    refresh(nodes, root);
    return root;
}

fn int erase_key(RbstNode* nodes, uint* random_state, int root, long key) {
    if (root < 0) return -1;
    if (key == nodes[root].key) return join_trees(nodes, random_state, nodes[root].left, nodes[root].right);
    if (key < nodes[root].key) nodes[root].left = erase_key(nodes, random_state, nodes[root].left, key);
    else nodes[root].right = erase_key(nodes, random_state, nodes[root].right, key);
    refresh(nodes, root);
    return root;
}

fn long kth(RbstNode* nodes, int root, int rank) {
    if (rank > tree_size(nodes, root)) return -1;
    while (root >= 0) {
        int left_size = tree_size(nodes, nodes[root].left);
        if (rank == left_size + 1) return nodes[root].key;
        if (rank <= left_size) root = nodes[root].left;
        else { rank -= left_size + 1; root = nodes[root].right; }
    }
    return -1;
}

fn long minimum(RbstNode* nodes, int root) {
    if (root < 0) return -1;
    while (nodes[root].left >= 0) root = nodes[root].left;
    return nodes[root].key;
}

fn long maximum(RbstNode* nodes, int root) {
    if (root < 0) return -1;
    while (nodes[root].right >= 0) root = nodes[root].right;
    return nodes[root].key;
}

fn bool valid_operation(long* input, usz offset) {
    long opcode = input[offset], a = input[offset + 1], b = input[offset + 2], c = input[offset + 3];
    if (opcode == 0 || opcode == 1) return (a == 0 || a == 1) && b >= 0 && b <= 1000 && c == 0;
    if (opcode == 2) return (a == 0 || a == 1) && b >= 1 && b <= 65 && c == 0;
    if (opcode == 3) return (a == 0 || a == 1) && (b == 0 || b == 1) && a != b && c >= 0 && c <= 1001;
    if (opcode == 4) return (a == 0 || a == 1) && (b == 0 || b == 1) && a != b && c == 0;
    return false;
}

fn long randomized_binary_search_tree_order_statistics_split_join(long* input, usz length)
        @export("randomized_binary_search_tree_order_statistics_split_join") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0], q_value = input[1], seed_value = input[2];
    if (n_value < 0 || n_value > 32 || q_value < 0 || q_value > 32 || seed_value < 0 || seed_value > 4294967295L) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != (usz)(3 + n + 4 * q)) return -1;
    for (usz i = 0; i < n; i++) {
        long key = input[3 + i];
        if (key < 0 || key > 1000 || (i > 0 && input[2 + i] >= key)) return -1;
    }
    usz operations_start = 3 + n;
    for (usz operation = 0; operation < q; operation++) {
        if (!valid_operation(input, operations_start + 4 * operation)) return -1;
    }

    RbstNode[MAX_NODES] nodes;
    int used = 0;
    uint random_state = (uint)seed_value;
    int[2] roots = {-1, -1};
    for (usz i = 0; i < n; i++) roots[0] = insert_absent(&nodes[0], &used, &random_state, roots[0], input[3 + i]);

    long checksum = 0, query_number = 0;
    for (usz operation = 0; operation < q; operation++) {
        usz offset = operations_start + 4 * operation;
        long opcode = input[offset], arg = input[offset + 2], extra = input[offset + 3];
        int tree_a = (int)input[offset + 1];
        if (opcode == 0) {
            if (!contains(&nodes[0], roots[tree_a], arg)) roots[tree_a] = insert_absent(&nodes[0], &used, &random_state, roots[tree_a], arg);
        } else if (opcode == 1) roots[tree_a] = erase_key(&nodes[0], &random_state, roots[tree_a], arg);
        else if (opcode == 2) { query_number++; checksum += query_number * (kth(&nodes[0], roots[tree_a], (int)arg) + 1); }
        else if (opcode == 3) {
            int tree_b = (int)arg;
            if (roots[tree_b] >= 0) return -1;
            split_tree(&nodes[0], roots[tree_a], extra, &roots[tree_a], &roots[tree_b]);
        } else {
            int tree_b = (int)arg;
            long left_max = maximum(&nodes[0], roots[tree_a]);
            long right_min = minimum(&nodes[0], roots[tree_b]);
            if (left_max >= 0 && right_min >= 0 && left_max >= right_min) return -1;
            roots[tree_a] = join_trees(&nodes[0], &random_state, roots[tree_a], roots[tree_b]);
            roots[tree_b] = -1;
        }
    }
    return checksum;
}
