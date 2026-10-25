// Clean-room port of TSVC s258; see package README for provenance and rights.
const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 257;

export fn tsvc_s258_wrapped_scalar_expansion(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 5 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 1 + 4 * n) return -1;
    const c_start = 1 + n;
    const d_start = 1 + 2 * n;
    const aa_start = 1 + 3 * n;
    var a = [_]i64{0} ** MAX_N;
    var c = [_]i64{0} ** MAX_N;
    var d = [_]i64{0} ** MAX_N;
    var aa0 = [_]i64{0} ** MAX_N;
    var b = [_]i64{0} ** MAX_N;
    var e = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        a[i] = values[1 + i];
        c[i] = values[c_start + i];
        d[i] = values[d_start + i];
        aa0[i] = values[aa_start + i];
        if (a[i] < 0 or a[i] > 2 or c[i] < 0 or c[i] > 2 or
            d[i] < 0 or d[i] > 2 or aa0[i] < 0 or aa0[i] > 2) return -1;
    }
    var s: i64 = 0;
    for (0..n) |i| {
        if (a[i] > 0) s = d[i] * d[i];
        b[i] = s * c[i] + d[i];
        e[i] = (s + 1) * aa0[i];
    }
    var sum_b: i64 = 0;
    var sum_e: i64 = 0;
    for (0..n) |i| {
        sum_b += b[i];
        sum_e += e[i];
    }
    return sum_b + sum_e;
}
