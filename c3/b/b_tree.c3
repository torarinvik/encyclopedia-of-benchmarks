module b_tree;

const usz MAX_NODE_COUNT = 257;
const usz MAX_NODE_KEYS = 15;
const usz MAX_NODE_CHILDREN = 16;
const usz MAX_KEY_COUNT = 256;
const usz MAX_OPERATIONS = 511;
const long OFFSET = 1000000;
const long HASH_MOD = 1000000007;

fn bool split_child(long* keys, usz* children, usz* key_count, bool* leaf,
    usz* used_nodes, usz min_degree, usz parent, usz child_index) {
    if (*used_nodes >= MAX_NODE_COUNT) return false;
    usz child = children[parent * MAX_NODE_CHILDREN + child_index];
    usz sibling = *used_nodes;
    (*used_nodes)++;
    leaf[sibling] = leaf[child];
    key_count[sibling] = min_degree - 1;
    for (usz i = 0; i < min_degree - 1; i++)
        keys[sibling * MAX_NODE_KEYS + i] = keys[child * MAX_NODE_KEYS + min_degree + i];
    if (!leaf[child])
        for (usz i = 0; i < min_degree; i++)
            children[sibling * MAX_NODE_CHILDREN + i] = children[child * MAX_NODE_CHILDREN + min_degree + i];
    usz parent_count = key_count[parent];
    for (usz i = parent_count + 1; i > child_index + 1; i--)
        children[parent * MAX_NODE_CHILDREN + i] = children[parent * MAX_NODE_CHILDREN + i - 1];
    children[parent * MAX_NODE_CHILDREN + child_index + 1] = sibling;
    for (usz i = parent_count; i > child_index; i--)
        keys[parent * MAX_NODE_KEYS + i] = keys[parent * MAX_NODE_KEYS + i - 1];
    keys[parent * MAX_NODE_KEYS + child_index] = keys[child * MAX_NODE_KEYS + min_degree - 1];
    key_count[child] = min_degree - 1;
    key_count[parent] = parent_count + 1;
    return true;
}

fn bool insert_non_full(long* keys, usz* children, usz* key_count, bool* leaf,
    usz* used_nodes, usz min_degree, usz node, long key) {
    usz index = key_count[node];
    if (leaf[node]) {
        while (index > 0 && key <= keys[node * MAX_NODE_KEYS + index - 1]) {
            keys[node * MAX_NODE_KEYS + index] = keys[node * MAX_NODE_KEYS + index - 1];
            index--;
        }
        keys[node * MAX_NODE_KEYS + index] = key;
        key_count[node]++;
        return true;
    }
    while (index > 0 && key <= keys[node * MAX_NODE_KEYS + index - 1]) index--;
    usz child = children[node * MAX_NODE_CHILDREN + index];
    if (key_count[child] == 2 * min_degree - 1) {
        if (!split_child(keys, children, key_count, leaf, used_nodes, min_degree, node, index)) return false;
        if (keys[node * MAX_NODE_KEYS + index] < key) index++;
    }
    return insert_non_full(keys, children, key_count, leaf, used_nodes, min_degree,
        children[node * MAX_NODE_CHILDREN + index], key);
}

fn bool insert_key(long* keys, usz* children, usz* key_count, bool* leaf,
    usz* used_nodes, usz* root, usz min_degree, long key) {
    if (key_count[*root] == 2 * min_degree - 1) {
        if (*used_nodes + 2 > MAX_NODE_COUNT) return false;
        usz old_root = *root;
        usz new_root = *used_nodes;
        (*used_nodes)++;
        leaf[new_root] = false;
        key_count[new_root] = 0;
        children[new_root * MAX_NODE_CHILDREN] = old_root;
        *root = new_root;
        if (!split_child(keys, children, key_count, leaf, used_nodes, min_degree, new_root, 0)) return false;
    }
    return insert_non_full(keys, children, key_count, leaf, used_nodes, min_degree, *root, key);
}

fn bool search_key(long* keys, usz* children, usz* key_count, bool* leaf, usz root, long key) {
    usz node = root;
    while (true) {
        usz index = 0;
        while (index < key_count[node] && key > keys[node * MAX_NODE_KEYS + index]) index++;
        if (index < key_count[node] && key == keys[node * MAX_NODE_KEYS + index]) return true;
        if (leaf[node]) return false;
        node = children[node * MAX_NODE_CHILDREN + index];
    }
}

fn long walk_in_order(long* keys, usz* children, usz* key_count, bool* leaf,
    usz root, usz operation_count, long* ordered_sum) {
    usz[32] node_stack, position_stack;
    usz depth = 1, index = 0;
    long hash = 0;
    node_stack[0] = root;
    position_stack[0] = 0;
    while (depth > 0) {
        usz top = depth - 1;
        usz node = node_stack[top];
        usz count = key_count[node];
        if (leaf[node]) {
            if (position_stack[top] == count) { depth--; continue; }
            long value = keys[node * MAX_NODE_KEYS + position_stack[top]];
            position_stack[top]++;
            hash = (hash * 257 + value + 1000001) % HASH_MOD;
            if (ordered_sum != null) (*ordered_sum) += (long)(operation_count + index + 1) * (value + OFFSET);
            index++;
        } else if (position_stack[top] > 2 * count) {
            depth--;
        } else {
            usz position = position_stack[top];
            position_stack[top]++;
            if (position % 2 == 0) {
                node_stack[depth] = children[node * MAX_NODE_CHILDREN + position / 2];
                position_stack[depth] = 0;
                depth++;
            } else {
                long value = keys[node * MAX_NODE_KEYS + position / 2];
                hash = (hash * 257 + value + 1000001) % HASH_MOD;
                if (ordered_sum != null) (*ordered_sum) += (long)(operation_count + index + 1) * (value + OFFSET);
                index++;
            }
        }
    }
    return hash;
}

fn long b_tree_benchmark(long* input, usz length) @export("b_tree_benchmark") {
    if (input == null || length < 2 || length > 1024 || input[0] < 2 || input[0] > 8 ||
        input[1] < 0 || input[1] > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)input[1];
    if (length != 2 + 2 * operation_count) return -1;
    long[MAX_NODE_COUNT * MAX_NODE_KEYS] keys;
    usz[MAX_NODE_COUNT * MAX_NODE_CHILDREN] children;
    usz[MAX_NODE_COUNT] key_count;
    bool[MAX_NODE_COUNT] leaf;
    usz used_nodes = 1, root = 0, min_degree = (usz)input[0];
    key_count[0] = 0;
    leaf[0] = true;
    usz inserted_count = 0;
    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        long opcode = input[2 + 2 * operation];
        long payload = input[3 + 2 * operation];
        long observed = 0;
        if (opcode == 0) {
            if (payload < -OFFSET || payload > OFFSET || inserted_count == MAX_KEY_COUNT ||
                !insert_key(&keys[0], &children[0], &key_count[0], &leaf[0], &used_nodes, &root, min_degree, payload)) return -1;
            inserted_count++;
            observed = 1;
        } else if (opcode == 1) {
            if (payload < -OFFSET || payload > OFFSET) return -1;
            observed = (long)search_key(&keys[0], &children[0], &key_count[0], &leaf[0], root, payload);
        } else if (opcode == 2) {
            if (payload != 0) return -1;
            observed = walk_in_order(&keys[0], &children[0], &key_count[0], &leaf[0], root, 0, null);
        } else return -1;
        checksum += (long)(operation + 1) * (observed + OFFSET);
    }
    walk_in_order(&keys[0], &children[0], &key_count[0], &leaf[0], root, operation_count, &checksum);
    return checksum;
}
