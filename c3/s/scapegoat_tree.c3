module scapegoat_tree;

const usz MAX_OPERATIONS = 64;
const usz MAX_LIVE_KEYS = 32;
const usz MAX_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS;
const usz MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1;
const usz MAX_OUTPUT_BYTES = 8 * (2 + MAX_OPERATIONS + MAX_LIVE_KEYS);

struct Node { long key; int left; int right; bool active; }
struct Tree { Node[MAX_LIVE_KEYS] nodes; int root; usz size; usz max_size; }

fn usz subtree_size(Tree* tree, int root) {
    if (root < 0) return 0;
    return 1 + subtree_size(tree, tree.nodes[root].left) + subtree_size(tree, tree.nodes[root].right);
}

fn usz alpha_height(Tree* tree, int root) {
    usz size = subtree_size(tree, root);
    usz height = 0;
    while (size > 1) { size >>= 1; height++; }
    return height;
}

fn void flatten(Tree* tree, int root, int* order, usz* length) {
    if (root < 0) return;
    flatten(tree, tree.nodes[root].left, order, length);
    order[length[0]++] = root;
    flatten(tree, tree.nodes[root].right, order, length);
}

fn int rebuild(Tree* tree, int* order, usz start, usz end) {
    if (start >= end) return -1;
    usz pivot = (start + end) / 2;
    int root = order[pivot];
    tree.nodes[root].left = rebuild(tree, order, start, pivot);
    tree.nodes[root].right = rebuild(tree, order, pivot + 1, end);
    return root;
}

fn bool find_key(Tree* tree, int root, long key) {
    while (root >= 0) {
        if (tree.nodes[root].key == key) return true;
        root = key < tree.nodes[root].key ? tree.nodes[root].left : tree.nodes[root].right;
    }
    return false;
}

fn int allocate_node(Tree* tree, long key) {
    for (usz index = 0; index < MAX_LIVE_KEYS; index++) {
        if (!tree.nodes[index].active) {
            tree.nodes[index].key = key;
            tree.nodes[index].left = -1;
            tree.nodes[index].right = -1;
            tree.nodes[index].active = true;
            return (int)index;
        }
    }
    return -1;
}

fn bool insert_key(Tree* tree, long key) {
    if (tree.root < 0) {
        tree.root = allocate_node(tree, key);
        if (tree.root < 0) return false;
        tree.size++;
        if (tree.size > tree.max_size) tree.max_size = tree.size;
        return true;
    }
    int[MAX_LIVE_KEYS] path = {};
    usz path_length = 0;
    int current = tree.root;
    while (true) {
        path[path_length++] = current;
        if (tree.nodes[current].key == key) return false;
        if (key < tree.nodes[current].key) {
            if (tree.nodes[current].left < 0) {
                tree.nodes[current].left = allocate_node(tree, key);
                break;
            }
            current = tree.nodes[current].left;
        } else {
            if (tree.nodes[current].right < 0) {
                tree.nodes[current].right = allocate_node(tree, key);
                break;
            }
            current = tree.nodes[current].right;
        }
    }
    tree.size++;
    if (tree.size > tree.max_size) tree.max_size = tree.size;
    if (path_length > alpha_height(tree, tree.root)) {
        usz depth = 1;
        int scapegoat = -1;
        int parent = -1;
        while (path_length > 0) {
            path_length--;
            int candidate = path[path_length];
            if (depth > alpha_height(tree, candidate)) {
                scapegoat = candidate;
                if (path_length > 0) parent = path[--path_length];
                break;
            }
            depth++;
        }
        int[MAX_LIVE_KEYS] order = {};
        usz order_length = 0;
        flatten(tree, scapegoat, &order[0], &order_length);
        int rebuilt = rebuild(tree, &order[0], 0, order_length);
        if (parent < 0) tree.root = rebuilt;
        else if (tree.nodes[parent].key < tree.nodes[rebuilt].key) tree.nodes[parent].right = rebuilt;
        else tree.nodes[parent].left = rebuilt;
    }
    return true;
}

fn bool delete_key(Tree* tree, long key) {
    int parent = -1;
    int node = tree.root;
    while (node >= 0 && tree.nodes[node].key != key) {
        parent = node;
        node = key < tree.nodes[node].key ? tree.nodes[node].left : tree.nodes[node].right;
    }
    if (node < 0) return false;
    int left = tree.nodes[node].left;
    int right = tree.nodes[node].right;
    if (left >= 0 && right >= 0) {
        int predecessor_parent = node;
        int predecessor = left;
        while (tree.nodes[predecessor].right >= 0) {
            predecessor_parent = predecessor;
            predecessor = tree.nodes[predecessor].right;
        }
        tree.nodes[node].key = tree.nodes[predecessor].key;
        int replacement = tree.nodes[predecessor].left;
        if (predecessor_parent == node) tree.nodes[node].left = replacement;
        else tree.nodes[predecessor_parent].right = replacement;
        tree.nodes[predecessor].active = false;
        tree.nodes[predecessor].left = -1;
        tree.nodes[predecessor].right = -1;
    } else {
        int replacement = left >= 0 ? left : right;
        if (parent < 0) tree.root = replacement;
        else if (tree.nodes[parent].left == node) tree.nodes[parent].left = replacement;
        else tree.nodes[parent].right = replacement;
        tree.nodes[node].active = false;
        tree.nodes[node].left = -1;
        tree.nodes[node].right = -1;
    }
    tree.size--;
    if (tree.root >= 0 && 2 * tree.size < tree.max_size) {
        int[MAX_LIVE_KEYS] order = {};
        usz order_length = 0;
        flatten(tree, tree.root, &order[0], &order_length);
        tree.root = rebuild(tree, &order[0], 0, order_length);
        tree.max_size = tree.size;
    }
    return true;
}

fn bool root_weight_balanced(Tree* tree) {
    if (tree.root < 0) return true;
    usz total = subtree_size(tree, tree.root);
    return 2 * subtree_size(tree, tree.nodes[tree.root].left) <= total &&
        2 * subtree_size(tree, tree.nodes[tree.root].right) <= total;
}

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long scapegoat_tree(long* input, usz length, char* output, usz capacity)
    @export("scapegoat_tree") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)input[0];
    if (length != 1 + 2 * operation_count) return -1;

    long[MAX_LIVE_KEYS] active_keys = {};
    usz active_count = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        usz offset = 1 + 2 * operation;
        long opcode = input[offset];
        long key = input[offset + 1];
        if (key < -2147483648l || key > 2147483647l || opcode < 0 || opcode > 6) return -1;
        if (opcode >= 3 && key != 0) return -1;
        if (opcode == 0) {
            bool present = false;
            for (usz i = 0; i < active_count; i++) if (active_keys[i] == key) present = true;
            if (!present) {
                if (active_count == MAX_LIVE_KEYS) return -1;
                active_keys[active_count++] = key;
            }
        } else if (opcode == 2) {
            for (usz i = 0; i < active_count; i++) {
                if (active_keys[i] == key) {
                    for (usz j = i; j + 1 < active_count; j++) active_keys[j] = active_keys[j + 1];
                    active_count--;
                    break;
                }
            }
        } else if (opcode == 6) active_count = 0;
    }

    Tree tree = {};
    tree.root = -1;
    for (usz index = 0; index < MAX_LIVE_KEYS; index++) {
        tree.nodes[index].left = -1;
        tree.nodes[index].right = -1;
    }
    long[MAX_OPERATIONS] results = {};
    for (usz operation = 0; operation < operation_count; operation++) {
        usz offset = 1 + 2 * operation;
        long opcode = input[offset];
        long key = input[offset + 1];
        if (opcode == 0) results[operation] = insert_key(&tree, key) ? 1 : 0;
        else if (opcode == 1) results[operation] = find_key(&tree, tree.root, key) ? 1 : 0;
        else if (opcode == 2) results[operation] = delete_key(&tree, key) ? 1 : 0;
        else if (opcode == 3) results[operation] = (long)tree.size;
        else if (opcode == 4) results[operation] = (long)tree.max_size;
        else if (opcode == 5) results[operation] = root_weight_balanced(&tree) ? 1 : 0;
        else {
            for (usz index = 0; index < MAX_LIVE_KEYS; index++) {
                tree.nodes[index].active = false;
                tree.nodes[index].left = -1;
                tree.nodes[index].right = -1;
            }
            tree.root = -1;
            tree.size = 0;
            tree.max_size = 0;
            results[operation] = -2;
        }
    }

    usz output_bytes = (2 + operation_count + tree.size) * 8;
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged = {};
    put_i64_le(&staged[0], 0, (long)operation_count);
    for (usz operation = 0; operation < operation_count; operation++)
        put_i64_le(&staged[0], (1 + operation) * 8, results[operation]);
    put_i64_le(&staged[0], (1 + operation_count) * 8, (long)tree.size);
    int[MAX_LIVE_KEYS] order = {};
    usz order_length = 0;
    flatten(&tree, tree.root, &order[0], &order_length);
    for (usz i = 0; i < order_length; i++)
        put_i64_le(&staged[0], (2 + operation_count + i) * 8, tree.nodes[order[i]].key);
    for (usz byte = 0; byte < output_bytes; byte++) output[byte] = staged[byte];
    return (long)output_bytes;
}
