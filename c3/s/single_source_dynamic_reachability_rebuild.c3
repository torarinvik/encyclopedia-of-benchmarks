module single_source_dynamic_reachability_rebuild;

const usz MAX_N = 8;
const usz MAX_INITIAL_EDGES = 16;
const usz MAX_OPERATIONS = 20;
const usz MAX_INPUT = 97;
const usz MAX_OUTPUT_BYTES = 168;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn void rebuild_reachable(usz n, usz source, bool[MAX_N][MAX_N]* adjacency, bool[MAX_N]* reachable) {
    usz[MAX_N] queue;
    usz head = 0, tail = 0;
    for (usz i = 0; i < n; i += 1) (*reachable)[i] = false;
    (*reachable)[source] = true;
    queue[tail] = source; tail += 1;
    while (head < tail) {
        usz u = queue[head]; head += 1;
        for (usz v = 0; v < n; v += 1) {
            if ((*adjacency)[u][v] && !(*reachable)[v]) {
                (*reachable)[v] = true;
                queue[tail] = v; tail += 1;
            }
        }
    }
}

long single_source_dynamic_reachability_rebuild(long* input, usz length, char* output, usz capacity)
        @export("single_source_dynamic_reachability_rebuild") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long n_raw = input[0], source_raw = input[1], edge_count_raw = input[2];
    if (n_raw < 2 || n_raw > MAX_N.long() || source_raw < 0 || source_raw >= n_raw ||
            edge_count_raw < 0 || edge_count_raw > MAX_INITIAL_EDGES.long()) return -1;
    usz n = n_raw.usz(), source = source_raw.usz(), edge_count = edge_count_raw.usz();
    usz operation_count_offset = 3 + 2 * edge_count;
    if (length <= operation_count_offset) return -1;
    long operation_count_raw = input[operation_count_offset];
    if (operation_count_raw < 0 || operation_count_raw > MAX_OPERATIONS.long() ||
            length != operation_count_offset + 1 + 3 * operation_count_raw.usz()) return -1;
    usz operation_count = operation_count_raw.usz();

    bool[MAX_N][MAX_N] adjacency = zeroed;
    usz cursor = 3;
    for (usz i = 0; i < edge_count; i += 1) {
        long u_raw = input[cursor], v_raw = input[cursor + 1]; cursor += 2;
        if (u_raw < 0 || u_raw >= n_raw || v_raw < 0 || v_raw >= n_raw) return -1;
        usz u = u_raw.usz(), v = v_raw.usz();
        if (adjacency[u][v]) return -1;
        adjacency[u][v] = true;
    }
    cursor = operation_count_offset + 1;
    usz[MAX_OPERATIONS] op_type, op_u, op_v;
    usz query_count = 0;
    for (usz i = 0; i < operation_count; i += 1) {
        long kind = input[cursor], u = input[cursor + 1], v = input[cursor + 2]; cursor += 3;
        if (kind == 0 || kind == 1) {
            if (u < 0 || u >= n_raw || v < 0 || v >= n_raw) return -1;
        } else if (kind == 2) {
            if (u < 0 || u >= n_raw || v != 0) return -1;
            query_count += 1;
        } else return -1;
        op_type[i] = kind.usz(); op_u[i] = u.usz(); op_v[i] = v.usz();
    }

    usz output_bytes = 8 * (1 + query_count);
    if (output == null || capacity < output_bytes) return -2;
    bool[MAX_N] reachable = zeroed;
    long[MAX_OPERATIONS] answers = zeroed;
    usz answer_count = 0;
    rebuild_reachable(n, source, &adjacency, &reachable);
    for (usz i = 0; i < operation_count; i += 1) {
        if (op_type[i] == 0) {
            adjacency[op_u[i]][op_v[i]] = true;
            rebuild_reachable(n, source, &adjacency, &reachable);
        } else if (op_type[i] == 1) {
            adjacency[op_u[i]][op_v[i]] = false;
            rebuild_reachable(n, source, &adjacency, &reachable);
        } else {
            answers[answer_count] = if reachable[op_u[i]] then 1 else 0;
            answer_count += 1;
        }
    }
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    store_i64_le(&staged[0], 0, answer_count.long());
    for (usz i = 0; i < answer_count; i += 1) store_i64_le(&staged[0], 8 * (i + 1), answers[i]);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return output_bytes.long();
}
