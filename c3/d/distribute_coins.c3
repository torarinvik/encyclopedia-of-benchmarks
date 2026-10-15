module distribute_coins;

const usz MAX_NODE_COUNT = 100;

fn long absolute_i64(long value) {
    return value < 0 ? -value : value;
}

fn long analyze(long* nodes, long node, long* moves) {
    if (node == -1) return 1;
    usz index = (usz)node;
    long left = nodes[3 * index + 1];
    long right = nodes[3 * index + 2];
    long left_excess = analyze(nodes, left, moves);
    long right_excess = analyze(nodes, right, moves);
    moves[0] += absolute_i64(1 - left_excess) + absolute_i64(1 - right_excess);
    return nodes[3 * index] + left_excess + right_excess - 2;
}

fn long distribute_coins(long* nodes, usz node_count, long root_index)
        @export("distribute_coins") {
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return root_index == -1 ? 0 : -1;
    if (nodes == null || root_index < 0 || (usz)root_index >= node_count) return -1;

    long[MAX_NODE_COUNT] parent;
    usz[MAX_NODE_COUNT] stack;
    bool[MAX_NODE_COUNT] seen;
    for (usz node = 0; node < node_count; node++) {
        parent[node] = -1;
        seen[node] = false;
    }

    long coin_total = 0;
    for (usz node = 0; node < node_count; node++) {
        long value = nodes[3 * node];
        if (value < 0 || value > 100) return -1;
        coin_total += value;
        for (usz edge = 1; edge <= 2; edge++) {
            long child = nodes[3 * node + edge];
            if (child < -1 || (child >= 0 && (usz)child >= node_count)) return -1;
            if (child >= 0) {
                usz child_index = (usz)child;
                if (parent[child_index] != -1) return -1;
                parent[child_index] = (long)node;
            }
        }
    }
    if (coin_total != (long)node_count) return -1;
    usz root = (usz)root_index;
    if (parent[root] != -1) return -1;
    for (usz node = 0; node < node_count; node++) {
        if (node != root && parent[node] == -1) return -1;
    }

    usz top = 0;
    usz reached = 0;
    stack[top] = root;
    top++;
    while (top > 0) {
        top--;
        usz node = stack[top];
        if (seen[node]) return -1;
        seen[node] = true;
        reached++;
        for (usz edge = 1; edge <= 2; edge++) {
            long child = nodes[3 * node + edge];
            if (child >= 0) {
                stack[top] = (usz)child;
                top++;
            }
        }
    }
    if (reached != node_count) return -1;

    long moves = 0;
    analyze(nodes, root_index, &moves);
    return moves;
}
