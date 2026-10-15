/// Return the longest printable-ASCII substring with no repeated byte.
const MAX_LENGTH: usize = 1024;
const ALPHABET_SIZE: usize = 95;

export fn longest_substring_without_repeating_characters(values: [*]const i64, length: usize) i64 {
    if (length > MAX_LENGTH) return -2;
    var last_seen: [ALPHABET_SIZE]i64 = @splat(-1);
    var window_start: usize = 0;
    var longest: usize = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < 32 or value > 126) return -2;
        const slot: usize = @intCast(value - 32);
        const previous = last_seen[slot];
        if (previous >= 0 and @as(usize, @intCast(previous)) >= window_start)
            window_start = @as(usize, @intCast(previous)) + 1;
        last_seen[slot] = @intCast(index);
        const current = index - window_start + 1;
        if (current > longest) longest = current;
    }
    return @intCast(longest);
}
