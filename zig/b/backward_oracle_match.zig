pub export fn backward_oracle_match(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or values[0] < 0 or values[0] > 4096 or values[1] < 0 or values[1] > 63) return -2;
    const n: usize = @intCast(values[0]);
    const m: usize = @intCast(values[1]);
    if (length != 2 + n + m) return -2;
    for (2..length) |i| { if (values[i] < 97 or values[i] > 122) return -2; }
    if (m == 0) return 0;
    if (m > n) return -1;
    var next: [64][26]i32 = @splat(@splat(-1));
    var suffix: [64]i32 = @splat(-1);
    for (0..m) |i| {
        const letter: usize = @intCast(values[2 + n + m - 1 - i] - 97);
        next[i][letter] = @intCast(i + 1);
        var k = suffix[i];
        while (k >= 0 and next[@intCast(k)][letter] < 0) {
            next[@intCast(k)][letter] = @intCast(i + 1);
            k = suffix[@intCast(k)];
        }
        suffix[i + 1] = if (k < 0) 0 else next[@intCast(k)][letter];
    }
    var start: usize = 0;
    while (start <= n - m) {
        var state: usize = 0;
        var remaining = m;
        var shift = m;
        while (remaining > 0) {
            remaining -= 1;
            const letter: usize = @intCast(values[2 + start + remaining] - 97);
            const dest = next[state][letter];
            if (dest < 0) { shift = remaining + 1; break; }
            state = @intCast(dest);
            if (remaining == 0) return @intCast(start);
        }
        start += shift;
    }
    return -1;
}
