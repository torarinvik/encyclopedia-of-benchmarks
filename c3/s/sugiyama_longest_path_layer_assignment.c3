module sugiyama_longest_path_layer_assignment;

const usz MAX_N = 32;
const usz MAX_M = 128;
const usz MAX_INPUT = 258;
const usz MAX_OUTPUT = 264;

fn void put_i64_le(u8* output, usz word, u64 value) {
    for (usz byte = 0; byte < 8; byte++) {
        output[word * 8 + byte] = (u8)(value >> (byte * 8));
    }
}

fn long sugiyama_longest_path_layer_assignment(long* input, usz length,
        u8* output, usz capacity) @export("sugiyama_longest_path_layer_assignment") {
    if (input == null || length < 2 || length > MAX_INPUT + 1) return -1;
    long n_value = input[0], m_value = input[1];
    if (n_value < 0 || n_value > 32 || m_value < 0 || m_value > 128) return -1;
    usz n = (usz)n_value, m = (usz)m_value;
    if (length != 2 + 2 * m) return -1;

    u32[32] adjacency = zeroed;
    for (usz edge = 0; edge < m; edge++) {
        long source = input[2 + 2 * edge], target = input[3 + 2 * edge];
        if (source < 0 || source >= n_value || target < 0 || target >= n_value) return -1;
        u32 bit = 1u32 << (usz)target;
        if ((adjacency[(usz)source] & bit) != 0) return -1;
        adjacency[(usz)source] |= bit;
    }

    bool[32] removed = zeroed;
    usz[32] sink_depth = zeroed;
    usz remaining = n, depth = 0;
    while (remaining > 0) {
        bool[32] sinks = zeroed;
        usz sink_count = 0;
        for (usz vertex = 0; vertex < n; vertex++) {
            if (removed[vertex]) continue;
            bool has_remaining_successor = false;
            for (usz target = 0; target < n; target++) {
                if (!removed[target] && (adjacency[vertex] & (1u32 << target)) != 0) {
                    has_remaining_successor = true;
                    break;
                }
            }
            if (!has_remaining_successor) { sinks[vertex] = true; sink_count++; }
        }
        if (sink_count == 0) return -1;
        for (usz vertex = 0; vertex < n; vertex++) {
            if (sinks[vertex]) { removed[vertex] = true; sink_depth[vertex] = depth; }
        }
        remaining -= sink_count;
        depth++;
    }

    usz output_bytes = 8 * (n + 1);
    if (output == null || capacity < output_bytes) return -2;
    put_i64_le(output, 0, (u64)depth);
    for (usz vertex = 0; vertex < n; vertex++) {
        put_i64_le(output, vertex + 1, (u64)(depth - 1 - sink_depth[vertex]));
    }
    return (long)output_bytes;
}
