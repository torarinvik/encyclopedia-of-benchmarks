fn binary32Ge(a: u32, b: u32) bool {
    const exp_a = (a >> 23) & 0xff; const frac_a = a & 0x7f_ffff;
    const exp_b = (b >> 23) & 0xff; const frac_b = b & 0x7f_ffff;
    if ((exp_a == 0xff and frac_a != 0) or (exp_b == 0xff and frac_b != 0)) return false;
    const mag_a = a & 0x7fff_ffff; const mag_b = b & 0x7fff_ffff;
    if (mag_a == 0 and mag_b == 0) return true;
    const neg_a = (a >> 31) != 0; const neg_b = (b >> 31) != 0;
    if (neg_a != neg_b) return !neg_a;
    return if (neg_a) mag_a <= mag_b else mag_a >= mag_b;
}

export fn versabench_dbms_valid_index_key(raw: ?[*]const i64, length: usize) i64 {
    if (raw == null or length < 1 or length > 9 or length != 8) return -1;
    const values = raw.?[0..length];
    var bits: [8]u32 = undefined;
    for (0..8) |i| {
        if (values[i] < 0 or values[i] > 0xffff_ffff) return -1;
        bits[i] = @intCast(values[i]);
    }
    for (0..4) |d| if (binary32Ge(bits[d], bits[4+d])) return 0;
    return 1;
}
