module submodular_ranking_greedy;

const usz MAX_N = 5;
const usz MAX_M = 4;
const usz MAX_SUBSETS = 32;
const usz MAX_INPUT = 131;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b += 1) { output[offset + b] = (char)(bits & 255); bits >>= 8; }
}

long submodular_ranking_greedy(long* input, usz length, char* output, usz capacity)
        @export("submodular_ranking_greedy") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > 5 || m64 < 1 || m64 > 4) return -1;
    usz n = n64.usz(), m = m64.usz(), size = 1 << n;
    if (length != 2 + m * size) return -1;
    long[MAX_M][MAX_SUBSETS] f = zeroed;
    for (usz i = 0; i < m; i += 1) {
        for (usz a = 0; a < size; a += 1) {
            long v = input[2 + i * size + a];
            if (v < 0 || v > 8) return -1;
            f[i][a] = v;
        }
        if (f[i][0] != 0 || f[i][size - 1] != 8) return -1;
        for (usz a = 0; a < size; a += 1) for (usz bit = 0; bit < n; bit += 1) {
            usz e = 1 << bit;
            if ((a & e) == 0 && f[i][a] > f[i][a | e]) return -1;
        }
        for (usz a = 0; a < size; a += 1) for (usz b = 0; b < size; b += 1) {
            if ((a & b) != a) continue;
            for (usz bit = 0; bit < n; bit += 1) {
                usz e = 1 << bit;
                if ((b & e) == 0 && f[i][a | e] - f[i][a] < f[i][b | e] - f[i][b]) return -1;
            }
        }
    }
    usz out_bytes = 8 * (1 + n + m);
    if (output == null || capacity < out_bytes) return -2;
    usz[MAX_N] order = zeroed, mask = 0;
    long[MAX_M] times = zeroed;
    long total = 0;
    for (usz t = 1; t <= n; t += 1) {
        usz winner = 0;
        long best_num = -1, best_den = 1;
        for (usz e = 0; e < n; e += 1) {
            usz bit = 1 << e;
            if ((mask & bit) != 0) continue;
            long num = 0, den = 1;
            for (usz i = 0; i < m; i += 1) {
                long cur = f[i][mask];
                if (cur == 8) continue;
                long d = 8 - cur, gain = f[i][mask | bit] - cur;
                num = num * d + gain * den;
                den *= d;
            }
            if (best_num < 0 || num * best_den > best_num * den) {
                winner = e; best_num = num; best_den = den;
            }
        }
        mask |= 1 << winner;
        order[t - 1] = winner;
        for (usz i = 0; i < m; i += 1) if (times[i] == 0 && f[i][mask] == 8) {
            times[i] = t.long(); total += t.long();
        }
    }
    store_i64_le(output, 0, total);
    for (usz j = 0; j < n; j += 1) store_i64_le(output, 8 * (1 + j), order[j].long());
    for (usz i = 0; i < m; i += 1) store_i64_le(output, 8 * (1 + n + i), times[i]);
    return out_bytes.long();
}
