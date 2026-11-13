module dirichlet_convolution_and_prefix_sums;

const long MODULUS = 998244353;
const usz MAX_N = 64, MAX_Q = 15, MAX_PARSEABLE = 32;

fn long prefix_value(long* quotients, long* prefix, usz count, long value) {
    if (value == 0) return 0;
    for (usz i = 0; i < count; i += 1)
        if (quotients[i] == value) return prefix[i];
    return 0;
}

fn void store_le(char* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long dirichlet_convolution_and_prefix_sums(long* input, usz length,
        char* output, usz output_capacity)
    @export("dirichlet_convolution_and_prefix_sums") {
    if (input == null || length < 3 || length > MAX_PARSEABLE) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N) return -1;
    long n = input[0];
    long[MAX_Q] descending = zeroed;
    usz count = 0;
    for (long left = 1; left <= n;) {
        long value = n / left;
        descending[count++] = value;
        left = n / value + 1;
    }
    long[MAX_Q] quotients = zeroed;
    for (usz i = 0; i < count; i += 1) quotients[i] = descending[count - 1 - i];
    if (length != 1 + 2 * count) return -1;

    long[MAX_Q] f = zeroed, g = zeroed, result = zeroed;
    for (usz i = 0; i < count; i += 1) {
        f[i] = input[1 + i];
        g[i] = input[1 + count + i];
        if (f[i] < 1 || f[i] >= MODULUS || g[i] < 1 || g[i] >= MODULUS) return -1;
    }
    usz needed = 8 * count;
    if (output == null || output_capacity < needed) return -2;

    for (usz out = 0; out < count; out += 1) {
        long x = quotients[out], total = 0;
        for (long left = 1; left <= x;) {
            long quotient = x / left;
            long right = x / quotient;
            long below = x / (quotient + 1);
            long interval = (prefix_value(&quotients[0], &f[0], count, right)
                    - prefix_value(&quotients[0], &f[0], count, below)) % MODULUS;
            if (interval < 0) interval += MODULUS;
            usz q_index = 0;
            while (q_index < count && quotients[q_index] != quotient) q_index += 1;
            if (q_index == count) return -1;
            total = (total + interval * g[q_index]) % MODULUS;
            left = right + 1;
        }
        result[out] = total;
    }
    for (usz i = 0; i < count; i += 1) store_le(output + 8 * i, result[i]);
    return (long)needed;
}
