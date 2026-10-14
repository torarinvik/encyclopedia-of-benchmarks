/// Test ASCII pattern presence with a Rabin-Karp rolling hash.
export fn rabin_karp(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 512) return -1;
    const text_length_value = values[0];
    const pattern_length_value = values[1];
    if (text_length_value < 0 or text_length_value > 255 or pattern_length_value < 0 or pattern_length_value > 255) return -1;
    if (length != 2 + @as(usize, @intCast(text_length_value)) + @as(usize, @intCast(pattern_length_value))) return -1;
    for (0..@as(usize, @intCast(text_length_value + pattern_length_value))) |index| {
        if (values[2 + index] < 0 or values[2 + index] > 127) return -1;
    }

    const text_length: usize = @intCast(text_length_value);
    const pattern_length: usize = @intCast(pattern_length_value);
    if (pattern_length == 0) return 1;
    if (pattern_length > text_length) return 0;

    const base: i64 = 256;
    const modulus: i64 = 1_000_003;
    var pattern_hash: i64 = 0;
    var rolling_hash: i64 = 0;
    var high_power: i64 = 1;
    for (0..pattern_length) |index| {
        pattern_hash = @mod(pattern_hash * base + values[2 + text_length + index], modulus);
        rolling_hash = @mod(rolling_hash * base + values[2 + index], modulus);
        if (index + 1 < pattern_length) high_power = @mod(high_power * base, modulus);
    }
    const last_start = text_length - pattern_length;
    for (0..last_start + 1) |start| {
        if (rolling_hash == pattern_hash) {
            var offset: usize = 0;
            while (offset < pattern_length and values[2 + start + offset] == values[2 + text_length + offset]) : (offset += 1) {}
            if (offset == pattern_length) return 1;
        }
        if (start < last_start) {
            const removed = @mod(values[2 + start] * high_power, modulus);
            rolling_hash = @mod(rolling_hash - removed, modulus);
            if (rolling_hash < 0) rolling_hash += modulus;
            rolling_hash = @mod(rolling_hash * base + values[2 + start + pattern_length], modulus);
        }
    }
    return 0;
}
