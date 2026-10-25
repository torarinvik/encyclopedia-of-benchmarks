module versabench_dbms_keys_union;

fn void write_i64_le(u8* output, usz index, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[index * 8 + b] = (u8)((bits >> (8 * b)) & 255);
}

fn long versabench_dbms_keys_union(long* values, usz length, u8* output, usz output_capacity) @export("versabench_dbms_keys_union") {
    if (values == null || length < 1 || length > 130) return -1;
    long raw_count = values[0];
    if (raw_count < 1 || raw_count > 16 || length != 1 + 8 * (usz)raw_count) return -1;
    long[8] bounds;
    for (usz d = 0; d < 4; d++) { bounds[d] = values[1+d]; bounds[4+d] = values[5+d]; }
    for (usz i = 0; i < (usz)raw_count; i++) {
        usz at = 1 + 8 * i;
        for (usz d = 0; d < 4; d++) {
            long lo = values[at+d]; long hi = values[at+4+d];
            if (lo < -8 || lo > 8 || hi < -8 || hi > 8 || lo > hi) return -1;
            if (lo < bounds[d]) bounds[d] = lo;
            if (hi > bounds[4+d]) bounds[4+d] = hi;
        }
    }
    if (output == null || output_capacity < 64) return -2;
    for (usz i = 0; i < 8; i++) write_i64_le(output, i, bounds[i]);
    return 64;
}
