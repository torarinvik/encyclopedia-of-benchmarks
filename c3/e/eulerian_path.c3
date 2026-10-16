module eulerian_path;

const usz MAX_VERTICES = 32;
const usz MAX_EDGES = 256;

fn void put_i64(char* output, usz byte_offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[byte_offset + byte] = (char)(bits >> (8 * byte));
}

// Construct a directed Eulerian path with iterative Hierholzer traversal.
fn long eulerian_path(long* input, usz length, char* output, usz capacity) @export("eulerian_path") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > (long)MAX_VERTICES ||
        input[1] < 0 || input[1] > (long)MAX_EDGES) return -1;
    usz vertices = (usz)input[0];
    usz edges = (usz)input[1];
    if (length != 2 + 2 * edges) return -1;

    long[MAX_VERTICES][MAX_EDGES] adjacency = zeroed;
    usz[MAX_VERTICES] in_degree = zeroed;
    usz[MAX_VERTICES] out_degree = zeroed;
    for (usz edge = 0; edge < edges; edge++) {
        long source = input[2 + 2 * edge];
        long destination = input[3 + 2 * edge];
        if (source < 0 || source >= (long)vertices || destination < 0 || destination >= (long)vertices) return -1;
        adjacency[(usz)source][out_degree[(usz)source]] = destination;
        out_degree[(usz)source]++;
        in_degree[(usz)destination]++;
    }
    if (edges == 0) return 0;

    usz start = 0;
    usz start_count = 0;
    usz end_count = 0;
    for (usz vertex = 0; vertex < vertices; vertex++) {
        long difference = (long)out_degree[vertex] - (long)in_degree[vertex];
        if (difference == 1) { start = vertex; start_count++; }
        else if (difference == -1) end_count++;
        else if (difference != 0) return 0;
    }
    if (!((start_count == 0 && end_count == 0) || (start_count == 1 && end_count == 1))) return 0;
    if (start_count == 0) {
        while (start < vertices && out_degree[start] == 0) start++;
        if (start == vertices) return 0;
    }

    usz[MAX_VERTICES] remaining;
    for (usz vertex = 0; vertex < vertices; vertex++) remaining[vertex] = out_degree[vertex];
    usz[MAX_EDGES + 1] stack;
    usz[MAX_EDGES + 1] reverse_path;
    usz top = 1;
    usz path_count = 0;
    stack[0] = start;
    while (top > 0) {
        usz current = stack[top - 1];
        if (remaining[current] > 0) {
            remaining[current]--;
            stack[top] = (usz)adjacency[current][remaining[current]];
            top++;
        } else {
            top--;
            reverse_path[path_count] = stack[top];
            path_count++;
        }
    }
    if (path_count != edges + 1) return 0;
    usz bytes = path_count * 8;
    if (output == null || capacity < bytes) return -2;
    for (usz index = 0; index < path_count; index++) put_i64(output, index * 8, (long)reverse_path[path_count - index - 1]);
    return (long)bytes;
}
