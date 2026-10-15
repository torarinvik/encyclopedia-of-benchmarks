module lowest_common_ancestor_binary_lifting;

const int MAX_NODES = 256;
const int MAX_QUERIES = 1024;
const int MAX_ARCS = 510;
const int LOG_LEVELS = 9;

fn long lowest_common_ancestor_binary_lifting(long* input, usz length, char* output, usz output_capacity)
        @export("lowest_common_ancestor_binary_lifting") {
    if (input == null || length < 4 || input[0] < 1 || input[0] > MAX_NODES) return -1;
    usz node_count = (usz)input[0];
    if (input[1] < 0 || input[1] >= (long)node_count || input[2] != (long)(node_count - 1) ||
        input[3] < 0 || input[3] > MAX_QUERIES) return -1;
    usz edge_count = (usz)input[2];
    usz query_count = (usz)input[3];
    usz query_offset = 4 + 2 * edge_count;
    if (length != query_offset + 2 * query_count) return -1;
    usz root = (usz)input[1];

    int[MAX_NODES] head;
    int[MAX_ARCS] arc_to;
    int[MAX_ARCS] arc_next;
    long[MAX_NODES] parent;
    usz[MAX_NODES] depth;
    usz[LOG_LEVELS * MAX_NODES] up;
    usz[MAX_NODES] stack;
    for (usz node = 0; node < node_count; node++) { head[node] = -1; parent[node] = -2; }
    usz arcs = 0;
    for (usz edge = 0; edge < edge_count; edge++) {
        long left = input[4 + 2 * edge];
        long right = input[5 + 2 * edge];
        if (left < 0 || left >= (long)node_count || right < 0 || right >= (long)node_count || left == right) return -1;
        usz a = (usz)left;
        usz b = (usz)right;
        arc_to[arcs] = (int)b; arc_next[arcs] = head[a]; head[a] = (int)arcs; arcs++;
        arc_to[arcs] = (int)a; arc_next[arcs] = head[b]; head[b] = (int)arcs; arcs++;
    }
    for (usz query = 0; query < query_count; query++) {
        for (usz side = 0; side < 2; side++) {
            long node = input[query_offset + 2 * query + side];
            if (node < 0 || node >= (long)node_count) return -1;
        }
    }

    usz top = 0;
    usz reached = 0;
    parent[root] = -1;
    up[root] = root;
    stack[top] = root;
    top++;
    while (top > 0) {
        top--;
        usz node = stack[top];
        reached++;
        int arc = head[node];
        while (arc >= 0) {
            usz neighbor = (usz)arc_to[(usz)arc];
            if ((long)neighbor != parent[node]) {
                if (parent[neighbor] != -2) return -1;
                parent[neighbor] = (long)node;
                depth[neighbor] = depth[node] + 1;
                up[neighbor] = node;
                stack[top] = neighbor;
                top++;
            }
            arc = arc_next[(usz)arc];
        }
    }
    if (reached != node_count) return -1;
    if (output_capacity < query_count || (query_count != 0 && output == null)) return -2;
    for (usz level = 1; level < LOG_LEVELS; level++) {
        for (usz node = 0; node < node_count; node++) {
            usz middle = up[(level - 1) * MAX_NODES + node];
            up[level * MAX_NODES + node] = up[(level - 1) * MAX_NODES + middle];
        }
    }
    for (usz query = 0; query < query_count; query++) {
        usz u = (usz)input[query_offset + 2 * query];
        usz v = (usz)input[query_offset + 2 * query + 1];
        if (depth[u] < depth[v]) { usz temp = u; u = v; v = temp; }
        usz difference = depth[u] - depth[v];
        for (usz level = 0; level < LOG_LEVELS; level++) {
            if (difference % 2 != 0) u = up[level * MAX_NODES + u];
            difference = difference / 2;
        }
        if (u != v) {
            for (usz level = LOG_LEVELS; level > 0; level--) {
                usz index = level - 1;
                usz up_u = up[index * MAX_NODES + u];
                usz up_v = up[index * MAX_NODES + v];
                if (up_u != up_v) { u = up_u; v = up_v; }
            }
            u = up[u];
        }
        output[query] = (char)u;
    }
    return (long)query_count;
}
