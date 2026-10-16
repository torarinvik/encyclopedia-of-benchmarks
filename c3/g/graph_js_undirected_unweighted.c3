module graph_js_undirected_unweighted;

const usz MAX_VERTICES = 26;
const usz MAX_EDGES = 256;
const usz MAX_DEGREE = 512;
const usz MAX_INPUT_LENGTH = 541;
const usz MAX_OUTPUT_VALUES = 645;
const usz MAX_QUEUE = 513;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn void dfs_visit(usz vertex, char* adjacency, usz* degree, bool* visited,
    long* result, usz* position, usz* count) {
    if (visited[vertex]) return;
    visited[vertex] = true;
    result[position[0]++] = (long)(97 + vertex);
    count[0] += 1;
    for (usz edge = 0; edge < degree[vertex]; edge += 1) {
        usz neighbor = (usz)adjacency[vertex * MAX_DEGREE + edge];
        dfs_visit(neighbor, adjacency, degree, visited, result, position, count);
    }
}

fn long graph_js_undirected_unweighted(long* input, usz length, char* output, usz capacity)
        @export("graph_js_undirected_unweighted") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_VERTICES) return -1;
    usz vertex_count = (usz)input[0];
    if (length < 1 + vertex_count + 2) return -1;

    char[MAX_VERTICES] vertices;
    bool[MAX_VERTICES] declared;
    for (usz index = 0; index < MAX_VERTICES; index += 1) declared[index] = false;
    for (usz index = 0; index < vertex_count; index += 1) {
        long value = input[1 + index];
        if (value < 97 || value > 122) return -1;
        usz vertex = (usz)(value - 97);
        if (declared[vertex]) return -1;
        declared[vertex] = true;
        vertices[index] = (char)vertex;
    }
    usz edge_count_offset = 1 + vertex_count;
    long raw_edge_count = input[edge_count_offset];
    if (raw_edge_count < 0 || raw_edge_count > (long)MAX_EDGES) return -1;
    usz edge_count = (usz)raw_edge_count;
    if (length != 1 + vertex_count + 1 + 2 * edge_count + 1) return -1;

    char[MAX_VERTICES][MAX_DEGREE] adjacency;
    usz[MAX_VERTICES] degree;
    for (usz index = 0; index < MAX_VERTICES; index += 1) degree[index] = 0;
    usz position = edge_count_offset + 1;
    for (usz edge = 0; edge < edge_count; edge += 1) {
        long left_value = input[position++], right_value = input[position++];
        if (left_value < 97 || left_value > 122 || right_value < 97 || right_value > 122) return -1;
        usz left = (usz)(left_value - 97), right = (usz)(right_value - 97);
        if (declared[left] && declared[right]) {
            if (degree[left] >= MAX_DEGREE || degree[right] >= MAX_DEGREE) return -1;
            adjacency[left][degree[left]++] = (char)right;
            adjacency[right][degree[right]++] = (char)left;
        }
    }
    long start_value = input[position];
    if (start_value < 97 || start_value > 122) return -1;
    usz start = (usz)(start_value - 97);
    if (!declared[start]) return -1;

    long[MAX_OUTPUT_VALUES] result;
    usz result_length = 0;
    result[result_length++] = (long)vertex_count;
    for (usz index = 0; index < vertex_count; index += 1) {
        usz vertex = (usz)vertices[index];
        result[result_length++] = (long)(97 + vertex);
        result[result_length++] = (long)degree[vertex];
        for (usz edge = 0; edge < degree[vertex]; edge += 1)
            result[result_length++] = (long)(97 + (usz)adjacency[vertex][edge]);
    }

    bool[MAX_VERTICES] visited;
    char[MAX_QUEUE] queue;
    char[MAX_QUEUE] levels;
    for (usz index = 0; index < MAX_VERTICES; index += 1) visited[index] = false;
    usz head = 0, tail = 0, bfs_count = 0;
    usz bfs_count_slot = result_length++;
    queue[tail] = (char)start; levels[tail++] = 0;
    while (head < tail) {
        usz vertex = (usz)queue[head];
        usz level = (usz)levels[head++];
        if (visited[vertex]) continue;
        visited[vertex] = true;
        result[result_length++] = (long)(97 + vertex);
        result[result_length++] = (long)level;
        bfs_count += 1;
        for (usz edge = 0; edge < degree[vertex]; edge += 1) {
            queue[tail] = adjacency[vertex][edge];
            levels[tail++] = (char)(level + 1);
        }
    }
    result[bfs_count_slot] = (long)bfs_count;

    for (usz index = 0; index < MAX_VERTICES; index += 1) visited[index] = false;
    usz dfs_count_slot = result_length++;
    usz dfs_count = 0;
    dfs_visit(start, &adjacency[0][0], &degree[0], &visited[0], &result[0], &result_length, &dfs_count);
    result[dfs_count_slot] = (long)dfs_count;

    usz output_bytes = result_length * 8;
    if (output == null || capacity < output_bytes) return -2;
    for (usz index = 0; index < result_length; index += 1) store_i64_le(output, index * 8, result[index]);
    return (long)output_bytes;
}
