module ordered_set_avl_order_statistics;

const long MAX_ITEMS = 32;
const long MAX_OPS = 32;
const long MAX_KEY = 1000;
const long NODE_CAP = 64;

struct Tree {
    long[NODE_CAP + 1] key;
    int[NODE_CAP + 1] height;
    int[NODE_CAP + 1] size;
    int[NODE_CAP + 1] left;
    int[NODE_CAP + 1] right;
    int used;
}

fn int height(Tree* tree, int node) { return node == 0 ? 0 : tree.height[node]; }
fn int size(Tree* tree, int node) { return node == 0 ? 0 : tree.size[node]; }

fn void refresh(Tree* tree, int node) {
    int lh = height(tree, tree.left[node]), rh = height(tree, tree.right[node]);
    tree.height[node] = (lh > rh ? lh : rh) + 1;
    tree.size[node] = size(tree, tree.left[node]) + size(tree, tree.right[node]) + 1;
}

fn int rotate_right(Tree* tree, int root) {
    int pivot = tree.left[root];
    tree.left[root] = tree.right[pivot];
    tree.right[pivot] = root;
    refresh(tree, root); refresh(tree, pivot);
    return pivot;
}

fn int rotate_left(Tree* tree, int root) {
    int pivot = tree.right[root];
    tree.right[root] = tree.left[pivot];
    tree.left[pivot] = root;
    refresh(tree, root); refresh(tree, pivot);
    return pivot;
}

fn int rebalance(Tree* tree, int root) {
    refresh(tree, root);
    int difference = height(tree, tree.left[root]) - height(tree, tree.right[root]);
    if (difference > 1) {
        int child = tree.left[root];
        if (height(tree, tree.left[child]) < height(tree, tree.right[child])) tree.left[root] = rotate_left(tree, child);
        return rotate_right(tree, root);
    }
    if (difference < -1) {
        int child = tree.right[root];
        if (height(tree, tree.right[child]) < height(tree, tree.left[child])) tree.right[root] = rotate_right(tree, child);
        return rotate_left(tree, root);
    }
    return root;
}

fn int insert_key(Tree* tree, int root, long key) {
    if (root == 0) {
        int node = ++tree.used;
        tree.key[node] = key; tree.height[node] = 1; tree.size[node] = 1;
        return node;
    }
    if (key < tree.key[root]) tree.left[root] = insert_key(tree, tree.left[root], key);
    else if (key > tree.key[root]) tree.right[root] = insert_key(tree, tree.right[root], key);
    else return root;
    return rebalance(tree, root);
}

fn int minimum_node(Tree* tree, int root) {
    while (tree.left[root] != 0) root = tree.left[root];
    return root;
}

fn int erase_key(Tree* tree, int root, long key) {
    if (root == 0) return 0;
    if (key < tree.key[root]) tree.left[root] = erase_key(tree, tree.left[root], key);
    else if (key > tree.key[root]) tree.right[root] = erase_key(tree, tree.right[root], key);
    else if (tree.left[root] == 0) return tree.right[root];
    else if (tree.right[root] == 0) return tree.left[root];
    else {
        int next = minimum_node(tree, tree.right[root]);
        tree.key[root] = tree.key[next];
        tree.right[root] = erase_key(tree, tree.right[root], tree.key[next]);
    }
    return rebalance(tree, root);
}

fn long kth(Tree* tree, int root, long rank) {
    if (rank < 1 || rank > size(tree, root)) return -1;
    while (root != 0) {
        int left_count = size(tree, tree.left[root]);
        if (rank == left_count + 1) return tree.key[root];
        if (rank <= left_count) root = tree.left[root];
        else { rank -= left_count + 1; root = tree.right[root]; }
    }
    return -1;
}

fn long count_le(Tree* tree, int root, long key) {
    long count = 0;
    while (root != 0) {
        if (tree.key[root] <= key) { count += size(tree, tree.left[root]) + 1; root = tree.right[root]; }
        else root = tree.left[root];
    }
    return count;
}

fn long predecessor(Tree* tree, int root, long key) {
    long answer = -1;
    while (root != 0) {
        if (tree.key[root] <= key) { answer = tree.key[root]; root = tree.right[root]; }
        else root = tree.left[root];
    }
    return answer;
}

fn long successor(Tree* tree, int root, long key) {
    long answer = -1;
    while (root != 0) {
        if (tree.key[root] >= key) { answer = tree.key[root]; root = tree.left[root]; }
        else root = tree.right[root];
    }
    return answer;
}

fn long ordered_set_avl_order_statistics(long* input, usz length) @export("ordered_set_avl_order_statistics") {
    if (input == null || length < 2 || length > 99) return -1;
    long n = input[0], q = input[1];
    if (n < 0 || n > MAX_ITEMS || q < 0 || q > MAX_OPS || length != 2 + n + 2 * q) return -1;
    for (long i = 0; i < n; i++) {
        long key = input[2 + i];
        if (key < 0 || key > MAX_KEY || (i > 0 && input[1 + i] >= key)) return -1;
    }
    for (long i = 0; i < q; i++) {
        long op = input[2 + n + 2 * i], key = input[3 + n + 2 * i];
        if (op < 0 || op > 5 || key < 0 || key > MAX_KEY || (op == 2 && key < 1)) return -1;
    }
    Tree tree = {};
    int root = 0;
    for (long i = 0; i < n; i++) root = insert_key(&tree, root, input[2 + i]);
    long checksum = 0, query_index = 0;
    for (long i = 0; i < q; i++) {
        long op = input[2 + n + 2 * i], key = input[3 + n + 2 * i];
        if (op == 0) root = insert_key(&tree, root, key);
        else if (op == 1) root = erase_key(&tree, root, key);
        else {
            long answer = op == 2 ? kth(&tree, root, key) : op == 3 ? count_le(&tree, root, key)
                         : op == 4 ? predecessor(&tree, root, key) : successor(&tree, root, key);
            query_index++;
            checksum += query_index * (answer + 1);
        }
    }
    return checksum;
}
