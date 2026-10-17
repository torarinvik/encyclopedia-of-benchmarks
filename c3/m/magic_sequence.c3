module magic_sequence;

const usz MAX_N = 11;
const ulong FNV_OFFSET_BASIS = 14695981039346656037;
const ulong FNV_PRIME = 1099511628211;
const ulong I64_RESULT_MASK = 0x7fffffffffffffff;

fn void fnv_byte(ulong* hash, uint8 value) {
    hash[0] = (hash[0] ^ (ulong)value) * FNV_PRIME;
}

fn uint enumerate(uint8 n, ulong* hash, bool hash_rows) {
    if (n == 0) return 1;

    uint8[MAX_N] vector = zeroed;
    uint8[MAX_N] frequencies = zeroed;
    uint8[MAX_N] next_candidate = zeroed;
    uint8[MAX_N + 1] prefix_sum = zeroed;
    usz depth = 0;
    uint solution_count = 0;

    while (true) {
        if (depth == (usz)n) {
            bool is_magic = true;
            for (usz symbol = 0; symbol < (usz)n; symbol++) {
                if (frequencies[symbol] != vector[symbol]) {
                    is_magic = false;
                    break;
                }
            }
            if (is_magic) {
                solution_count++;
                if (hash_rows) {
                    for (usz index = 0; index < (usz)n; index++) {
                        fnv_byte(hash, vector[index]);
                    }
                }
            }
            depth--;
            frequencies[(usz)vector[depth]]--;
            continue;
        }

        uint8 candidate = next_candidate[depth];
        if (candidate >= n) {
            next_candidate[depth] = 0;
            if (depth == 0) break;
            depth--;
            frequencies[(usz)vector[depth]]--;
            continue;
        }
        next_candidate[depth] = candidate + 1;
        usz sum = (usz)prefix_sum[depth] + (usz)candidate;
        if (sum > (usz)n) continue;

        vector[depth] = candidate;
        frequencies[(usz)candidate]++;
        prefix_sum[depth + 1] = (uint8)sum;
        depth++;
        next_candidate[depth] = 0;
    }
    return solution_count;
}

fn long magic_sequence(long* input, usz length) @export("magic_sequence") {
    if (input == null || length != 1 || input[0] < 0 || input[0] > (long)MAX_N) return -1;
    uint8 n = (uint8)input[0];

    ulong hash = FNV_OFFSET_BASIS;
    fnv_byte(&hash, n);
    uint solution_count = enumerate(n, &hash, false);
    for (uint shift = 0; shift < 32; shift += 8) {
        fnv_byte(&hash, (uint8)(solution_count >> shift));
    }
    enumerate(n, &hash, true);
    return (long)(hash & I64_RESULT_MASK);
}
