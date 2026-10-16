module binary_tree_is_full;

const int MAX_N = 1024;

fn long binary_tree_is_full(long* input, usz length) @export("binary_tree_is_full") {
    if (input == null || length < 2 || input[0] < 1 || input[0] > (long)MAX_N) return -1;
    int n = (int)input[0];
    long root_value = input[1];
    if (root_value < 0 || root_value >= (long)n || length != 2 + 2 * (usz)n) return -1;

    int[MAX_N] left;
    int[MAX_N] right;
    int[MAX_N] parents;
    int[MAX_N] stack;
    bool[MAX_N] seen;
    bool full = true;
    for (int i = 0; i < MAX_N; i++) {
        parents[i] = 0;
        seen[i] = false;
    }
    for (int i = 0; i < n; i++) {
        long l = input[2 + 2 * i];
        long r = input[3 + 2 * i];
        if (l < -1 || l >= (long)n || r < -1 || r >= (long)n || l == (long)i || r == (long)i) return -1;
        left[i] = (int)l;
        right[i] = (int)r;
        if (l >= 0) parents[(int)l]++;
        if (r >= 0) parents[(int)r]++;
        if ((l < 0) != (r < 0)) full = false;
    }
    int root = (int)root_value;
    if (parents[root] != 0) return -1;
    for (int i = 0; i < n; i++) {
        if (i != root && parents[i] != 1) return -1;
    }
    int top = 1;
    int visited = 0;
    stack[0] = root;
    while (top > 0) {
        top--;
        int node = stack[top];
        if (seen[node]) return -1;
        seen[node] = true;
        visited++;
        if (left[node] >= 0) {
            stack[top] = left[node];
            top++;
        }
        if (right[node] >= 0) {
            stack[top] = right[node];
            top++;
        }
    }
    if (visited != n) return -1;
    return full ? 1 : 0;
}
