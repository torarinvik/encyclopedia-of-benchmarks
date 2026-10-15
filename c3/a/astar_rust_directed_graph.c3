module astar_rust_directed_graph;

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long astar_rust_directed_graph(long* input, usz length, char* output, usz capacity) @export("astar_rust_directed_graph") {
    if (input == null || length < 4) return -1;
    long vertices = input[0], edge_count = input[1];
    if (vertices < 1 || vertices > 32 || edge_count < 0 || edge_count > 128) return -1;
    if (length != 4 + (usz)vertices + 3 * (usz)edge_count) return -1;
    long start = input[2], goal = input[3];
    if (start < 0 || start >= vertices || goal < 0 || goal >= vertices) return -1;
    for (long v = 0; v < vertices; v++) if (input[4+v] < 0 || input[4+v] > 1000000) return -1;
    if (input[4+goal] != 0) return -1;
    usz edge_base = 4 + (usz)vertices;
    for (long e = 0; e < edge_count; e++) {
        long from = input[edge_base+3*e], to = input[edge_base+3*e+1], weight = input[edge_base+3*e+2];
        if (from < 0 || from >= vertices || to < 0 || to >= vertices || weight < 0 || weight > 1000000 || input[4+from] > weight + input[4+to]) return -1;
    }
    long distance[32], parent[32]; bool closed[32] = zeroed;
    for (long v = 0; v < vertices; v++) { distance[v] = 0x7fffffffffffffff; parent[v] = -1; closed[v] = false; }
    distance[start] = 0;
    for (long step = 0; step < vertices; step++) {
        long current = -1;
        for (long v = 0; v < vertices; v++) {
            if (closed[v] || distance[v] == 0x7fffffffffffffff) continue;
            if (current < 0 || distance[v]+input[4+v] < distance[current]+input[4+current] ||
                (distance[v]+input[4+v] == distance[current]+input[4+current] && (distance[v] < distance[current] || (distance[v] == distance[current] && v < current)))) current = v;
        }
        if (current < 0 || current == goal) break;
        closed[current] = true;
        for (long e = 0; e < edge_count; e++) if (input[edge_base+3*e] == current) {
            long next = input[edge_base+3*e+1], candidate = distance[current] + input[edge_base+3*e+2];
            if (!closed[next] && candidate < distance[next]) { distance[next] = candidate; parent[next] = current; }
        }
    }
    if (distance[goal] == 0x7fffffffffffffff) return 0;
    long reversed[32], path_length = 0, current = goal;
    while (path_length < vertices) {
        reversed[path_length++] = current;
        if (current == start) break;
        current = parent[current]; if (current < 0) return -1;
    }
    if (reversed[path_length-1] != start) return -1;
    usz required = 8 * ((usz)path_length + 2);
    if (output == null || capacity < required) return -2;
    put_i64_le(output,0,distance[goal]); put_i64_le(output,8,path_length);
    for (long i = 0; i < path_length; i++) put_i64_le(output,16+(usz)i*8,reversed[path_length-1-i]);
    return (long)required;
}
