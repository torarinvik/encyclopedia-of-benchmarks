module same_trees_check;

const usz MAX_NODE_COUNT = 1023;

struct TreeView {
    usz count;
    long root;
    long* rows;
}

fn bool parse_tree(long* input, usz length, usz* offset, TreeView* tree) {
    if (*offset > length || length - *offset < 2) return false;
    long count_value = input[*offset];
    long root = input[*offset + 1];
    if (count_value < 0 || count_value > (long)MAX_NODE_COUNT) return false;
    usz count = (usz)count_value;
    usz row_start = *offset + 2;
    if (count > (length - row_start) / 3) return false;
    (*tree).count = count;
    (*tree).root = root;
    (*tree).rows = &input[row_start];
    *offset = row_start + 3 * count;
    return true;
}

fn bool valid_tree(TreeView tree) {
    if (tree.count == 0) return tree.root == -1;
    if (tree.root < 0 || (usz)tree.root >= tree.count) return false;
    usz[MAX_NODE_COUNT] parents;
    for (usz index = 0; index < tree.count; index++) parents[index] = 0;
    for (usz index = 0; index < tree.count; index++) {
        long value = tree.rows[3 * index];
        long left = tree.rows[3 * index + 1];
        long right = tree.rows[3 * index + 2];
        if (value < -2147483648L || value > 2147483647L || left < -1 || right < -1 ||
            (left >= 0 && (usz)left >= tree.count) || (right >= 0 && (usz)right >= tree.count)) return false;
        if (left >= 0) { parents[(usz)left]++; if (parents[(usz)left] > 1) return false; }
        if (right >= 0) { parents[(usz)right]++; if (parents[(usz)right] > 1) return false; }
    }
    for (usz index = 0; index < tree.count; index++) {
        usz expected = index == (usz)tree.root ? 0 : 1;
        if (parents[index] != expected) return false;
    }
    usz[MAX_NODE_COUNT] queue;
    bool[MAX_NODE_COUNT] seen;
    for (usz index = 0; index < tree.count; index++) seen[index] = false;
    usz head = 0, tail = 0;
    queue[tail++] = (usz)tree.root;
    while (head < tail) {
        usz index = queue[head++];
        if (seen[index]) return false;
        seen[index] = true;
        long left = tree.rows[3 * index + 1], right = tree.rows[3 * index + 2];
        if (left >= 0) queue[tail++] = (usz)left;
        if (right >= 0) queue[tail++] = (usz)right;
    }
    return tail == tree.count;
}

fn long trees_equal(TreeView first, TreeView second) {
    if (first.root == -1 || second.root == -1) return first.root == second.root ? 1 : 0;
    long[MAX_NODE_COUNT] queue1, queue2;
    usz head = 0, tail = 0;
    queue1[tail] = first.root; queue2[tail++] = second.root;
    while (head < tail) {
        usz index1 = (usz)queue1[head], index2 = (usz)queue2[head];
        head++;
        long* a = &first.rows[3 * index1];
        long* b = &second.rows[3 * index2];
        if (a[0] != b[0] || (a[1] == -1) != (b[1] == -1) || (a[2] == -1) != (b[2] == -1)) return 0;
        if (a[1] >= 0) { queue1[tail] = a[1]; queue2[tail++] = b[1]; }
        if (a[2] >= 0) { queue1[tail] = a[2]; queue2[tail++] = b[2]; }
    }
    return 1;
}

fn long same_trees_check(long* input, usz length) @export("same_trees_check") {
    if (input == null || length < 4) return -1;
    usz offset = 0;
    TreeView first, second;
    if (!parse_tree(input, length, &offset, &first) || !parse_tree(input, length, &offset, &second) ||
        offset != length || first.count + second.count > MAX_NODE_COUNT ||
        !valid_tree(first) || !valid_tree(second)) return -1;
    return trees_equal(first, second);
}
