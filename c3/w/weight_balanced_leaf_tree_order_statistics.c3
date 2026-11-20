module weight_balanced_leaf_tree_order_statistics;

import std::core;

const long MAX_OPERATIONS = 64;
const long MISSING = -129;
const int NODE_CAPACITY = 129;

struct Tree {
    int[NODE_CAPACITY] left;
    int[NODE_CAPACITY] right;
    int[NODE_CAPACITY] size;
    int[NODE_CAPACITY] free_next;
    long[NODE_CAPACITY] key;
    long[NODE_CAPACITY] maximum;
    int next_node;
    int free_head;
}

fn int allocate(Tree* tree) {
    int node;
    if (tree.free_head != 0) {
        node = tree.free_head;
        tree.free_head = tree.free_next[node];
    } else {
        node = tree.next_node;
        tree.next_node += 1;
    }
    tree.left[node] = 0; tree.right[node] = 0; tree.size[node] = 0;
    tree.free_next[node] = 0; tree.key[node] = 0; tree.maximum[node] = 0;
    return node;
}

fn void release(Tree* tree, int node) {
    tree.left[node] = 0; tree.right[node] = 0; tree.size[node] = 0;
    tree.key[node] = 0; tree.maximum[node] = 0;
    tree.free_next[node] = tree.free_head;
    tree.free_head = node;
}

fn int leaf(Tree* tree, long value) {
    int node = allocate(tree);
    tree.key[node] = value; tree.maximum[node] = value; tree.size[node] = 1;
    return node;
}

fn int join(Tree* tree, int a, int b) {
    int node = allocate(tree);
    tree.left[node] = a; tree.right[node] = b;
    tree.size[node] = tree.size[a] + tree.size[b];
    tree.maximum[node] = tree.maximum[b];
    return node;
}

fn bool too_heavy(int a, int b) { return a > 3 * b; }
fn int merge(Tree* tree, int a, int b);

fn int rebalance(Tree* tree, int node) {
    if (tree.size[node] == 1) return node;
    int a = tree.left[node]; int b = tree.right[node];
    if (too_heavy(tree.size[a], tree.size[b]) || too_heavy(tree.size[b], tree.size[a])) {
        release(tree, node);
        return merge(tree, a, b);
    }
    return node;
}

fn int merge(Tree* tree, int a, int b) {
    if (a == 0) return b;
    if (b == 0) return a;
    if (too_heavy(tree.size[a], tree.size[b])) {
        int x = tree.left[a]; int y = tree.right[a];
        release(tree, a);
        return rebalance(tree, join(tree, x, merge(tree, y, b)));
    }
    if (too_heavy(tree.size[b], tree.size[a])) {
        int x = tree.left[b]; int y = tree.right[b];
        release(tree, b);
        return rebalance(tree, join(tree, merge(tree, a, x), y));
    }
    return join(tree, a, b);
}

fn int insert(Tree* tree, int node, long value) {
    if (node == 0) return leaf(tree, value);
    if (tree.size[node] == 1) {
        if (value <= tree.key[node]) return join(tree, leaf(tree, value), node);
        return join(tree, node, leaf(tree, value));
    }
    if (value <= tree.maximum[tree.left[node]]) {
        tree.left[node] = insert(tree, tree.left[node], value);
    } else {
        tree.right[node] = insert(tree, tree.right[node], value);
    }
    tree.size[node] = tree.size[tree.left[node]] + tree.size[tree.right[node]];
    tree.maximum[node] = tree.maximum[tree.right[node]];
    return rebalance(tree, node);
}

fn int remove_one(Tree* tree, int node, long value, bool* removed) {
    *removed = false;
    if (node == 0) return 0;
    if (tree.size[node] == 1) {
        if (tree.key[node] != value) return node;
        release(tree, node); *removed = true; return 0;
    }
    if (value <= tree.maximum[tree.left[node]]) {
        tree.left[node] = remove_one(tree, tree.left[node], value, removed);
    } else {
        tree.right[node] = remove_one(tree, tree.right[node], value, removed);
    }
    if (!*removed) return node;
    if (tree.left[node] == 0 || tree.right[node] == 0) {
        int child = tree.left[node] != 0 ? tree.left[node] : tree.right[node];
        release(tree, node); return child;
    }
    tree.size[node] = tree.size[tree.left[node]] + tree.size[tree.right[node]];
    tree.maximum[node] = tree.maximum[tree.right[node]];
    return rebalance(tree, node);
}

fn long rank_less(Tree* tree, int node, long value) {
    if (node == 0) return 0;
    if (tree.size[node] == 1) return tree.key[node] < value ? 1 : 0;
    int a = tree.left[node];
    if (value <= tree.maximum[a]) return rank_less(tree, a, value);
    return tree.size[a] + rank_less(tree, tree.right[node], value);
}

fn long kth(Tree* tree, int node, long index) {
    if (node == 0 || index >= tree.size[node]) return MISSING;
    while (tree.size[node] != 1) {
        int a = tree.left[node];
        if (index < tree.size[a]) node = a;
        else { index -= tree.size[a]; node = tree.right[node]; }
    }
    return tree.key[node];
}

fn long predecessor(Tree* tree, int node, long value) {
    if (node == 0) return MISSING;
    if (tree.size[node] == 1) return tree.key[node] < value ? tree.key[node] : MISSING;
    int a = tree.left[node];
    if (value <= tree.maximum[a]) return predecessor(tree, a, value);
    long answer = predecessor(tree, tree.right[node], value);
    return answer == MISSING ? tree.maximum[a] : answer;
}

fn long successor(Tree* tree, int node, long value) {
    if (node == 0) return MISSING;
    if (tree.size[node] == 1) return tree.key[node] > value ? tree.key[node] : MISSING;
    int a = tree.left[node];
    if (value < tree.maximum[a]) return successor(tree, a, value);
    return successor(tree, tree.right[node], value);
}

fn long weight_balanced_leaf_tree_order_statistics(long* input, usz length)
    @export("weight_balanced_leaf_tree_order_statistics") {
    if (input == null || length < 1 || length > 130) return -1;
    long q = input[0];
    if (q < 0 || q > MAX_OPERATIONS || length != 1 + 2 * (usz)q) return -1;
    for (usz i = 0; i < (usz)q; i += 1) {
        long op = input[1 + 2 * i]; long arg = input[2 + 2 * i];
        if (op < 0 || op > 5) return -1;
        if (op == 3) { if (arg < 0 || arg >= MAX_OPERATIONS) return -1; }
        else if (arg < -128 || arg > 127) return -1;
    }
    Tree tree = {};
    tree.next_node = 1;
    int root = 0;
    long checksum = 0;
    for (usz i = 0; i < (usz)q; i += 1) {
        long op = input[1 + 2 * i]; long arg = input[2 + 2 * i];
        if (op == 0) root = insert(&tree, root, arg);
        else if (op == 1) { bool removed = false; root = remove_one(&tree, root, arg, &removed); }
        else {
            long answer;
            if (op == 2) answer = rank_less(&tree, root, arg);
            else if (op == 3) answer = kth(&tree, root, arg);
            else if (op == 4) answer = predecessor(&tree, root, arg);
            else answer = successor(&tree, root, arg);
            checksum += (long)(i + 1) * (answer - MISSING);
        }
    }
    return checksum;
}
