const MAX_ATTRIBUTES: usize = 51;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_ATTRIBUTES;

fn keyFloatBitsValid(payload: i64) i64 {
    if (payload < 0 or payload > 0xffff_ffff) return -1;
    const bits: u32 = @intCast(payload);
    const exponent = (bits >> 23) & 0xff;
    const fraction = bits & 0x7f_ffff;
    return if (exponent == 0xff and fraction == 0) 0 else 1;
}

export fn versabench_dbms_valid_attributes(raw: ?[*]const i64, length: usize) i64 {
    if (raw == null or length < 1 or length > MAX_INPUT_LENGTH + 1) return -1;
    const values = raw.?[0..length];
    const raw_count = values[0];
    if (raw_count < 0 or raw_count > @as(i64, MAX_ATTRIBUTES) or length != 1 + 2 * @as(usize, @intCast(raw_count))) return -1;
    for (0..@as(usize, @intCast(raw_count))) |i| {
        const code = values[1 + 2*i]; const payload = values[2 + 2*i];
        if (code < 0 or code > 50) return 0;
        if (code < 8) {
            const valid = keyFloatBitsValid(payload);
            if (valid < 0) return -1;
            if (valid == 0) return 0;
        } else {
            if (payload != 0 and payload != 1) return -1;
            if (payload == 0) return 0;
        }
    }
    return 1;
}
