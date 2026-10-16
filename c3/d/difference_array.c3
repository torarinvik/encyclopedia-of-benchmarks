module difference_array;

fn void put_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long difference_array(long* input, usz length, char* output, usz capacity) @export("difference_array") {
    if (input == null || length < 2) return -1;
    long raw_n = input[0];
    long raw_q = input[1];
    if (raw_n < 1 || raw_n > 64 || raw_q < 0 || raw_q > 64) return -1;
    usz n = (usz)raw_n, q = (usz)raw_q;
    if (length != 2 + n + 3*q) return -1;
    for (usz i = 0; i < n; i += 1) if (input[2+i] < -1000000 || input[2+i] > 1000000) return -1;
    for (usz u = 0; u < q; u += 1) {
        usz base = 2 + n + 3*u;
        if (input[base] < 0 || input[base] >= raw_n || input[base+1] < input[base] || input[base+1] >= raw_n ||
            input[base+2] < -1000000 || input[base+2] > 1000000) return -1;
    }
    usz bytes = n * 8;
    if (output == null || capacity < bytes) return -2;
    long[65] diff;
    diff[0] = input[2];
    for (usz i = 1; i < n; i += 1) diff[i] = input[2+i] - input[2+i-1];
    for (usz u = 0; u < q; u += 1) {
        usz base = 2 + n + 3*u;
        usz left = (usz)input[base], right = (usz)input[base+1];
        long delta = input[base+2];
        diff[left] += delta;
        diff[right+1] -= delta;
    }
    long current = diff[0];
    put_i64_le(current, output, 0);
    for (usz i = 1; i < n; i += 1) { current += diff[i]; put_i64_le(current, output, i*8); }
    return (long)bytes;
}
