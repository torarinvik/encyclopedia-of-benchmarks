module tree_height;

const usz MAX_NODES = 1023;
const usz MAX_ARCS = 2 * (MAX_NODES - 1);

fn long dfs_height(usz node, long* head, long* to, long* next, bool* visited,
                   long* dp, usz* reached) {
    visited[node] = true;
    *reached = *reached + 1;
    long child_height = 1;
    long arc = head[node];
    while (arc >= 0) {
        usz child = (usz)to[(usz)arc];
        if (!visited[child]) {
            if (dfs_height(child, head, to, next, visited, dp, reached) < 0) return -1;
            if (dp[child] + 1 > child_height) child_height = dp[child] + 1;
        }
        arc = next[(usz)arc];
    }
    dp[node] = child_height;
    return child_height;
}

fn long tree_height(long* values, usz length) @export("tree_height") {
    if (values == null || length < 1 || values[0] < 1 || values[0] > (long)MAX_NODES) return -1;
    usz count = (usz)values[0];
    if (length != 1 + 2 * (count - 1)) return -1;
    long[MAX_NODES + 1] head;
    long[MAX_ARCS] to;
    long[MAX_ARCS] next;
    long[MAX_NODES + 1] dp;
    bool[MAX_NODES + 1] visited;
    for (usz node = 0; node <= count; node++) { head[node] = -1; visited[node] = false; }
    usz arcs = 0;
    for (usz edge = 0; edge + 1 < count; edge++) {
        long a = values[1 + 2 * edge], b = values[2 + 2 * edge];
        if (a < 1 || b < 1 || a > (long)count || b > (long)count || a == b) return -1;
        to[arcs] = b; next[arcs] = head[(usz)a]; head[(usz)a] = (long)arcs; arcs++;
        to[arcs] = a; next[arcs] = head[(usz)b]; head[(usz)b] = (long)arcs; arcs++;
    }
    usz reached = 0;
    long result = dfs_height(1, &head[0], &to[0], &next[0], &visited[0], &dp[0], &reached);
    return result < 0 || reached != count ? -1 : result;
}
