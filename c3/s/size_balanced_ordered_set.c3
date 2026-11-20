module size_balanced_ordered_set;

const long SBT_MAX_OPERATIONS = 128;
const long SBT_MAX_NODES = 128;
const long SBT_MISSING = -1025;

struct SbtTree {
    long[SBT_MAX_NODES + 1] key;
    int[SBT_MAX_NODES + 1] size;
    int[SBT_MAX_NODES + 1] left;
    int[SBT_MAX_NODES + 1] right;
    int used;
}

fn int sbt_size(SbtTree* tree, int node) {
    return node == 0 ? 0 : tree.size[node];
}

fn void sbt_update_size(SbtTree* tree, int node) {
    tree.size[node] = sbt_size(tree, tree.left[node])
                    + sbt_size(tree, tree.right[node]) + 1;
}

fn int sbt_rotate_left(SbtTree* tree, int root) {
    int pivot = tree.right[root];
    tree.right[root] = tree.left[pivot];
    tree.left[pivot] = root;
    sbt_update_size(tree, root);
    sbt_update_size(tree, pivot);
    return pivot;
}

fn int sbt_rotate_right(SbtTree* tree, int root) {
    int pivot = tree.left[root];
    tree.left[root] = tree.right[pivot];
    tree.right[pivot] = root;
    sbt_update_size(tree, root);
    sbt_update_size(tree, pivot);
    return pivot;
}

fn int sbt_maintain(SbtTree* tree, int root) {
    if (root == 0) return 0;

    int left = tree.left[root];
    int right = tree.right[root];
    if (sbt_size(tree, left) < sbt_size(tree, tree.left[right])) {
        tree.right[root] = sbt_rotate_right(tree, right);
        root = sbt_rotate_left(tree, root);
        tree.left[root] = sbt_maintain(tree, tree.left[root]);
        tree.right[root] = sbt_maintain(tree, tree.right[root]);
        return sbt_maintain(tree, root);
    }
    if (sbt_size(tree, left) < sbt_size(tree, tree.right[right])) {
        root = sbt_rotate_left(tree, root);
        tree.left[root] = sbt_maintain(tree, tree.left[root]);
        return sbt_maintain(tree, root);
    }
    if (sbt_size(tree, right) < sbt_size(tree, tree.left[left])) {
        root = sbt_rotate_right(tree, root);
        tree.right[root] = sbt_maintain(tree, tree.right[root]);
        return sbt_maintain(tree, root);
    }
    if (sbt_size(tree, right) < sbt_size(tree, tree.right[left])) {
        tree.left[root] = sbt_rotate_left(tree, left);
        root = sbt_rotate_right(tree, root);
        tree.left[root] = sbt_maintain(tree, tree.left[root]);
        tree.right[root] = sbt_maintain(tree, tree.right[root]);
        return sbt_maintain(tree, root);
    }
    return root;
}

fn bool sbt_contains(SbtTree* tree, int root, long key) {
    while (root != 0) {
        if (key < tree.key[root]) root = tree.left[root];
        else if (key > tree.key[root]) root = tree.right[root];
        else return true;
    }
    return false;
}

fn int sbt_insert_new(SbtTree* tree, int root, long key) {
    if (root == 0) {
        int node = ++tree.used;
        tree.key[node] = key;
        tree.size[node] = 1;
        return node;
    }
    if (key < tree.key[root]) tree.left[root] = sbt_insert_new(tree, tree.left[root], key);
    else tree.right[root] = sbt_insert_new(tree, tree.right[root], key);
    sbt_update_size(tree, root);
    return sbt_maintain(tree, root);
}

fn long sbt_rank_less(SbtTree* tree, int root, long key) {
    long rank = 0;
    while (root != 0) {
        if (key <= tree.key[root]) root = tree.left[root];
        else {
            rank += sbt_size(tree, tree.left[root]) + 1;
            root = tree.right[root];
        }
    }
    return rank;
}

fn long sbt_kth(SbtTree* tree, int root, long index) {
    if (index < 0 || index >= sbt_size(tree, root)) return SBT_MISSING;
    while (root != 0) {
        int left_size = sbt_size(tree, tree.left[root]);
        if (index == left_size) return tree.key[root];
        if (index < left_size) root = tree.left[root];
        else {
            index -= left_size + 1;
            root = tree.right[root];
        }
    }
    return SBT_MISSING;
}

fn long sbt_predecessor(SbtTree* tree, int root, long key) {
    long answer = SBT_MISSING;
    while (root != 0) {
        if (tree.key[root] < key) {
            answer = tree.key[root];
            root = tree.right[root];
        } else root = tree.left[root];
    }
    return answer;
}

fn long sbt_successor(SbtTree* tree, int root, long key) {
    long answer = SBT_MISSING;
    while (root != 0) {
        if (tree.key[root] > key) {
            answer = tree.key[root];
            root = tree.left[root];
        } else root = tree.right[root];
    }
    return answer;
}

fn long size_balanced_ordered_set(long* input, usz length)
    @export("size_balanced_ordered_set") {
    if (input == null || length < 1 || length > 1 + 2 * SBT_MAX_OPERATIONS) return -1;
    long operation_count_value = input[0];
    if (operation_count_value < 0 || operation_count_value > SBT_MAX_OPERATIONS) return -1;
    usz operation_count = (usz)operation_count_value;
    if (length != 1 + 2 * operation_count) return -1;

    for (usz i = 0; i < operation_count; i += 1) {
        long operation = input[1 + 2 * i];
        long argument = input[2 + 2 * i];
        if (operation < 0 || operation > 4) return -1;
        if (operation == 2) {
            if (argument < 0 || argument > 127) return -1;
        } else if (argument < -1024 || argument > 1023) return -1;
    }

    SbtTree tree = {};
    int root = 0;
    long checksum = 0;
    for (usz i = 0; i < operation_count; i += 1) {
        long operation = input[1 + 2 * i];
        long argument = input[2 + 2 * i];
        long answer;
        if (operation == 0) {
            if (!sbt_contains(&tree, root, argument))
                root = sbt_insert_new(&tree, root, argument);
            continue;
        }
        if (operation == 1) answer = sbt_rank_less(&tree, root, argument);
        else if (operation == 2) answer = sbt_kth(&tree, root, argument);
        else if (operation == 3) answer = sbt_predecessor(&tree, root, argument);
        else answer = sbt_successor(&tree, root, argument);
        checksum += (long)(i + 1) * (answer + 1025);
    }
    return checksum;
}
