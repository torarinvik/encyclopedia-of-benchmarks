/// Return the unique most frequent lowercase ASCII letter as its code point.
export fn max_character(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 256) return -1;
    var counts: [26]i64 = @splat(0);
    for (0..length) |i| {
        const value = values[i];
        if (value < 97 or value > 122) return -1;
        counts[@intCast(value - 97)] += 1;
    }
    var best: i64 = 0;
    var code: i64 = -1;
    var tied = false;
    for (0..26) |i| {
        if (counts[i] > best) {
            best = counts[i];
            code = 97 + @as(i64, @intCast(i));
            tied = false;
        } else if (counts[i] == best and best != 0) {
            tied = true;
        }
    }
    return if (tied) -1 else code;
}
