export fn polybius(v: [*c]const i64, n: usize, out: [*c]u8, cap: usize) i64 {
    if (v == null or n < 1 or n > 65 or v[0] < 0 or v[0] > 64 or n != @as(usize, @intCast(v[0])) + 1) return -1;
    const count: usize = @intCast(v[0]); const needed = count * 2;
    if (needed > cap or (needed > 0 and out == null)) return -2;
    var k: usize = 0;
    for (0..count) |i| { var x = v[i + 1]; if (x >= 97 and x <= 122) x -= 32; if (x < 65 or x > 90 or x == 74) return -1;
        var index: i64 = x - 65; if (x > 74) index -= 1;
        out[k] = @intCast(65 + @divTrunc(index, 5)); out[k + 1] = @intCast(65 + @mod(index, 5)); k += 2;
    }
    return @intCast(needed);
}
