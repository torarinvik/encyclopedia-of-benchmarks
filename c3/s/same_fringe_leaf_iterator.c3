module same_fringe_leaf_iterator;

const usz MAX_TREE_NODES = 15;
const usz MAX_TOTAL_NODES = 30;
const usz MAX_PARSEABLE_LENGTH = 93;

fn bool valid_tree(long* input, usz offset, usz node_count) {
    long[15] visited = {};
    long[15] parents = {};
    usz[15] stack = {};
    usz top = 1;
    usz reached = 0;
    while (top > 0) {
        top -= 1;
        usz node = stack[top];
        if (node >= node_count || visited[node] != 0) return false;
        visited[node] = 1;
        reached += 1;
        usz base = offset + 3 * node;
        long left = input[base + 1];
        long right = input[base + 2];
        if (left == -1 && right == -1) continue;
        if (left < 0 || right < 0 || (usz)left >= node_count || (usz)right >= node_count ||
            left == right || left == 0 || right == 0) return false;
        parents[(usz)left] += 1;
        parents[(usz)right] += 1;
        if (parents[(usz)left] != 1 || parents[(usz)right] != 1) return false;
        stack[top] = (usz)right;
        top += 1;
        stack[top] = (usz)left;
        top += 1;
    }
    if (reached != node_count || parents[0] != 0) return false;
    for (usz node = 1; node < node_count; node += 1)
        if (parents[node] != 1) return false;
    return true;
}

fn long same_fringe_leaf_iterator(long* input, usz length) @export("same_fringe_leaf_iterator") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_LENGTH) return -1;
    long n_a_word = input[0];
    long n_b_word = input[1];
    if (n_a_word < 1 || n_a_word > (long)MAX_TREE_NODES ||
        n_b_word < 1 || n_b_word > (long)MAX_TREE_NODES) return -1;
    usz n_a = (usz)n_a_word;
    usz n_b = (usz)n_b_word;
    if (n_a + n_b > MAX_TOTAL_NODES || length != 2 + 3 * (n_a + n_b)) return -1;
    usz offset_a = 2;
    usz offset_b = 2 + 3 * n_a;
    if (!valid_tree(input, offset_a, n_a) || !valid_tree(input, offset_b, n_b)) return -1;

    usz[15] stack_a = {};
    usz[15] stack_b = {};
    usz top_a = 1;
    usz top_b = 1;
    for (;;) {
        bool have_a = false;
        bool have_b = false;
        long leaf_a = 0;
        long leaf_b = 0;
        while (top_a > 0 && !have_a) {
            top_a -= 1;
            usz node = stack_a[top_a];
            usz base = offset_a + 3 * node;
            long left = input[base + 1];
            long right = input[base + 2];
            if (left == -1) {
                leaf_a = input[base];
                have_a = true;
            } else {
                stack_a[top_a] = (usz)right;
                top_a += 1;
                stack_a[top_a] = (usz)left;
                top_a += 1;
            }
        }
        while (top_b > 0 && !have_b) {
            top_b -= 1;
            usz node = stack_b[top_b];
            usz base = offset_b + 3 * node;
            long left = input[base + 1];
            long right = input[base + 2];
            if (left == -1) {
                leaf_b = input[base];
                have_b = true;
            } else {
                stack_b[top_b] = (usz)right;
                top_b += 1;
                stack_b[top_b] = (usz)left;
                top_b += 1;
            }
        }
        if (!have_a || !have_b) {
            if (have_a == have_b) return 1;
            return 0;
        }
        if (leaf_a != leaf_b) return 0;
    }
    return -1;
}
