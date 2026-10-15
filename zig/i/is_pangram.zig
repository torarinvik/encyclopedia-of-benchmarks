/// ASCII pangram predicate: ignore nonletters and ASCII letter case.
export fn is_pangram(values: [*]const i64, length: usize) i64 {
    if (length > 4096) return -1;
    var seen: [26]bool = @splat(false);
    var found: usize = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < 0 or value > 127) return -1;
        const lower = if (value >= 65 and value <= 90) value + 32 else value;
        if (lower >= 97 and lower <= 122) {
            const letter: usize = @intCast(lower - 97);
            if (!seen[letter]) {
                seen[letter] = true;
                found += 1;
            }
        }
    }
    return if (found == 26) 1 else 0;
}
