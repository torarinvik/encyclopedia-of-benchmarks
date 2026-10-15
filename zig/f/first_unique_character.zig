/// Return the first lowercase ASCII letter whose frequency is one.
const MAX_LENGTH: usize = 1024;

export fn first_unique_character(values: [*]const i64, length: usize) i64 {
    if (length > MAX_LENGTH) return -2;
    var counts: [26]usize = @splat(0);
    for (0..length) |index| {
        const value = values[index];
        if (value < 97 or value > 122) return -2;
        counts[@intCast(value - 97)] += 1;
    }
    for (0..length) |index| {
        const slot: usize = @intCast(values[index] - 97);
        if (counts[slot] == 1) return @intCast(index);
    }
    return -1;
}
