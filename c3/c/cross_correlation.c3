module cross_correlation;

fn void store_i64_le(char* output, usz position, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[position + byte] = (char)(bits & 0xff);
        bits >>= 8;
    }
}

fn long cross_correlation(long* values, usz length, char* output, usz output_capacity) @export("cross_correlation") {
    if (values == null || length < 4 || length > 66) return -1;
    long raw_x_count = values[0];
    long raw_y_count = values[1];
    if (raw_x_count < 1 || raw_x_count > 32 || raw_y_count < 1 || raw_y_count > 32) return -1;
    usz x_count = (usz)raw_x_count;
    usz y_count = (usz)raw_y_count;
    if (length != x_count + y_count + 2) return -1;
    for (usz i = 0; i < x_count + y_count; i += 1) {
        if (values[i + 2] < -1000000 || values[i + 2] > 1000000) return -1;
    }
    usz result_count = x_count + y_count - 1;
    usz byte_count = 8 * result_count;
    if (output == null || output_capacity < byte_count) return -2;

    usz y_start = y_count;
    for (usz index = 0; index < result_count; index += 1) {
        if (index < y_count) y_start -= 1;
        usz k_min = index >= y_count - 1 ? index - (y_count - 1) : 0;
        usz k_max = index < x_count ? index : x_count - 1;
        long sum = 0;
        for (usz k = k_min; k <= k_max; k += 1) {
            usz y_index = y_start + (k - k_min);
            sum += values[k + 2] * values[x_count + y_index + 2];
        }
        store_i64_le(output, index * 8, sum);
    }
    return (long)byte_count;
}
