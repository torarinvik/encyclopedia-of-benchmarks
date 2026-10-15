module auto_correlation;

fn void store_i64_le(char* output, usz position, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[position + byte] = (char)(bits & 0xff);
        bits >>= 8;
    }
}

fn long auto_correlation(long* values, usz length, char* output, usz output_capacity) @export("auto_correlation") {
    if (values == null || length < 2 || length > 65) return -1;
    long raw_count = values[0];
    if (raw_count < 1 || raw_count > 64) return -1;
    usz count = (usz)raw_count;
    if (length != count + 1) return -1;
    for (usz i = 0; i < count; i += 1) {
        if (values[i + 1] < -1000000 || values[i + 1] > 1000000) return -1;
    }
    usz result_count = 2 * count - 1;
    usz byte_count = 8 * result_count;
    if (output == null || output_capacity < byte_count) return -2;

    usz y_start = count;
    for (usz index = 0; index < result_count; index += 1) {
        if (index < count) y_start -= 1;
        usz k_min = index >= count - 1 ? index - (count - 1) : 0;
        usz k_max = index < count ? index : count - 1;
        usz offset = 0;
        long sum = 0;
        for (usz k = k_min; k <= k_max; k += 1) {
            sum += values[k + 1] * values[y_start + offset + 1];
            offset += 1;
        }
        store_i64_le(output, index * 8, sum);
    }
    return (long)byte_count;
}
