module breadth_first_search_shortest_path;

const int MAX_VERTICES = 32;
const int MAX_EDGES = 256;
const int MAX_INPUT_LENGTH = 4 + 2 * MAX_EDGES;
const int MAX_OUTPUT_VALUES = 1 + MAX_VERTICES;

fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long breadth_first_search_shortest_path(long* input, usz length, char* output, usz capacity) @export("breadth_first_search_shortest_path") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    long vertex_value = input[0], edge_value = input[1], start_value = input[2], goal_value = input[3];
    if (vertex_value < 1 || vertex_value > MAX_VERTICES || edge_value < 0 || edge_value > MAX_EDGES) return -1;
    int vertices = (int)vertex_value, edges = (int)edge_value;
    if (length != 4 + 2 * (usz)edges || start_value < 0 || start_value >= vertices || goal_value < 0 || goal_value >= vertices) return -1;
    int adjacency[MAX_VERTICES * MAX_EDGES], degree[MAX_VERTICES] = {};
    for (int edge = 0; edge < edges; edge++) {
        long from = input[4 + 2 * edge], to = input[5 + 2 * edge];
        if (from < 0 || from >= vertices || to < 0 || to >= vertices) return -1;
        int source = (int)from;
        adjacency[source * MAX_EDGES + degree[source]++] = (int)to;
    }
    int start = (int)start_value, goal = (int)goal_value;
    long parent[MAX_VERTICES];
    bool visited[MAX_VERTICES] = {};
    int queue[MAX_VERTICES], head = 0, tail = 0;
    for (int vertex = 0; vertex < vertices; vertex++) parent[vertex] = -1;
    visited[start] = true;
    queue[tail++] = start;
    while (head < tail && !visited[goal]) {
        int node = queue[head++];
        for (int index = 0; index < degree[node]; index++) {
            int neighbor = adjacency[node * MAX_EDGES + index];
            if (visited[neighbor]) continue;
            visited[neighbor] = true;
            parent[neighbor] = node;
            queue[tail++] = neighbor;
            if (neighbor == goal) break;
        }
    }
    long encoded[MAX_OUTPUT_VALUES];
    usz path_count = 0;
    if (visited[goal]) {
        int reverse_path[MAX_VERTICES];
        int current = goal;
        while (current >= 0) {
            reverse_path[path_count++] = current;
            if (current == start) break;
            current = (int)parent[current];
        }
        for (usz index = 0; index < path_count; index++) encoded[1 + index] = reverse_path[path_count - 1 - index];
    }
    encoded[0] = (long)path_count;
    usz required = (path_count + 1) * 8;
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index <= path_count; index++) put_i64(output, index * 8, encoded[index]);
    return (long)required;
}
