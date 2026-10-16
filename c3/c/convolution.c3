module convolution;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long convolution(long* values, usz length, char* output, usz capacity) @export("convolution") {
    if (values == null || length < 4 || length > 130) return -1;
    long raw_a_count = values[0];
    long raw_b_count = values[1];
    if (raw_a_count < 1 || raw_a_count > 64 || raw_b_count < 1 || raw_b_count > 64) return -1;
    usz a_count = (usz)raw_a_count, b_count = (usz)raw_b_count;
    if (length != a_count + b_count + 2) return -1;
    for (usz j = 0; j < a_count + b_count; j += 1) if (values[j + 2] < -1000000 || values[j + 2] > 1000000) return -1;
    usz result_count = a_count + b_count - 1;
    usz byte_count = result_count * 8;
    if (output == null || capacity < byte_count) return -2;
    for (usz i = 0; i < result_count; i += 1) {
        usz k_start = i >= b_count - 1 ? i - (b_count - 1) : 0;
        usz k_end = i < a_count ? i : a_count - 1;
        long sum = 0;
        for (usz k = k_start; k <= k_end; k += 1) sum += values[k + 2] * values[a_count + (i - k) + 2];
        store_i64_le(output, i * 8, sum);
    }
    return (long)byte_count;
}
