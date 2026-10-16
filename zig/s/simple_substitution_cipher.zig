export fn simple_substitution_cipher(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 28 or length > 284) return -1;
    const values = input.?;
    const mode, n64 = .{ values[0], values[27] };
    if ((mode != 0 and mode != 1) or n64 < 0 or n64 > 256 or length != 28 + @as(usize, @intCast(n64))) return -1;
    var seen = [_]bool{false} ** 26;
    for (0..26) |i| {
        const value = values[1 + i];
        if (value < 65 or value > 90 or seen[@intCast(value - 65)]) return -1;
        seen[@intCast(value - 65)] = true;
    }
    const n: usize = @intCast(n64);
    for (0..n) |i| if (values[28 + i] < 0 or values[28 + i] > 127) return -1;
    if (output == null or output_capacity < n) return -2;
    const out = output.?;
    for (0..n) |i| {
        const ch = values[28 + i];
        const lower = ch >= 97 and ch <= 122;
        const upper = ch >= 65 and ch <= 90;
        if (!lower and !upper) { out[i] = @intCast(ch); continue; }
        const index: usize = @intCast(ch - (if (lower) 97 else 65));
        var mapped: i64 = @intCast(index);
        if (mode == 0) mapped = values[1 + index] - 65 else {
            mapped = 0;
            while (mapped < 26 and values[1 + @as(usize, @intCast(mapped))] != 65 + @as(i64, @intCast(index))) : (mapped += 1) {}
        }
        out[i] = @intCast((if (lower) 97 else 65) + mapped);
    }
    return @intCast(n);
}
