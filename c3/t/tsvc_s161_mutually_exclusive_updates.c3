module tsvc_s161_mutually_exclusive_updates;

const usz MAX_N = 64;
const usz MAX_INPUT_LENGTH = 1 + 5 * MAX_N;
const long MAX_VALUE = 2;

fn bool bounded_value(long value) {
    return value >= -MAX_VALUE && value <= MAX_VALUE;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tsvc_s161_mutually_exclusive_updates(long* input, usz length, char* output,
        usz output_capacity) @export("tsvc_s161_mutually_exclusive_updates") {
    if (input == null || length < 11 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0];
    if (n_raw < 2 || n_raw > (long)MAX_N) return -1;
    usz n = (usz)n_raw;
    if (length != 1 + 5 * n) return -1;

    usz a_start = 1, b_start = a_start + n, c_start = b_start + n;
    usz d_start = c_start + n, e_start = d_start + n;
    long[MAX_N] a, c;
    for (usz i = 0; i < n; i += 1) {
        a[i] = input[a_start + i];
        c[i] = input[c_start + i];
        if (!bounded_value(a[i]) || !bounded_value(input[b_start + i]) ||
            !bounded_value(c[i]) || !bounded_value(input[d_start + i]) ||
            !bounded_value(input[e_start + i])) return -1;
    }
    if (output == null || output_capacity < 16 * n) return -2;

    for (usz i = 0; i + 1 < n; i += 1) {
        if (input[b_start + i] < 0) {
            long d = input[d_start + i];
            c[i + 1] = a[i] + d * d;
        } else {
            a[i] = c[i] + input[d_start + i] * input[e_start + i];
        }
    }
    for (usz i = 0; i < n; i += 1) {
        store_i64_le(output, 8 * i, a[i]);
        store_i64_le(output, 8 * (n + i), c[i]);
    }
    return (long)(2 * n);
}
