module prufer_code;

const int MAX_VERTICES = 64;
const int MAX_OUTPUT_BYTES = 1016;

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long make_code(long* input, usz n, long* code) {
    bool[MAX_VERTICES * MAX_VERTICES] adjacency = {};
    long[MAX_VERTICES] degree = {};
    for (usz edge = 0; edge + 1 < n; edge++) {
        long raw_u = input[2 + edge * 2], raw_v = input[3 + edge * 2];
        if (raw_u < 0 || raw_v < 0 || raw_u >= (long)n || raw_v >= (long)n || raw_u == raw_v) return -1;
        usz u = (usz)raw_u, v = (usz)raw_v;
        if (adjacency[u * MAX_VERTICES + v]) return -1;
        adjacency[u * MAX_VERTICES + v] = true;
        adjacency[v * MAX_VERTICES + u] = true;
        degree[u] += 1; degree[v] += 1;
    }
    bool[MAX_VERTICES] visited = {};
    long[MAX_VERTICES] queue = {};
    usz head = 0, tail = 0;
    visited[0] = true; queue[tail++] = 0;
    while (head < tail) {
        usz u = (usz)queue[head++];
        for (usz v = 0; v < n; v++) {
            if (adjacency[u * MAX_VERTICES + v] && !visited[v]) { visited[v] = true; queue[tail++] = (long)v; }
        }
    }
    if (tail != n) return -1;
    bool[MAX_VERTICES] active = {};
    for (usz v = 0; v < n; v++) active[v] = true;
    usz code_length = 0;
    for (usz step = 0; step + 2 < n; step++) {
        long leaf = -1;
        for (usz v = n; v > 0; v--) { usz candidate = v - 1; if (active[candidate] && degree[candidate] == 1) { leaf = (long)candidate; break; } }
        if (leaf < 0) return -1;
        usz neighbor = n;
        for (usz v = 0; v < n; v++) if (active[v] && adjacency[(usz)leaf * MAX_VERTICES + v]) { neighbor = v; break; }
        if (neighbor == n) return -1;
        code[code_length++] = (long)neighbor;
        active[(usz)leaf] = false;
        adjacency[(usz)leaf * MAX_VERTICES + neighbor] = false;
        adjacency[neighbor * MAX_VERTICES + (usz)leaf] = false;
        degree[neighbor] -= 1;
    }
    return (long)code_length;
}

fn void add_edge(long* edges, usz index, usz u, usz v) {
    if (u < v) { edges[index * 2] = (long)u; edges[index * 2 + 1] = (long)v; }
    else { edges[index * 2] = (long)v; edges[index * 2 + 1] = (long)u; }
}

fn long make_decoded_edges(long* input, usz n, long* edges) {
    long[MAX_VERTICES] remaining = {};
    for (usz i = 0; i + 2 < n; i++) {
        long raw = input[2 + i];
        if (raw < 0 || raw >= (long)n) return -1;
        remaining[(usz)raw] += 1;
    }
    bool[MAX_VERTICES] active = {};
    for (usz v = 0; v < n; v++) active[v] = true;
    usz edge_count = 0;
    for (usz i = 0; i + 2 < n; i++) {
        usz leaf = n;
        for (usz v = n; v > 0; v--) { usz candidate = v - 1; if (active[candidate] && remaining[candidate] == 0) { leaf = candidate; break; } }
        if (leaf == n) return -1;
        usz vertex = (usz)input[2 + i];
        add_edge(edges, edge_count++, leaf, vertex);
        active[leaf] = false;
        remaining[vertex] -= 1;
    }
    usz first = n;
    for (usz v = n; v > 0; v--) if (active[v - 1]) { first = v - 1; break; }
    if (first == n) return -1;
    active[first] = false;
    usz second = n;
    for (usz v = n; v > 0; v--) if (active[v - 1]) { second = v - 1; break; }
    if (second == n) return -1;
    add_edge(edges, edge_count++, first, second);
    for (usz i = 1; i < edge_count; i++) {
        long u = edges[i * 2], v = edges[i * 2 + 1];
        usz j = i;
        while (j > 0 && (edges[(j - 1) * 2] > u || (edges[(j - 1) * 2] == u && edges[(j - 1) * 2 + 1] > v))) {
            edges[j * 2] = edges[(j - 1) * 2]; edges[j * 2 + 1] = edges[(j - 1) * 2 + 1]; j--;
        }
        edges[j * 2] = u; edges[j * 2 + 1] = v;
    }
    return (long)edge_count;
}

fn long prufer_code(long* input, usz length, char* output, usz capacity) @export("prufer_code") {
    if (input == null || length < 2 || length > 129) return -1;
    long mode = input[0], raw_n = input[1];
    if (raw_n < 1 || raw_n > MAX_VERTICES || (mode != 0 && mode != 1)) return -1;
    usz n = (usz)raw_n;
    if (mode == 0) {
        if (length != n * 2) return -1;
        long[MAX_VERTICES] code = {};
        long code_length = make_code(input, n, &code[0]);
        if (code_length < 0) return -1;
        usz needed = (usz)code_length * 8;
        if (needed == 0) return 0;
        if (output == null || capacity < needed) return -2;
        for (long i = 0; i < code_length; i++) write_i64_le(output, (usz)i * 8, code[(usz)i]);
        return (long)needed;
    }
    if (n < 2 || length != n) return -1;
    long[MAX_VERTICES * 2] edges = {};
    long edge_count = make_decoded_edges(input, n, &edges[0]);
    if (edge_count < 0) return -1;
    usz needed = 8 + (usz)edge_count * 16;
    if (needed > MAX_OUTPUT_BYTES) return -1;
    if (output == null || capacity < needed) return -2;
    write_i64_le(output, 0, edge_count);
    for (long i = 0; i < edge_count; i++) {
        write_i64_le(output, 8 + (usz)i * 16, edges[(usz)i * 2]);
        write_i64_le(output, 16 + (usz)i * 16, edges[(usz)i * 2 + 1]);
    }
    return (long)needed;
}
