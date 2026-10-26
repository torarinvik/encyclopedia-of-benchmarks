module gbbs_five_cycle_count;

const usz MAX_N = 16;
const usz MAX_M = 64;
const usz MAX_INPUT = 130;

fn void store_i64_le(char* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

// Clean-room bounded GBBS five-cycle profile; see package LICENSE.txt.
long gbbs_five_cycle_count(long* input, usz length, char* output, usz capacity)
        @export("gbbs_five_cycle_count") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > (long)MAX_N || m64 < 0 || m64 > (long)MAX_M) return -1;
    usz n = (usz)n64, m = (usz)m64;
    if (length != 2 + 2 * m) return -1;
    bool[MAX_N * MAX_N] adjacent = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        usz u = (usz)u64, v = (usz)v64;
        if (adjacent[u * MAX_N + v]) return -1;
        adjacent[u * MAX_N + v] = true;
        adjacent[v * MAX_N + u] = true;
    }
    if (output == null || capacity < 8) return -2;

    long count = 0;
    for (usz start = 0; start < n; start += 1) {
        for (usz first = start + 1; first < n; first += 1) {
            for (usz second = start + 1; second < n; second += 1) {
                if (second == first) continue;
                for (usz third = start + 1; third < n; third += 1) {
                    if (third == first || third == second) continue;
                    for (usz last = first + 1; last < n; last += 1) {
                        if (last == second || last == third) continue;
                        if (adjacent[start * MAX_N + first] && adjacent[first * MAX_N + second] &&
                            adjacent[second * MAX_N + third] && adjacent[third * MAX_N + last] &&
                            adjacent[last * MAX_N + start]) count += 1;
                    }
                }
            }
        }
    }
    store_i64_le(output, count);
    return 8;
}
