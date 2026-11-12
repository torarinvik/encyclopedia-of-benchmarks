module counting_c4;

const usz MAX_VERTICES = 8;
const usz MAX_EDGES = 12;
const usz MAX_INPUT_LENGTH = 26;
const usz MAX_OUTPUT_BYTES = 96;

fn long counting_c4(long* input, usz length, uint8* output, usz output_capacity)
        @export("counting_c4") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    long m_value = input[1];
    if (n_value < 2 || n_value > 8 || m_value < 1 || m_value > 12) return -1;
    usz n = (usz)n_value;
    usz edge_count = (usz)m_value;
    if (length != 2 + 2 * edge_count) return -1;

    long[8][8] multiplicity = zeroed;
    for (usz edge = 0; edge < edge_count; edge++) {
        long u_value = input[2 + 2 * edge];
        long v_value = input[3 + 2 * edge];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value)
            return -1;
        usz u = (usz)u_value;
        usz v = (usz)v_value;
        multiplicity[u][v]++;
        multiplicity[v][u]++;
    }

    ulong[12] answers = zeroed;
    for (usz edge = 0; edge < edge_count; edge++) {
        usz u = (usz)input[2 + 2 * edge];
        usz v = (usz)input[3 + 2 * edge];
        for (usz a = 0; a < n; a++) {
            if (a == u || a == v) continue;
            for (usz b = 0; b < n; b++) {
                if (b == u || b == v || b == a) continue;
                answers[edge] += (ulong)(multiplicity[u][a] * multiplicity[a][b] * multiplicity[b][v]);
            }
        }
    }

    usz bytes = 8 * edge_count;
    if (output == null || output_capacity < bytes) return -2;
    uint8[96] staged = zeroed;
    for (usz edge = 0; edge < edge_count; edge++)
        for (usz byte = 0; byte < 8; byte++)
            staged[8 * edge + byte] = (uint8)(answers[edge] >> (8 * byte));
    for (usz byte = 0; byte < bytes; byte++) output[byte] = staged[byte];
    return (long)bytes;
}
