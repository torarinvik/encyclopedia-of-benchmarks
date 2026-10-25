module versabench_dbms_valid_index_key;

fn bool binary32_ge(uint a, uint b) {
    uint exp_a = (a >> 23) & 0xff; uint frac_a = a & 0x7fffff;
    uint exp_b = (b >> 23) & 0xff; uint frac_b = b & 0x7fffff;
    if ((exp_a == 0xff && frac_a != 0) || (exp_b == 0xff && frac_b != 0)) return false;
    uint mag_a = a & 0x7fffffff; uint mag_b = b & 0x7fffffff;
    if (mag_a == 0 && mag_b == 0) return true;
    bool neg_a = (a >> 31) != 0; bool neg_b = (b >> 31) != 0;
    if (neg_a != neg_b) return !neg_a;
    if (neg_a) return mag_a <= mag_b;
    return mag_a >= mag_b;
}

fn long versabench_dbms_valid_index_key(long* values, usz length) @export("versabench_dbms_valid_index_key") {
    if (values == null || length < 1 || length > 9 || length != 8) return -1;
    uint[8] bits;
    for (usz i = 0; i < 8; i++) {
        if (values[i] < 0 || (ulong)values[i] > 0xffffffff) return -1;
        bits[i] = (uint)values[i];
    }
    for (usz d = 0; d < 4; d++) if (binary32_ge(bits[d], bits[4+d])) return 0;
    return 1;
}
