module undirected_cycle_check;

const usz MAX_VERTICES = 32;
const usz MAX_EDGES = 256;
const usz MAX_MATRIX = MAX_VERTICES * MAX_VERTICES;

// Detect cycles in a bounded simple undirected graph with iterative DFS.
fn long undirected_cycle_check(long* input, usz length) @export("undirected_cycle_check") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > (long)MAX_VERTICES ||
        input[1] < 0 || input[1] > (long)MAX_EDGES) return -1;
    usz vertices = (usz)input[0];
    usz edges = (usz)input[1];
    if (length != 2 + 2 * edges) return -1;

    bool[MAX_MATRIX] adjacency = zeroed;
    for (usz edge = 0; edge < edges; edge++) {
        long left = input[2 + 2 * edge];
        long right = input[3 + 2 * edge];
        if (left < 0 || left >= (long)vertices || right < 0 || right >= (long)vertices) return -1;
        usz forward = (usz)left * MAX_VERTICES + (usz)right;
        usz reverse = (usz)right * MAX_VERTICES + (usz)left;
        if (adjacency[forward]) return -1;
        adjacency[forward] = true;
        adjacency[reverse] = true;
    }

    bool[MAX_VERTICES] visited = zeroed;
    usz[MAX_VERTICES] stack_vertex;
    usz[MAX_VERTICES] stack_parent;
    for (usz start = 0; start < vertices; start++) {
        if (visited[start]) continue;
        usz top = 1;
        stack_vertex[0] = start;
        stack_parent[0] = MAX_VERTICES;
        visited[start] = true;
        while (top > 0) {
            top--;
            usz current = stack_vertex[top];
            usz parent = stack_parent[top];
            for (usz neighbor = 0; neighbor < vertices; neighbor++) {
                if (!adjacency[current * MAX_VERTICES + neighbor] || neighbor == parent) continue;
                if (visited[neighbor]) return 1;
                visited[neighbor] = true;
                stack_vertex[top] = neighbor;
                stack_parent[top] = current;
                top++;
            }
        }
    }
    return 0;
}
