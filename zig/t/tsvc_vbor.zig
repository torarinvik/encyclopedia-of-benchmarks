const max_n: usize = 128;

export fn tsvc_vbor(values_opt: ?[*]const i64, length: usize) i64 {
    if (values_opt == null or length < 7 or length > 1 + 6 * max_n) return -1;
    const values = values_opt.?;
    const n_value = values[0];
    if (n_value < 1 or n_value > @as(i64, @intCast(max_n))) return -1;
    const n: usize = @intCast(n_value);
    if (length != 1 + 6 * n) return -1;
    for (1..length) |index| {
        if (values[index] < 0 or values[index] > 2) return -1;
    }

    var checksum: i64 = 0;
    for (0..n) |i| {
        const a = values[1 + i];
        const b = values[1 + n + i];
        const c = values[1 + 2 * n + i];
        const d = values[1 + 3 * n + i];
        const e = values[1 + 4 * n + i];
        const f = values[1 + 5 * n + i];
        const a1 = a*b*c + a*b*d + a*b*e + a*b*f + a*c*d + a*c*e + a*c*f + a*d*e + a*d*f + a*e*f;
        const b1 = b*c*d + b*c*e + b*c*f + b*d*e + b*d*f + b*e*f;
        const c1 = c*d*e + c*d*f + c*e*f;
        const d1 = d*e*f;
        checksum += a1*b1*c1*d1;
    }
    return checksum;
}
