module d_esopo_pape;

const usz MAX_VERTICES = 16;
const usz MAX_EDGES = 64;
const usz MAX_INPUT_LENGTH = 3 + 3 * MAX_EDGES;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long d_esopo_pape(long* values, usz length, char* output, usz output_capacity)
    @export("d_esopo_pape") {
    if (values == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long raw_n = values[0];
    long raw_m = values[1];
    long raw_source = values[2];
    if (raw_n < 1 || raw_n > (long)MAX_VERTICES || raw_m < 0 ||
        raw_m > (long)MAX_EDGES || raw_source < 0 || raw_source >= raw_n ||
        length != 3 + 3 * (usz)raw_m) return -1;

    usz n = (usz)raw_n;
    usz m = (usz)raw_m;
    long[MAX_VERTICES] head;
    long[MAX_EDGES] to;
    long[MAX_EDGES] next;
    long[MAX_EDGES] weight;
    for (usz vertex = 0; vertex < n; vertex += 1) head[vertex] = -1;
    for (usz edge = 0; edge < m; edge += 1) {
        long u = values[3 + 3 * edge];
        long v = values[4 + 3 * edge];
        long w = values[5 + 3 * edge];
        if (u < 0 || u >= raw_n || v < 0 || v >= raw_n || w < 0 || w > 1000) return -1;
        to[edge] = v;
        weight[edge] = w;
        next[edge] = head[(usz)u];
        head[(usz)u] = (long)edge;
    }

    long[MAX_VERTICES] distance;
    bool[MAX_VERTICES] reachable = zeroed;
    bool[MAX_VERTICES] queued = zeroed;
    bool[MAX_VERTICES] removed_before = zeroed;
    long[MAX_VERTICES] deque;
    usz front = 0;
    usz size = 1;
    usz source = (usz)raw_source;
    deque[0] = (long)source;
    distance[source] = 0;
    reachable[source] = true;
    queued[source] = true;
    while (size > 0) {
        long vertex_value = deque[front];
        usz vertex = (usz)vertex_value;
        front = (front + 1) % n;
        size -= 1;
        queued[vertex] = false;
        removed_before[vertex] = true;
        long edge = head[vertex];
        while (edge >= 0) {
            usz edge_index = (usz)edge;
            usz neighbor = (usz)to[edge_index];
            long candidate = distance[vertex] + weight[edge_index];
            if (!reachable[neighbor] || candidate < distance[neighbor]) {
                distance[neighbor] = candidate;
                reachable[neighbor] = true;
                if (!queued[neighbor]) {
                    if (removed_before[neighbor]) {
                        front = (front + n - 1) % n;
                        deque[front] = (long)neighbor;
                    } else {
                        deque[(front + size) % n] = (long)neighbor;
                    }
                    size += 1;
                    queued[neighbor] = true;
                }
            }
            edge = next[edge_index];
        }
    }

    usz byte_count = 8 * n;
    if (output == null || output_capacity < byte_count) return -2;
    for (usz vertex = 0; vertex < n; vertex += 1)
        store_i64_le(output, 8 * vertex, reachable[vertex] ? distance[vertex] : -1);
    return (long)byte_count;
}
