module bfs_connected_undirected_visit_order;

const usz MAX_VERTICES = 40;
const usz MAX_EDGES = 780;

fn void put_i64(char* output, usz slot, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[slot * 8 + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long bfs_connected_undirected_visit_order(long* input, usz length,
    char* output, usz capacity) @export("bfs_connected_undirected_visit_order") {
    if (input == null || length < 3) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_VERTICES || input[1] < 0 || input[1] > (long)MAX_EDGES || input[2] != 0) return -1;
    usz vertices = (usz)input[0];
    usz edge_count = (usz)input[1];
    if (length != 3 + 2 * edge_count) return -1;

    ulong[MAX_VERTICES] adjacency;
    for (usz i = 0; i < MAX_VERTICES; i++) adjacency[i] = 0;
    for (usz edge = 0; edge < edge_count; edge++) {
        long left_value = input[3 + 2 * edge], right_value = input[4 + 2 * edge];
        if (left_value < 0 || right_value < 0 || (ulong)left_value >= (ulong)vertices || (ulong)right_value >= (ulong)vertices) return -1;
        usz left = (usz)left_value, right = (usz)right_value;
        adjacency[left] |= 1ul << (ulong)right;
        adjacency[right] |= 1ul << (ulong)left;
    }
    bool[MAX_VERTICES] visited;
    usz[MAX_VERTICES] queue, order;
    for (usz i = 0; i < MAX_VERTICES; i++) visited[i] = false;
    usz head = 0, tail = 0, count = 0;
    visited[0] = true;
    queue[tail++] = 0;
    while (head < tail) {
        usz vertex = queue[head++];
        order[count++] = vertex;
        for (usz neighbor = 0; neighbor < vertices; neighbor++) {
            if ((adjacency[vertex] & (1ul << (ulong)neighbor)) != 0ul && !visited[neighbor]) {
                visited[neighbor] = true;
                queue[tail++] = neighbor;
            }
        }
    }
    if (count != vertices) return -1;
    if (output == null || capacity < vertices * 8) return -2;
    for (usz i = 0; i < count; i++) put_i64(output, i, (long)order[i]);
    return (long)count;
}
