module bipartite_graph_dfs;

const usz MAX_VERTICES = 64;
const usz MAX_EDGES = 256;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES;
const usz MAX_CELLS = MAX_VERTICES * MAX_VERTICES;

fn long bipartite_graph_dfs(long* input, usz length) @export("bipartite_graph_dfs") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_VERTICES || input[1] < 0 || input[1] > (long)MAX_EDGES) return -1;
    usz n = (usz)input[0], m = (usz)input[1];
    if (length != 2 + 2 * m) return -1;

    char[MAX_CELLS] adjacency;
    for (usz i = 0; i < MAX_CELLS; i++) adjacency[i] = 0;
    for (usz edge = 0; edge < m; edge++) {
        long from_value = input[2 + 2 * edge], to_value = input[3 + 2 * edge];
        if (from_value < 0 || from_value >= (long)n || to_value < 0 || to_value >= (long)n) return -1;
        usz from = (usz)from_value, to = (usz)to_value;
        adjacency[from * n + to] = 1;
        adjacency[to * n + from] = 1;
    }

    int[MAX_VERTICES] color;
    usz[MAX_VERTICES] stack;
    for (usz i = 0; i < n; i++) color[i] = -1;
    for (usz start = 0; start < n; start++) {
        if (color[start] != -1) continue;
        usz top = 0;
        stack[top++] = start;
        color[start] = 0;
        while (top > 0) {
            usz node = stack[--top];
            for (usz neighbor = 0; neighbor < n; neighbor++) {
                if (adjacency[node * n + neighbor] == 0) continue;
                if (color[neighbor] == -1) {
                    color[neighbor] = 1 - color[node];
                    stack[top++] = neighbor;
                } else if (color[neighbor] == color[node]) return 0;
            }
        }
    }
    return 1;
}
