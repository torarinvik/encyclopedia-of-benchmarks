module weighted_greedy_set_cover;
const usz MAX_N = 16; const usz MAX_M = 16; const usz MAX_INPUT = 34; const usz MAX_OUTPUT = 136;

fn void put64(char* output, usz position, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[position + byte] = (char)(bits & 255); bits >>= 8; }
}
fn usz bit_count(ulong value) {
    usz count = 0;
    while (value != 0) { value &= value - 1; count += 1; }
    return count;
}

long weighted_greedy_set_cover(long* input, usz length, char* output, usz capacity) @export("weighted_greedy_set_cover") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > (long)MAX_N || m64 < 1 || m64 > (long)MAX_M || length != 2 + 2 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64;
    ulong full = (1UL << n) - 1, union_mask = 0;
    long[MAX_M] weight = zeroed;
    ulong[MAX_M] mask = zeroed;
    for (usz set = 0; set < m; set += 1) {
        weight[set] = input[2 + set];
        long mask_value = input[2 + m + set];
        if (weight[set] < 0 || weight[set] > 10000 || mask_value < 0 || (((ulong)mask_value & ~full) != 0)) return -1;
        mask[set] = (ulong)mask_value;
        union_mask |= mask[set];
    }
    if (union_mask != full) return -1;
    ulong covered = 0;
    usz[MAX_M] selected = zeroed;
    usz selected_count = 0;
    while (covered != full) {
        usz best = MAX_M, best_gain = 0;
        for (usz set = 0; set < m; set += 1) {
            usz gain = bit_count(mask[set] & ~covered);
            if (gain == 0) continue;
            if (best == MAX_M || weight[set] * (long)best_gain < weight[best] * (long)gain) {
                best = set; best_gain = gain;
            }
        }
        if (best == MAX_M) return -1;
        selected[selected_count] = best;
        selected_count += 1;
        covered |= mask[best];
    }
    usz output_bytes = 8 * (selected_count + 1);
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT] staged = zeroed;
    put64(&staged[0], 0, (long)selected_count);
    for (usz index = 0; index < selected_count; index += 1) put64(&staged[0], 8 * (index + 1), (long)selected[index]);
    for (usz index = 0; index < output_bytes; index += 1) output[index] = staged[index];
    return (long)output_bytes;
}
