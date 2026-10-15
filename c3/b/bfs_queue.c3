module bfs_queue;

const usz MAX_VERTEX_COUNT = 64;
const usz MAX_EDGE_COUNT = 2046;
const usz MAX_INPUT_LENGTH = 4 + 2 * MAX_EDGE_COUNT;

fn long bfs_queue(long* input, usz length, char* output, usz output_capacity)
    @export("bfs_queue") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH || input[0] < 1 ||
        input[0] > (long)MAX_VERTEX_COUNT || input[3] < 0 || input[3] > (long)MAX_EDGE_COUNT) return -1;
    usz vertex_count = (usz)input[0];
    long source_arg = input[1];
    long target_arg = input[2];
    usz edge_count = (usz)input[3];
    if (source_arg < 0 || source_arg >= (long)vertex_count || target_arg < 0 ||
        target_arg >= (long)vertex_count || length != 4 + 2 * edge_count) return -1;

    ulong[MAX_VERTEX_COUNT] adjacency;
    for (usz vertex = 0; vertex < vertex_count; vertex++) adjacency[vertex] = 0ul;
    for (usz edge = 0; edge < edge_count; edge++) {
        long left_arg = input[4 + 2 * edge];
        long right_arg = input[5 + 2 * edge];
        if (left_arg < 0 || right_arg < 0 || left_arg >= (long)vertex_count ||
            right_arg >= (long)vertex_count) return -1;
        usz left = (usz)left_arg;
        usz right = (usz)right_arg;
        adjacency[left] |= 1ul << (ulong)right;
        adjacency[right] |= 1ul << (ulong)left;
    }

    usz source = (usz)source_arg;
    usz target = (usz)target_arg;
    long[MAX_VERTEX_COUNT] predecessor;
    bool[MAX_VERTEX_COUNT] visited;
    usz[MAX_VERTEX_COUNT] queue;
    for (usz vertex = 0; vertex < vertex_count; vertex++) {
        predecessor[vertex] = -1;
        visited[vertex] = false;
    }
    predecessor[source] = (long)source;
    visited[source] = true;
    usz head = 0;
    usz tail = 1;
    queue[0] = source;
    bool found = source == target;
    while (head < tail && !found) {
        usz current = queue[head];
        head++;
        for (usz neighbor = 0; neighbor < vertex_count; neighbor++) {
            if ((adjacency[current] & (1ul << (ulong)neighbor)) == 0ul || visited[neighbor]) continue;
            visited[neighbor] = true;
            predecessor[neighbor] = (long)current;
            if (neighbor == target) { found = true; break; }
            queue[tail] = neighbor;
            tail++;
        }
    }
    if (!found) {
        if (output_capacity < 1 || output == null) return -2;
        output[0] = 0;
        return 1;
    }

    char[MAX_VERTEX_COUNT] path;
    usz path_length = 0;
    usz current = target;
    while (current != source) {
        path[path_length] = (char)current;
        path_length++;
        current = (usz)predecessor[current];
    }
    path[path_length] = (char)source;
    path_length++;
    if (output_capacity < path_length + 1 || output == null) return -2;
    output[0] = 1;
    for (usz index = 0; index < path_length; index++) output[index + 1] = path[index];
    return (long)(path_length + 1);
}
