const MAX_LENGTH: usize = 1024;
fn asciiSpace(c: i64) bool { return c == 9 or c == 10 or c == 11 or c == 12 or c == 13 or c == 32; }
export fn validate_email(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_LENGTH + 1 or values[0] < 1 or values[0] > MAX_LENGTH or @as(usize,@intCast(values[0])) + 1 != length) return -1;
    var finish: usize = @intCast(values[0]);
    for (0..finish) |i| if (values[i+1] < 0 or values[i+1] > 127) return -1;
    var at = finish;
    for (0..finish) |i| {
        const c = values[i+1];
        if (asciiSpace(c)) return 0;
        if (c == 64) { if (at != finish) return 0; at = i; }
    }
    if (at == 0 or at >= finish - 1) return 0;
    var i = at + 2;
    while (i + 1 < finish) : (i += 1) if (values[i+1] == 46) return 1;
    return 0;
}
