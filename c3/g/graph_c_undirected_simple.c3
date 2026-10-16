module graph_c_undirected_simple;

const usz MAX_VERTICES = 32;
const usz MAX_EDGES = 2047;

fn void put_i64(char* output, usz slot, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[slot * 8 + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long graph_c_undirected_simple(long* input, usz length, char* output, usz capacity)
    @export("graph_c_undirected_simple") {
    if (input == null || length < 2) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_VERTICES || input[1] < 0 || input[1] > (long)MAX_EDGES) return -1;
    usz vertices = (usz)input[0], edge_count = (usz)input[1];
    if (length != 2 + 2 * edge_count) return -1;

    bool[MAX_VERTICES * MAX_VERTICES] adjacency;
    for (usz i = 0; i < MAX_VERTICES * MAX_VERTICES; i++) adjacency[i] = false;
    for (usz edge = 0; edge < edge_count; edge++) {
        long left_value = input[2 + 2 * edge], right_value = input[3 + 2 * edge];
        if (left_value < 0 || right_value < 0 || (ulong)left_value >= (ulong)vertices || (ulong)right_value >= (ulong)vertices) return -1;
        usz left = (usz)left_value, right = (usz)right_value;
        adjacency[left * vertices + right] = true;
        adjacency[right * vertices + left] = true;
    }
    usz count = vertices * vertices;
    if (output == null || capacity < count * 8) return -2;
    for (usz row = 0; row < vertices; row++) {
        for (usz column = 0; column < vertices; column++)
            put_i64(output, row * vertices + column, adjacency[row * vertices + column] ? 1 : 0);
    }
    return (long)(count * 8);
}
