module binary_tree_path_sum;

const usz MAX_NODES = 63;

fn long count_from(long* input, usz node, long sum, long target) {
    usz base = 2 + 3 * node;
    long count = sum == target ? 1 : 0;
    long left = input[base + 1], right = input[base + 2];
    if (left >= 0) count += count_from(input, (usz)left, sum + input[2 + 3 * (usz)left], target);
    if (right >= 0) count += count_from(input, (usz)right, sum + input[2 + 3 * (usz)right], target);
    return count;
}

fn long start_at_each_node(long* input, usz node) {
    usz base = 2 + 3 * node;
    long count = count_from(input, node, input[base], input[0]);
    long left = input[base + 1], right = input[base + 2];
    if (left >= 0) count += start_at_each_node(input, (usz)left);
    if (right >= 0) count += start_at_each_node(input, (usz)right);
    return count;
}

fn long binary_tree_path_sum(long* input, usz length) @export("binary_tree_path_sum") {
    if (input == null || length < 2 || input[1] < 0 || input[1] > (long)MAX_NODES) return -1;
    usz count = (usz)input[1];
    if (length != 2 + 3 * count) return -1;
    if (count == 0) return 0;
    usz[MAX_NODES] parents;
    for (usz i = 0; i < count; i++) parents[i] = 0;
    for (usz node = 0; node < count; node++) {
        usz base = 2 + 3 * node;
        if (input[base] < -2147483648 || input[base] > 2147483647) return -1;
        for (usz side = 1; side <= 2; side++) {
            long child = input[base + side];
            if (child < -1 || child >= (long)count) return -1;
            if (child >= 0) {
                parents[(usz)child]++;
                if (parents[(usz)child] > 1) return -1;
            }
        }
    }
    if (parents[0] != 0) return -1;
    for (usz node = 1; node < count; node++) if (parents[node] != 1) return -1;
    bool[MAX_NODES] seen;
    usz[MAX_NODES] stack;
    for (usz i = 0; i < count; i++) seen[i] = false;
    usz top = 0, reached = 0;
    stack[top++] = 0;
    while (top > 0) {
        usz node = stack[--top];
        if (seen[node]) return -1;
        seen[node] = true; reached++;
        usz base = 2 + 3 * node;
        if (input[base + 1] >= 0) stack[top++] = (usz)input[base + 1];
        if (input[base + 2] >= 0) stack[top++] = (usz)input[base + 2];
    }
    if (reached != count) return -1;
    return start_at_each_node(input, 0);
}
