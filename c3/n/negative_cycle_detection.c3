// Clean-room negative-cycle detection and witness extraction.
module negative_cycle_detection;
const usz MAX_N = 20;
const usz MAX_M = 64;
const usz MAX_INPUT = 2 + 3 * MAX_M;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long negative_cycle_detection(long* input, usz length, char* output, usz capacity)
        @export("negative_cycle_detection") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > 20 || m64 < 0 || m64 > 64) return -1;
    usz n = (usz)n64, m = (usz)m64;
    if (length != 2 + 3 * m) return -1;
    long[MAX_M] edge_from = zeroed, edge_to = zeroed, weight = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[2 + 3 * edge], v64 = input[3 + 3 * edge], w = input[4 + 3 * edge];
        if (u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || w < -1000 || w > 1000) return -1;
        edge_from[edge] = u64; edge_to[edge] = v64; weight[edge] = w;
    }
    long[MAX_N] distance = zeroed, predecessor = zeroed;
    for (usz v = 0; v < n; v += 1) predecessor[v] = -1;
    long changed_vertex = -1;
    for (usz pass = 0; pass < n; pass += 1) {
        changed_vertex = -1;
        for (usz edge = 0; edge < m; edge += 1) {
            usz u = (usz)edge_from[edge], v = (usz)edge_to[edge];
            long candidate = distance[u] + weight[edge];
            if (candidate < distance[v]) { distance[v] = candidate; predecessor[v] = (long)u; changed_vertex = (long)v; }
        }
        if (changed_vertex < 0) break;
    }
    long[MAX_N + 2] record = zeroed;
    usz record_length = 1;
    if (changed_vertex >= 0) {
        usz vertex = (usz)changed_vertex;
        for (usz step = 0; step < n; step += 1) {
            if (predecessor[vertex] < 0) return -1;
            vertex = (usz)predecessor[vertex];
        }
        usz start = vertex;
        usz[MAX_N] cycle = zeroed;
        usz cycle_length = 0;
        while (true) {
            if (cycle_length >= n || predecessor[vertex] < 0) return -1;
            cycle[cycle_length] = vertex; cycle_length += 1;
            vertex = (usz)predecessor[vertex];
            if (vertex == start) break;
        }
        usz left = 0, right = cycle_length - 1;
        while (left < right) { usz temporary = cycle[left]; cycle[left] = cycle[right]; cycle[right] = temporary; left += 1; right -= 1; }
        usz minimum = 0;
        for (usz i = 1; i < cycle_length; i += 1) if (cycle[i] < cycle[minimum]) minimum = i;
        record[0] = 1; record[1] = (long)cycle_length;
        for (usz i = 0; i < cycle_length; i += 1) record[2 + i] = (long)cycle[(minimum + i) % cycle_length];
        record_length = cycle_length + 2;
    } else record[0] = 0;
    usz output_length = 8 * record_length;
    if (output == null || capacity < output_length) return -2;
    for (usz i = 0; i < record_length; i += 1) store_i64_le(output, 8 * i, record[i]);
    return (long)output_length;
}
