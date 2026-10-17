module minimum_spanning_tree_prims;

const usz MAX_VERTICES = 16;
const usz MAX_EDGES = 64;
const usz MAX_PARSEABLE_INPUT_LENGTH = 2 + 3 * MAX_EDGES + 1;
const usz MAX_OUTPUT_WORDS = 1 + 2 * (MAX_VERTICES - 1);
const usz MAX_OUTPUT_BYTES = 4 * MAX_OUTPUT_WORDS;
const long SOURCE_HEAP_SENTINEL = 9223372036854775807L;

fn void top_to_bottom(long* heap, int* positions, int* node_position, usz size, usz start) {
    usz root = start;
    while (root * 2 + 1 < size) {
        usz left = root * 2 + 1;
        usz right = left + 1;
        usz child = right >= size || heap[left] < heap[right] ? left : right;
        if (heap[child] >= heap[root]) break;
        long heap_value = heap[root];
        heap[root] = heap[child];
        heap[child] = heap_value;
        int vertex = positions[root];
        positions[root] = positions[child];
        positions[child] = vertex;
        node_position[(usz)positions[root]] = (int)root;
        node_position[(usz)positions[child]] = (int)child;
        root = child;
    }
}

fn void decrease_key(long value, usz index, long* heap, int* positions, int* node_position) {
    int vertex = positions[index];
    while (index != 0) {
        usz parent = (index - 1) / 2;
        if (value < heap[parent]) {
            heap[index] = heap[parent];
            positions[index] = positions[parent];
            node_position[(usz)positions[parent]] = (int)index;
        } else {
            heap[index] = value;
            positions[index] = vertex;
            node_position[(usz)vertex] = (int)index;
            return;
        }
        index = parent;
    }
    heap[0] = value;
    positions[0] = vertex;
    node_position[(usz)vertex] = 0;
}

fn void put_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long minimum_spanning_tree_prims(int* input, usz length, char* output, usz capacity)
        @export("minimum_spanning_tree_prims") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    int raw_vertices = input[0], raw_edges = input[1];
    if (raw_vertices < 1 || raw_vertices > (int)MAX_VERTICES ||
        raw_edges < 0 || raw_edges > (int)MAX_EDGES) return -1;
    usz vertex_count = (usz)raw_vertices, edge_count = (usz)raw_edges;
    if (length != 2 + 3 * edge_count) return -1;

    int[MAX_VERTICES * MAX_VERTICES] neighbors = zeroed;
    int[MAX_VERTICES * MAX_VERTICES] weights = zeroed;
    int[MAX_VERTICES] degree = zeroed;
    bool[MAX_VERTICES * MAX_VERTICES] seen = zeroed;
    for (usz index = 0; index < edge_count; index += 1) {
        usz offset = 2 + 3 * index;
        int u = input[offset], v = input[offset + 1], weight = input[offset + 2];
        if (u < 0 || v <= u || v >= raw_vertices) return -1;
        usz edge_index = (usz)u * MAX_VERTICES + (usz)v;
        if (seen[edge_index]) return -1;
        seen[edge_index] = true;
        usz u_degree = (usz)degree[(usz)u]++;
        neighbors[(usz)u * MAX_VERTICES + u_degree] = v;
        weights[(usz)u * MAX_VERTICES + u_degree] = weight;
        usz v_degree = (usz)degree[(usz)v]++;
        neighbors[(usz)v * MAX_VERTICES + v_degree] = u;
        weights[(usz)v * MAX_VERTICES + v_degree] = weight;
    }

    if (vertex_count > 1) {
        bool[MAX_VERTICES] reached_vertex = zeroed;
        int[MAX_VERTICES] stack = zeroed;
        usz stack_size = 1, reached = 0;
        stack[0] = 0;
        reached_vertex[0] = true;
        while (stack_size > 0) {
            stack_size -= 1;
            usz vertex = (usz)stack[stack_size];
            reached += 1;
            for (usz i = 0; i < (usz)degree[vertex]; i += 1) {
                usz neighbor = (usz)neighbors[vertex * MAX_VERTICES + i];
                if (!reached_vertex[neighbor]) {
                    reached_vertex[neighbor] = true;
                    stack[stack_size] = (int)neighbor;
                    stack_size += 1;
                }
            }
        }
        if (reached != vertex_count) return -1;
    }

    bool[MAX_VERTICES] visited = zeroed;
    int[MAX_VERTICES] parent = zeroed;
    long[MAX_VERTICES] heap;
    int[MAX_VERTICES] positions, node_position;
    for (usz vertex = 0; vertex < vertex_count; vertex += 1) {
        parent[vertex] = -1;
        heap[vertex] = SOURCE_HEAP_SENTINEL;
        positions[vertex] = (int)vertex;
        node_position[vertex] = (int)vertex;
    }
    visited[0] = true;
    for (usz i = 0; i < (usz)degree[0]; i += 1) {
        usz neighbor = (usz)neighbors[i];
        parent[neighbor] = 0;
        heap[neighbor] = (long)weights[i];
    }
    usz start = vertex_count / 2;
    while (start > 0) {
        start -= 1;
        top_to_bottom(&heap[0], &positions[0], &node_position[0], vertex_count, start);
    }

    int[MAX_OUTPUT_WORDS] words = zeroed;
    usz word_count = 1, tree_edge_count = 0;
    for (usz step = 1; step < vertex_count; step += 1) {
        int vertex_raw = positions[0];
        usz vertex = (usz)vertex_raw;
        heap[0] = SOURCE_HEAP_SENTINEL;
        top_to_bottom(&heap[0], &positions[0], &node_position[0], vertex_count, 0);
        if (!visited[vertex]) {
            words[word_count] = parent[vertex];
            words[word_count + 1] = vertex_raw;
            word_count += 2;
            tree_edge_count += 1;
            visited[vertex] = true;
            for (usz i = 0; i < (usz)degree[vertex]; i += 1) {
                usz neighbor = (usz)neighbors[vertex * MAX_VERTICES + i];
                int weight = weights[vertex * MAX_VERTICES + i];
                if (!visited[neighbor]) {
                    usz heap_index = (usz)node_position[neighbor];
                    if ((long)weight < heap[heap_index]) {
                        heap[heap_index] = (long)weight;
                        decrease_key((long)weight, heap_index, &heap[0], &positions[0], &node_position[0]);
                        parent[neighbor] = vertex_raw;
                    }
                }
            }
        }
    }
    if (tree_edge_count != vertex_count - 1) return -1;
    words[0] = (int)tree_edge_count;
    usz bytes = word_count * 4;
    if (bytes > MAX_OUTPUT_BYTES || output == null || capacity < bytes) return -2;
    char[MAX_OUTPUT_BYTES] buffer = zeroed;
    for (usz i = 0; i < word_count; i += 1) put_i32_le(&buffer[0], i * 4, words[i]);
    for (usz i = 0; i < bytes; i += 1) output[i] = buffer[i];
    return (long)bytes;
}
