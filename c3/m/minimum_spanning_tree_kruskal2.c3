module minimum_spanning_tree_kruskal2;

const usz MAX_VERTICES = 16;
const usz MAX_EDGES = 64;
const usz MAX_INPUT_WORDS = 194;
const usz MAX_OUTPUT_WORDS = 1 + 3 * (MAX_VERTICES - 1);
const usz MAX_OUTPUT_BYTES = 4 * MAX_OUTPUT_WORDS;

struct Edge { int u; int v; int weight; }

fn int find_root(int* parent, int node) {
    int current = node;
    while (parent[current] != current) {
        parent[current] = parent[parent[current]];
        current = parent[current];
    }
    return current;
}

fn void put_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long minimum_spanning_tree_kruskal2(int* input, usz length, char* output, usz capacity)
        @export("minimum_spanning_tree_kruskal2") {
    if (input == null || length < 2 || length > MAX_INPUT_WORDS) return -1;
    int vertex_count = input[0], edge_count = input[1];
    if (vertex_count < 1 || vertex_count > 16 || edge_count < 0 || edge_count > 64 ||
        length != 2 + 3 * (usz)edge_count) return -1;

    Edge[64] input_edges;
    bool[256] seen = zeroed;
    usz pos = 2;
    for (int i = 0; i < edge_count; i += 1) {
        int u = input[pos++], v = input[pos++], weight = input[pos++];
        if (u < 0 || v <= u || v >= vertex_count) return -1;
        usz seen_index = (usz)u * MAX_VERTICES + (usz)v;
        if (seen[seen_index]) return -1;
        seen[seen_index] = true;
        input_edges[i] = Edge{u, v, weight};
    }

    bool[16] visited = zeroed;
    int[16] stack;
    usz stack_size = 1, reached = 0;
    stack[0] = 0;
    visited[0] = true;
    while (stack_size > 0) {
        stack_size -= 1;
        int node = stack[stack_size];
        reached += 1;
        for (int neighbor = 0; neighbor < vertex_count; neighbor += 1) {
            usz a = (usz)node * MAX_VERTICES + (usz)neighbor;
            usz b = (usz)neighbor * MAX_VERTICES + (usz)node;
            if ((seen[a] || seen[b]) && !visited[neighbor]) {
                visited[neighbor] = true;
                stack[stack_size++] = neighbor;
            }
        }
    }
    if (reached != (usz)vertex_count) return -1;

    Edge[64] ordered;
    usz ordered_count = 0;
    for (int u = 0; u < vertex_count; u += 1)
        for (int i = 0; i < edge_count; i += 1)
            if (input_edges[i].u == u) ordered[ordered_count++] = input_edges[i];
    for (usz i = 1; i < ordered_count; i += 1) {
        Edge key = ordered[i];
        usz j = i;
        while (j > 0 && ordered[j - 1].weight > key.weight) {
            ordered[j] = ordered[j - 1];
            j -= 1;
        }
        ordered[j] = key;
    }

    int[16] parent;
    int[16] rank = zeroed;
    for (int i = 0; i < vertex_count; i += 1) parent[i] = i;
    int[46] words = zeroed;
    usz word_count = 1, accepted = 0;
    for (usz i = 0; i < ordered_count && accepted < (usz)(vertex_count - 1); i += 1) {
        int root_u = find_root(&parent[0], ordered[i].u);
        int root_v = find_root(&parent[0], ordered[i].v);
        if (root_u == root_v) continue;
        if (rank[root_u] < rank[root_v]) parent[root_u] = root_v;
        else if (rank[root_u] > rank[root_v]) parent[root_v] = root_u;
        else { parent[root_u] = root_v; rank[root_v] += 1; }
        words[word_count++] = ordered[i].u;
        words[word_count++] = ordered[i].v;
        words[word_count++] = ordered[i].weight;
        accepted += 1;
    }
    if (accepted != (usz)(vertex_count - 1)) return -1;
    words[0] = (int)accepted;
    usz bytes = word_count * 4;
    if (output == null || capacity < bytes) return -2;
    char[184] buffer;
    for (usz i = 0; i < word_count; i += 1) put_i32_le(&buffer[0], i * 4, words[i]);
    for (usz i = 0; i < bytes; i += 1) output[i] = buffer[i];
    return (long)bytes;
}
