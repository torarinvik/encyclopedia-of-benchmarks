module min_sum_set_cover_greedy;

const usz MAX_N = 12;
const usz MAX_M = 16;
const usz MAX_INPUT = 18;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long min_sum_set_cover_greedy(long* input, usz length, char* output, usz capacity)
        @export("min_sum_set_cover_greedy") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > (long)MAX_N || m64 < 1 || m64 > (long)MAX_M || length != 2 + (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64;
    ulong[MAX_M] masks = zeroed;
    for (usz set = 0; set < m; set += 1) {
        long mask = input[2 + set];
        if (mask <= 0 || (ulong)mask >= (1ul << n)) return -1;
        masks[set] = (ulong)mask;
    }
    usz output_bytes = 8 * (n + 1);
    if (output == null || capacity < output_bytes) return -2;
    bool[MAX_M] covered = zeroed;
    bool[MAX_N] used = zeroed;
    long[MAX_N] order = zeroed;
    long total_time = 0;
    for (usz slot = 1; slot <= n; slot += 1) {
        usz chosen = 0;
        long best_count = -1;
        for (usz element = 0; element < n; element += 1) {
            if (used[element]) continue;
            long count = 0;
            for (usz set = 0; set < m; set += 1)
                if (!covered[set] && (masks[set] & (1ul << element)) != 0) count += 1;
            if (count > best_count) { best_count = count; chosen = element; }
        }
        used[chosen] = true;
        order[slot - 1] = (long)chosen;
        for (usz set = 0; set < m; set += 1) {
            if (!covered[set] && (masks[set] & (1ul << chosen)) != 0) {
                covered[set] = true;
                total_time += (long)slot;
            }
        }
    }
    store_i64_le(output, 0, total_time);
    for (usz i = 0; i < n; i += 1) store_i64_le(output, 8 * (i + 1), order[i]);
    return (long)output_bytes;
}
