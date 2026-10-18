module tree_234;

const usz MAX_OPERATIONS = 128;
const usz MAX_NODES = 2049;
const usz MAX_PARSEABLE_INPUT_LENGTH = 258;
const usz MAX_OUTPUT_WORDS = 130;
const usz MAX_OUTPUT_BYTES = 1040;

struct Node { long[3] keys; int[4] children; int key_count; bool leaf; }
struct Tree { Node[MAX_NODES] nodes; usz node_count; int root; long[MAX_OPERATIONS] final_keys; usz final_count; }

fn int new_node(Tree* tree, bool leaf) {
    int index = (int)tree.node_count;
    tree.node_count++;
    tree.nodes[index].key_count = 0;
    tree.nodes[index].leaf = leaf;
    for (int child = 0; child < 4; child++) tree.nodes[index].children[child] = -1;
    return index;
}

fn bool contains(Tree* tree, int node_index, long key) {
    if (node_index < 0) return false;
    Node* node = &tree.nodes[node_index];
    int slot = 0;
    while (slot < node.key_count && key > node.keys[slot]) slot++;
    if (slot < node.key_count && key == node.keys[slot]) return true;
    return !node.leaf && contains(tree, node.children[slot], key);
}

fn void split_child(Tree* tree, int parent_index, int child_slot) {
    int child_index = tree.nodes[parent_index].children[child_slot];
    bool leaf = tree.nodes[child_index].leaf;
    int right_index = new_node(tree, leaf);
    tree.nodes[right_index].key_count = 1;
    tree.nodes[right_index].keys[0] = tree.nodes[child_index].keys[2];
    if (!leaf) {
        tree.nodes[right_index].children[0] = tree.nodes[child_index].children[2];
        tree.nodes[right_index].children[1] = tree.nodes[child_index].children[3];
    }
    long middle = tree.nodes[child_index].keys[1];
    tree.nodes[child_index].key_count = 1;
    int parent_count = tree.nodes[parent_index].key_count;
    for (int slot = parent_count; slot > child_slot; slot--) tree.nodes[parent_index].keys[slot] = tree.nodes[parent_index].keys[slot - 1];
    for (int slot = parent_count + 1; slot > child_slot + 1; slot--) tree.nodes[parent_index].children[slot] = tree.nodes[parent_index].children[slot - 1];
    tree.nodes[parent_index].keys[child_slot] = middle;
    tree.nodes[parent_index].children[child_slot + 1] = right_index;
    tree.nodes[parent_index].key_count++;
}

fn void insert_nonfull(Tree* tree, int node_index, long key) {
    int slot = tree.nodes[node_index].key_count - 1;
    if (tree.nodes[node_index].leaf) {
        while (slot >= 0 && key < tree.nodes[node_index].keys[slot]) {
            tree.nodes[node_index].keys[slot + 1] = tree.nodes[node_index].keys[slot];
            slot--;
        }
        tree.nodes[node_index].keys[slot + 1] = key;
        tree.nodes[node_index].key_count++;
        return;
    }
    while (slot >= 0 && key < tree.nodes[node_index].keys[slot]) slot--;
    slot++;
    int child_index = tree.nodes[node_index].children[slot];
    if (tree.nodes[child_index].key_count == 3) {
        split_child(tree, node_index, slot);
        if (key > tree.nodes[node_index].keys[slot]) slot++;
        child_index = tree.nodes[node_index].children[slot];
    }
    insert_nonfull(tree, child_index, key);
}

fn void insert_key(Tree* tree, long key) {
    if (contains(tree, tree.root, key)) return;
    if (tree.root < 0) {
        tree.root = new_node(tree, true);
        tree.nodes[tree.root].keys[0] = key;
        tree.nodes[tree.root].key_count = 1;
        return;
    }
    if (tree.nodes[tree.root].key_count == 3) {
        int new_root = new_node(tree, false);
        tree.nodes[new_root].children[0] = tree.root;
        tree.root = new_root;
        split_child(tree, new_root, 0);
    }
    insert_nonfull(tree, tree.root, key);
}

fn int find_key(Node* node, long key) {
    int slot = 0;
    while (slot < node.key_count && node.keys[slot] < key) slot++;
    return slot < node.key_count && node.keys[slot] == key ? slot : -1;
}

fn long predecessor(Tree* tree, int node_index) {
    while (!tree.nodes[node_index].leaf) node_index = tree.nodes[node_index].children[tree.nodes[node_index].key_count];
    return tree.nodes[node_index].keys[tree.nodes[node_index].key_count - 1];
}

fn long successor(Tree* tree, int node_index) {
    while (!tree.nodes[node_index].leaf) node_index = tree.nodes[node_index].children[0];
    return tree.nodes[node_index].keys[0];
}

fn int merge_children(Tree* tree, int parent_index, int key_slot) {
    int left_index = tree.nodes[parent_index].children[key_slot];
    int right_index = tree.nodes[parent_index].children[key_slot + 1];
    int left_count = tree.nodes[left_index].key_count;
    int right_count = tree.nodes[right_index].key_count;
    tree.nodes[left_index].keys[left_count] = tree.nodes[parent_index].keys[key_slot];
    for (int slot = 0; slot < right_count; slot++) tree.nodes[left_index].keys[left_count + 1 + slot] = tree.nodes[right_index].keys[slot];
    if (!tree.nodes[left_index].leaf) {
        for (int slot = 0; slot <= right_count; slot++) tree.nodes[left_index].children[left_count + 1 + slot] = tree.nodes[right_index].children[slot];
    }
    tree.nodes[left_index].key_count = left_count + 1 + right_count;
    int parent_count = tree.nodes[parent_index].key_count;
    for (int slot = key_slot; slot < parent_count - 1; slot++) tree.nodes[parent_index].keys[slot] = tree.nodes[parent_index].keys[slot + 1];
    for (int slot = key_slot + 1; slot < parent_count; slot++) tree.nodes[parent_index].children[slot] = tree.nodes[parent_index].children[slot + 1];
    tree.nodes[parent_index].key_count--;
    return left_index;
}

fn void borrow_from_previous(Tree* tree, int parent_index, int child_slot) {
    int child_index = tree.nodes[parent_index].children[child_slot];
    int sibling_index = tree.nodes[parent_index].children[child_slot - 1];
    int child_count = tree.nodes[child_index].key_count;
    int sibling_count = tree.nodes[sibling_index].key_count;
    for (int slot = child_count; slot > 0; slot--) tree.nodes[child_index].keys[slot] = tree.nodes[child_index].keys[slot - 1];
    if (!tree.nodes[child_index].leaf) {
        for (int slot = child_count + 1; slot > 0; slot--) tree.nodes[child_index].children[slot] = tree.nodes[child_index].children[slot - 1];
        tree.nodes[child_index].children[0] = tree.nodes[sibling_index].children[sibling_count];
    }
    tree.nodes[child_index].keys[0] = tree.nodes[parent_index].keys[child_slot - 1];
    tree.nodes[parent_index].keys[child_slot - 1] = tree.nodes[sibling_index].keys[sibling_count - 1];
    tree.nodes[child_index].key_count++;
    tree.nodes[sibling_index].key_count--;
}

fn void borrow_from_next(Tree* tree, int parent_index, int child_slot) {
    int child_index = tree.nodes[parent_index].children[child_slot];
    int sibling_index = tree.nodes[parent_index].children[child_slot + 1];
    int child_count = tree.nodes[child_index].key_count;
    int sibling_count = tree.nodes[sibling_index].key_count;
    tree.nodes[child_index].keys[child_count] = tree.nodes[parent_index].keys[child_slot];
    if (!tree.nodes[child_index].leaf) tree.nodes[child_index].children[child_count + 1] = tree.nodes[sibling_index].children[0];
    tree.nodes[parent_index].keys[child_slot] = tree.nodes[sibling_index].keys[0];
    for (int slot = 0; slot < sibling_count - 1; slot++) tree.nodes[sibling_index].keys[slot] = tree.nodes[sibling_index].keys[slot + 1];
    if (!tree.nodes[sibling_index].leaf) {
        for (int slot = 0; slot < sibling_count; slot++) tree.nodes[sibling_index].children[slot] = tree.nodes[sibling_index].children[slot + 1];
    }
    tree.nodes[child_index].key_count++;
    tree.nodes[sibling_index].key_count--;
}

fn void remove_from_node(Tree* tree, int node_index, long key) {
    int key_slot = find_key(&tree.nodes[node_index], key);
    if (key_slot >= 0) {
        if (tree.nodes[node_index].leaf) {
            int count = tree.nodes[node_index].key_count;
            for (int slot = key_slot; slot < count - 1; slot++) tree.nodes[node_index].keys[slot] = tree.nodes[node_index].keys[slot + 1];
            tree.nodes[node_index].key_count--;
            return;
        }
        int left_index = tree.nodes[node_index].children[key_slot];
        int right_index = tree.nodes[node_index].children[key_slot + 1];
        if (tree.nodes[left_index].key_count >= 2) {
            long replacement = predecessor(tree, left_index);
            tree.nodes[node_index].keys[key_slot] = replacement;
            remove_from_node(tree, left_index, replacement);
        } else if (tree.nodes[right_index].key_count >= 2) {
            long replacement = successor(tree, right_index);
            tree.nodes[node_index].keys[key_slot] = replacement;
            remove_from_node(tree, right_index, replacement);
        } else {
            int merged = merge_children(tree, node_index, key_slot);
            remove_from_node(tree, merged, key);
        }
        return;
    }
    if (tree.nodes[node_index].leaf) return;
    int child_slot = 0;
    while (child_slot < tree.nodes[node_index].key_count && key > tree.nodes[node_index].keys[child_slot]) child_slot++;
    int child_index = tree.nodes[node_index].children[child_slot];
    if (tree.nodes[child_index].key_count == 1) {
        if (child_slot > 0 && tree.nodes[tree.nodes[node_index].children[child_slot - 1]].key_count >= 2) {
            borrow_from_previous(tree, node_index, child_slot);
        } else if (child_slot < tree.nodes[node_index].key_count && tree.nodes[tree.nodes[node_index].children[child_slot + 1]].key_count >= 2) {
            borrow_from_next(tree, node_index, child_slot);
        } else if (child_slot < tree.nodes[node_index].key_count) {
            child_index = merge_children(tree, node_index, child_slot);
        } else {
            child_index = merge_children(tree, node_index, child_slot - 1);
        }
    }
    remove_from_node(tree, child_index, key);
}

fn bool remove_key(Tree* tree, long key) {
    if (!contains(tree, tree.root, key)) return false;
    remove_from_node(tree, tree.root, key);
    if (tree.root >= 0 && tree.nodes[tree.root].key_count == 0) {
        int old_root = tree.root;
        tree.root = tree.nodes[old_root].leaf ? -1 : tree.nodes[old_root].children[0];
    }
    return true;
}

fn void traverse(Tree* tree, int node_index) {
    if (node_index < 0) return;
    int count = tree.nodes[node_index].key_count;
    bool leaf = tree.nodes[node_index].leaf;
    for (int slot = 0; slot < count; slot++) {
        if (!leaf) traverse(tree, tree.nodes[node_index].children[slot]);
        tree.final_keys[tree.final_count] = tree.nodes[node_index].keys[slot];
        tree.final_count++;
    }
    if (!leaf) traverse(tree, tree.nodes[node_index].children[count]);
}

fn long tree_234(long* input, usz input_length, uint8* output, usz capacity) @export("tree_234") {
    if (input == null || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)input[0];
    if (input_length != 1 + 2 * operation_count) return -1;
    for (usz operation = 0; operation < operation_count; operation++) {
        long code = input[1 + 2 * operation];
        if (code != 0 && code != 1) return -1;
    }
    Tree tree = zeroed;
    tree.root = -1;
    long[MAX_OPERATIONS] remove_results = zeroed;
    usz remove_count = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        long code = input[1 + 2 * operation];
        long key = input[2 + 2 * operation];
        if (code == 0) insert_key(&tree, key);
        else { remove_results[remove_count] = remove_key(&tree, key) ? 1 : 0; remove_count++; }
    }
    traverse(&tree, tree.root);
    long[MAX_OUTPUT_WORDS] words = zeroed;
    words[0] = (long)remove_count;
    for (usz index = 0; index < remove_count; index++) words[1 + index] = remove_results[index];
    words[1 + remove_count] = (long)tree.final_count;
    for (usz index = 0; index < tree.final_count; index++) words[2 + remove_count + index] = tree.final_keys[index];
    usz word_count = 2 + remove_count + tree.final_count;
    usz output_bytes = word_count * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == null || capacity < output_bytes) return -2;
    for (usz index = 0; index < word_count; index++) {
        ulong bits = (ulong)words[index];
        for (usz byte = 0; byte < 8; byte++) { output[index * 8 + byte] = (uint8)(bits & 255); bits >>= 8; }
    }
    return (long)output_bytes;
}
