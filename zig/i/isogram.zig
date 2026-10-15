/// Check whether ASCII letters form an isogram, ignoring case and spaces.
export fn isogram(values: [*]const i64, length: usize) i64 {
    if (length > 4096) return -1;
    var seen: [26]bool = @splat(false);
    for (0..length) |index| {
        var value = values[index];
        if (value == 32) continue;
        if (value >= 65 and value <= 90) value += 32;
        if (value < 97 or value > 122) return -1;
        const letter: usize = @intCast(value - 97);
        if (seen[letter]) return 0;
        seen[letter] = true;
    }
    return 1;
}
