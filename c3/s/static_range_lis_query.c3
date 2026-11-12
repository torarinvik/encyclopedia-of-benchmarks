module static_range_lis_query;

const usz MAX_N = 128;
const usz MAX_Q = 32;

fn usz lower(long[MAX_N]* tails, usz count, long value) {
    usz lo = 0, hi = count;
    while (lo < hi) {
        usz mid = lo + (hi - lo) / 2;
        if (tails[mid] < value) lo = mid + 1; else hi = mid;
    }
    return lo;
}

fn void put64(uint8* output, usz offset, long value) {
    uint64 bits = (uint64)value;
    for (usz b = 0; b < 8; b += 1) output[offset + b] = (uint8)(bits >> (8 * b));
}

fn long static_range_lis_query(long* input, usz length, uint8* output, usz capacity)
    @export("static_range_lis_query") {
    if (input == null || length < 2 || length > 195) return -1;
    long n64 = input[0], q64 = input[1];
    if (n64 < 1 || n64 > 128 || q64 < 1 || q64 > 32) return -1;
    usz n = (usz)n64, q = (usz)q64;
    if (length != 2 + n + 2 * q) return -1;

    long[MAX_N] permutation, tails;
    long[MAX_Q] left, right, answers;
    bool[MAX_N] seen = zeroed;
    for (usz i = 0; i < n; i += 1) {
        long value = input[2 + i];
        if (value < 0 || value >= n64 || seen[(usz)value]) return -1;
        seen[(usz)value] = true;
        permutation[i] = value;
    }
    usz off = 2 + n;
    for (usz k = 0; k < q; k += 1) {
        left[k] = input[off]; right[k] = input[off + 1]; off += 2;
        if (left[k] < 0 || left[k] > right[k] || right[k] > n64) return -1;
    }
    for (usz k = 0; k < q; k += 1) {
        usz count = 0;
        for (usz i = (usz)left[k]; i < (usz)right[k]; i += 1) {
            usz at = lower(&tails, count, permutation[i]);
            tails[at] = permutation[i];
            if (at == count) count += 1;
        }
        answers[k] = (long)count;
    }
    usz bytes = 8 * q;
    if (output == null || capacity < bytes) return -2;
    for (usz k = 0; k < q; k += 1) put64(output, 8 * k, answers[k]);
    return (long)bytes;
}
