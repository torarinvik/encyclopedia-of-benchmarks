module versabench_dbms_valid_attributes;

fn long key_float_bits_valid(long payload) {
    if (payload < 0 || (ulong)payload > 0xffffffff) return -1;
    uint bits = (uint)payload;
    uint exponent = (bits >> 23) & 0xff;
    uint fraction = bits & 0x7fffff;
    if (exponent == 0xff && fraction == 0) return 0;
    return 1;
}

fn long versabench_dbms_valid_attributes(long* values, usz length) @export("versabench_dbms_valid_attributes") {
    if (values == null || length < 1 || length > 104) return -1;
    long raw_count = values[0];
    if (raw_count < 0 || raw_count > 51 || length != 1 + 2 * (usz)raw_count) return -1;
    for (usz i = 0; i < (usz)raw_count; i++) {
        long code = values[1+2*i]; long payload = values[2+2*i];
        if (code < 0 || code > 50) return 0;
        if (code < 8) {
            long valid = key_float_bits_valid(payload);
            if (valid < 0) return -1;
            if (valid == 0) return 0;
        } else {
            if (payload != 0 && payload != 1) return -1;
            if (payload == 0) return 0;
        }
    }
    return 1;
}
