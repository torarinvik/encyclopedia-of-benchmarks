// Clean-room port of TSVC s424; see package README for provenance and rights.
const MIN_N: usize = 66;
const MAX_N: usize = 192;
const X_LENGTH: usize = MAX_N + 63;
const MAX_INPUT_LENGTH: usize = MAX_N + 64;

export fn tsvc_s424_alias_overlap_feedback(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < MIN_N + 64 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < @as(i64, @intCast(MIN_N)) or values[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(values[0]);
    if (length != n + 64) return -1;
    var a = [_]i64{0} ** MAX_N;
    var x = [_]i64{0} ** X_LENGTH;
    for (0..n) |i| {
        a[i] = values[1 + i];
        if (a[i] < 0 or a[i] > 10) return -1;
    }
    for (0..63) |i| {
        x[i] = values[1 + n + i];
        if (x[i] < 0 or x[i] > 10) return -1;
    }
    // x[63..] is zero-filled like the source's xx view before the sweep.
    for (0..n - 1) |i| x[i + 64] = x[i] + a[i];
    var checksum: i64 = 0;
    for (0..n) |i| checksum += x[63 + i];
    return checksum;
}
