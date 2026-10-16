module btree_unique_key_set;

const usz MIN_DEGREE = 255;
const usz MAX_NODE_KEYS = 2 * MIN_DEGREE - 1;
const usz MAX_NODE_COUNT = 32;
const usz MAX_INSERTS = 2048;
const usz MAX_QUERIES = 1024;
const usz MAX_DELETES = 1024;
const usz MAX_OUTPUT_VALUES = 2 + MAX_QUERIES + MAX_INSERTS;

struct BTree {
    int[MAX_NODE_COUNT][MAX_NODE_KEYS] keys;
    usz[MAX_NODE_COUNT][MAX_NODE_KEYS + 1] children;
    usz[MAX_NODE_COUNT] key_count;
    bool[MAX_NODE_COUNT] leaf;
    usz used_nodes;
    usz root;
}

fn bool search_key(BTree* tree, int key) {
    usz node = tree.root;
    while (true) {
        usz index = 0;
        while (index < tree.key_count[node] && key > tree.keys[node][index]) index++;
        if (index < tree.key_count[node] && key == tree.keys[node][index]) return true;
        if (tree.leaf[node]) return false;
        node = tree.children[node][index];
    }
}

fn bool split_child(BTree* tree, usz parent, usz child_index) {
    if (tree.used_nodes >= MAX_NODE_COUNT) return false;
    usz child = tree.children[parent][child_index];
    usz sibling = tree.used_nodes++;
    tree.leaf[sibling] = tree.leaf[child];
    for (usz i = 0; i < MIN_DEGREE - 1; i++) tree.keys[sibling][i] = tree.keys[child][i + MIN_DEGREE];
    if (!tree.leaf[child])
        for (usz i = 0; i < MIN_DEGREE; i++) tree.children[sibling][i] = tree.children[child][i + MIN_DEGREE];
    tree.key_count[sibling] = MIN_DEGREE - 1;
    usz parent_count = tree.key_count[parent], i = parent_count + 1;
    while (i > child_index + 1) { tree.children[parent][i] = tree.children[parent][i - 1]; i--; }
    tree.children[parent][child_index + 1] = sibling;
    i = parent_count;
    while (i > child_index) { tree.keys[parent][i] = tree.keys[parent][i - 1]; i--; }
    tree.keys[parent][child_index] = tree.keys[child][MIN_DEGREE - 1];
    tree.key_count[child] = MIN_DEGREE - 1;
    tree.key_count[parent] = parent_count + 1;
    return true;
}

fn bool insert_non_full(BTree* tree, usz node, int key) {
    usz index = tree.key_count[node];
    if (tree.leaf[node]) {
        while (index > 0 && key < tree.keys[node][index - 1]) {
            tree.keys[node][index] = tree.keys[node][index - 1];
            index--;
        }
        tree.keys[node][index] = key;
        tree.key_count[node]++;
        return true;
    }
    while (index > 0 && key < tree.keys[node][index - 1]) index--;
    if (tree.key_count[tree.children[node][index]] == MAX_NODE_KEYS) {
        if (!split_child(tree, node, index)) return false;
        if (key > tree.keys[node][index]) index++;
    }
    return insert_non_full(tree, tree.children[node][index], key);
}

fn bool insert_key(BTree* tree, int key) {
    if (tree.key_count[tree.root] == MAX_NODE_KEYS) {
        if (tree.used_nodes >= MAX_NODE_COUNT) return false;
        usz old_root = tree.root, root = tree.used_nodes++;
        tree.leaf[root] = false;
        tree.children[root][0] = old_root;
        tree.root = root;
        if (!split_child(tree, root, 0)) return false;
    }
    return insert_non_full(tree, tree.root, key);
}

fn int predecessor(BTree* tree, usz node) {
    while (!tree.leaf[node]) node = tree.children[node][tree.key_count[node]];
    return tree.keys[node][tree.key_count[node] - 1];
}

fn int successor(BTree* tree, usz node) {
    while (!tree.leaf[node]) node = tree.children[node][0];
    return tree.keys[node][0];
}

fn void merge_children(BTree* tree, usz parent, usz index) {
    usz left = tree.children[parent][index], right = tree.children[parent][index + 1];
    usz left_count = tree.key_count[left];
    tree.keys[left][left_count++] = tree.keys[parent][index];
    for (usz i = 0; i < tree.key_count[right]; i++) tree.keys[left][left_count + i] = tree.keys[right][i];
    if (!tree.leaf[left])
        for (usz i = 0; i <= tree.key_count[right]; i++) tree.children[left][left_count + i] = tree.children[right][i];
    tree.key_count[left] = left_count + tree.key_count[right];
    usz parent_count = tree.key_count[parent];
    for (usz i = index + 1; i < parent_count; i++) tree.keys[parent][i - 1] = tree.keys[parent][i];
    for (usz i = index + 2; i <= parent_count; i++) tree.children[parent][i - 1] = tree.children[parent][i];
    tree.key_count[parent]--;
}

fn void borrow_previous(BTree* tree, usz parent, usz index) {
    usz child = tree.children[parent][index], sibling = tree.children[parent][index - 1];
    usz count = tree.key_count[child], i = count;
    while (i > 0) { tree.keys[child][i] = tree.keys[child][i - 1]; i--; }
    if (!tree.leaf[child]) {
        i = count + 1;
        while (i > 0) { tree.children[child][i] = tree.children[child][i - 1]; i--; }
    }
    tree.keys[child][0] = tree.keys[parent][index - 1];
    if (!tree.leaf[child]) tree.children[child][0] = tree.children[sibling][tree.key_count[sibling]];
    tree.keys[parent][index - 1] = tree.keys[sibling][tree.key_count[sibling] - 1];
    tree.key_count[child]++;
    tree.key_count[sibling]--;
}

fn void borrow_next(BTree* tree, usz parent, usz index) {
    usz child = tree.children[parent][index], sibling = tree.children[parent][index + 1];
    usz child_count = tree.key_count[child], sibling_count = tree.key_count[sibling];
    tree.keys[child][child_count] = tree.keys[parent][index];
    if (!tree.leaf[child]) tree.children[child][child_count + 1] = tree.children[sibling][0];
    tree.keys[parent][index] = tree.keys[sibling][0];
    for (usz i = 1; i < sibling_count; i++) tree.keys[sibling][i - 1] = tree.keys[sibling][i];
    if (!tree.leaf[sibling])
        for (usz i = 1; i <= sibling_count; i++) tree.children[sibling][i - 1] = tree.children[sibling][i];
    tree.key_count[child]++;
    tree.key_count[sibling]--;
}

fn void fill_child(BTree* tree, usz parent, usz index) {
    if (index > 0 && tree.key_count[tree.children[parent][index - 1]] >= MIN_DEGREE)
        borrow_previous(tree, parent, index);
    else if (index < tree.key_count[parent] && tree.key_count[tree.children[parent][index + 1]] >= MIN_DEGREE)
        borrow_next(tree, parent, index);
    else merge_children(tree, parent, index < tree.key_count[parent] ? index : index - 1);
}

fn bool delete_from(BTree* tree, usz node, int key) {
    usz index = 0;
    while (index < tree.key_count[node] && tree.keys[node][index] < key) index++;
    if (index < tree.key_count[node] && tree.keys[node][index] == key) {
        if (tree.leaf[node]) {
            for (usz i = index + 1; i < tree.key_count[node]; i++) tree.keys[node][i - 1] = tree.keys[node][i];
            tree.key_count[node]--;
        } else {
            usz left = tree.children[node][index], right = tree.children[node][index + 1];
            if (tree.key_count[left] >= MIN_DEGREE) {
                int replacement = predecessor(tree, left);
                tree.keys[node][index] = replacement;
                return delete_from(tree, left, replacement);
            }
            if (tree.key_count[right] >= MIN_DEGREE) {
                int replacement = successor(tree, right);
                tree.keys[node][index] = replacement;
                return delete_from(tree, right, replacement);
            }
            merge_children(tree, node, index);
            return delete_from(tree, left, key);
        }
        return true;
    }
    if (tree.leaf[node]) return false;
    bool was_last = index == tree.key_count[node];
    if (tree.key_count[tree.children[node][index]] < MIN_DEGREE) fill_child(tree, node, index);
    if (was_last && index > tree.key_count[node]) index--;
    return delete_from(tree, tree.children[node][index], key);
}

fn bool delete_key(BTree* tree, int key) {
    if (!delete_from(tree, tree.root, key)) return false;
    if (tree.key_count[tree.root] == 0 && !tree.leaf[tree.root]) tree.root = tree.children[tree.root][0];
    return true;
}

fn void traverse(BTree* tree, usz node, long* result, usz* length) {
    for (usz i = 0; i < tree.key_count[node]; i++) {
        if (!tree.leaf[node]) traverse(tree, tree.children[node][i], result, length);
        result[length[0]++] = (long)tree.keys[node][i];
    }
    if (!tree.leaf[node]) traverse(tree, tree.children[node][tree.key_count[node]], result, length);
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long btree_unique_key_set(long* input, usz length, char* output, usz capacity)
    @export("btree_unique_key_set") {
    if (input == null || length < 3 || length > 4096) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_INSERTS) return -1;
    usz insert_count = (usz)input[0], query_offset = 1 + insert_count;
    if (query_offset >= length || input[query_offset] < 0 || input[query_offset] > (long)MAX_QUERIES) return -1;
    usz query_count = (usz)input[query_offset], delete_count_offset = query_offset + 1 + query_count;
    if (delete_count_offset >= length || input[delete_count_offset] < 0 || input[delete_count_offset] > (long)MAX_DELETES) return -1;
    usz delete_count = (usz)input[delete_count_offset];
    if (length != 3 + insert_count + query_count + delete_count) return -1;

    BTree tree;
    tree.used_nodes = 1;
    tree.root = 0;
    for (usz i = 0; i < MAX_NODE_COUNT; i++) { tree.key_count[i] = 0; tree.leaf[i] = false; }
    tree.leaf[0] = true;
    for (usz i = 0; i < insert_count; i++) {
        long raw = input[1 + i];
        if (raw < -2147483648 || raw > 2147483647) return -1;
        int key = (int)raw;
        if (search_key(&tree, key) || !insert_key(&tree, key)) return -1;
    }

    long[MAX_OUTPUT_VALUES] result;
    usz result_length = 0;
    result[result_length++] = (long)query_count;
    usz query_start = query_offset + 1;
    for (usz i = 0; i < query_count; i++) {
        long raw = input[query_start + i];
        if (raw < -2147483648 || raw > 2147483647) return -1;
        result[result_length++] = search_key(&tree, (int)raw) ? 1 : 0;
    }
    usz delete_start = delete_count_offset + 1;
    for (usz i = 0; i < delete_count; i++) {
        long raw = input[delete_start + i];
        if (raw < -2147483648 || raw > 2147483647 || !delete_key(&tree, (int)raw)) return -1;
    }
    usz count_slot = result_length++;
    traverse(&tree, tree.root, &result[0], &result_length);
    result[count_slot] = (long)(result_length - count_slot - 1);
    usz output_bytes = result_length * 8;
    if (output == null || capacity < output_bytes) return -2;
    for (usz i = 0; i < result_length; i++) store_i64_le(output, i * 8, result[i]);
    return (long)output_bytes;
}
