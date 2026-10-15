module lowest_common_ancestor;

const MAX_NODE_COUNT = 1023;
const INVALID_RESULT = -1;

fn long lowest_common_ancestor(long* input, usz length) @export("lowest_common_ancestor")
{
    if (input == null || length < 4 || input[0] < 2 || input[0] > MAX_NODE_COUNT) return INVALID_RESULT;
    usz count = (usz)input[0];
    if (length != 4 + 3 * count) return INVALID_RESULT;
    if (input[1] < 0 || input[1] >= (long)count || input[2] < 0 || input[2] >= (long)count ||
        input[3] < 0 || input[3] >= (long)count || input[2] == input[3]) return INVALID_RESULT;
    usz root = (usz)input[1];
    usz p = (usz)input[2];
    usz q = (usz)input[3];

    long[MAX_NODE_COUNT] parent;
    usz[MAX_NODE_COUNT] stack;
    usz[MAX_NODE_COUNT] path_p;
    usz[MAX_NODE_COUNT] path_q;
    bool[MAX_NODE_COUNT] seen;
    for (usz node = 0; node < count; node++) {
        parent[node] = -1;
        seen[node] = false;
    }
    for (usz node = 0; node < count; node++) {
        usz offset = 4 + 3 * node;
        if (input[offset] < -1000000000 || input[offset] > 1000000000) return INVALID_RESULT;
        for (usz edge = 1; edge <= 2; edge++) {
            long child = input[offset + edge];
            if (child < -1 || child >= (long)count) return INVALID_RESULT;
            if (child >= 0) {
                usz child_index = (usz)child;
                if (parent[child_index] != -1) return INVALID_RESULT;
                parent[child_index] = (long)node;
            }
        }
    }
    if (parent[root] != -1) return INVALID_RESULT;
    for (usz node = 0; node < count; node++) {
        if (node != root && parent[node] == -1) return INVALID_RESULT;
    }

    usz top = 0;
    usz reached = 0;
    stack[top] = root;
    top++;
    while (top > 0) {
        top--;
        usz node = stack[top];
        if (seen[node]) return INVALID_RESULT;
        seen[node] = true;
        reached++;
        usz offset = 4 + 3 * node;
        for (usz edge = 1; edge <= 2; edge++) {
            long child = input[offset + edge];
            if (child >= 0) {
                stack[top] = (usz)child;
                top++;
            }
        }
    }
    if (reached != count) return INVALID_RESULT;

    usz depth_p = 0;
    usz depth_q = 0;
    usz current = p;
    while (true) {
        path_p[depth_p] = current;
        depth_p++;
        if (current == root) break;
        current = (usz)parent[current];
    }
    current = q;
    while (true) {
        path_q[depth_q] = current;
        depth_q++;
        if (current == root) break;
        current = (usz)parent[current];
    }
    long ancestor = INVALID_RESULT;
    while (depth_p > 0 && depth_q > 0 && path_p[depth_p - 1] == path_q[depth_q - 1]) {
        ancestor = (long)path_p[depth_p - 1];
        depth_p--;
        depth_q--;
    }
    return ancestor;
}
