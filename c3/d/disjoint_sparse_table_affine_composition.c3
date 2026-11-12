module disjoint_sparse_table_affine_composition;

const long MODULUS = 1000000007;
const usz MAX_N = 32;
const usz MAX_Q = 32;
const usz MAX_LEVELS = 5;
const usz MAX_INPUT = 130;

struct Affine { long a; long b; }

fn Affine combine(Affine left, Affine right) {
    return {
        .a = (right.a * left.a) % MODULUS,
        .b = (right.a * left.b + right.b) % MODULUS,
    };
}

fn void put_word(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long disjoint_sparse_table_affine_composition(long* input, usz length,
    char* output, usz capacity) @export("disjoint_sparse_table_affine_composition") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || q_value < 1 || q_value > (long)MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != 2 + 2 * n + 2 * q) return -1;

    Affine[MAX_N] maps = zeroed;
    long[MAX_Q] left = zeroed, right = zeroed;
    usz cursor = 2;
    for (usz index = 0; index < n; index++) {
        long a = input[cursor], b = input[cursor + 1];
        cursor += 2;
        if (a < 0 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;
        maps[index] = {.a = a, .b = b};
    }
    for (usz query = 0; query < q; query++) {
        long lo = input[cursor], hi = input[cursor + 1];
        cursor += 2;
        if (lo < 0 || lo > hi || hi >= n_value) return -1;
        left[query] = lo;
        right[query] = hi;
    }
    usz output_bytes = q * 16;
    if (output == null || capacity < output_bytes) return -2;

    Affine[MAX_LEVELS][MAX_N] table = zeroed;
    usz levels = 0, span = 1;
    while (span < n) { levels++; span *= 2; }
    for (usz level = 0; level < levels; level++) {
        usz half = (usz)1 << level, width = half * 2;
        for (usz start = 0; start < n; start += width) {
            usz middle = start + half, ending = start + width;
            if (middle > n) middle = n;
            if (ending > n) ending = n;
            if (middle > start) {
                table[level][middle - 1] = maps[middle - 1];
                usz index = middle - 1;
                while (index > start) {
                    table[level][index - 1] = combine(maps[index - 1], table[level][index]);
                    index--;
                }
            }
            if (middle < ending) {
                table[level][middle] = maps[middle];
                for (usz index = middle + 1; index < ending; index++)
                    table[level][index] = combine(table[level][index - 1], maps[index]);
            }
        }
    }
    for (usz query = 0; query < q; query++) {
        Affine answer;
        usz lo = (usz)left[query], hi = (usz)right[query];
        if (lo == hi) answer = maps[lo];
        else {
            usz difference = lo ^ hi, level = 0;
            while (difference > 1) { difference >>= 1; level++; }
            answer = combine(table[level][lo], table[level][hi]);
        }
        put_word(output, query * 16, answer.a);
        put_word(output, query * 16 + 8, answer.b);
    }
    return (long)output_bytes;
}
