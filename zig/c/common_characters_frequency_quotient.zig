const max_input_length: usize = 1 + 16 * (1 + 64);

export fn common_characters_frequency_quotient(input: [*c]const i64, length: usize,
        output: [*c]u8, capacity: usize) i64 {
    if (input == null or length == 0 or length > max_input_length) return -1;
    const count = input[0];
    if (count < 0 or count > 16) return -1;
    var counts = [_]i64{0} ** 26;
    var offset: usize = 1;
    var total: usize = 0;
    for (0..@as(usize, @intCast(count))) |_| {
        if (offset >= length) return -1;
        const string_length = input[offset];
        offset += 1;
        if (string_length < 0 or string_length > 64 or @as(usize, @intCast(string_length)) > length - offset) return -1;
        const end = offset + @as(usize, @intCast(string_length));
        while (offset < end) : (offset += 1) {
            const value = input[offset];
            if (value < 97 or value > 122) return -1;
            counts[@intCast(value - 97)] += 1;
        }
        total += @as(usize, @intCast(string_length));
        if (total > 512) return -1;
    }
    if (offset != length) return -1;
    var used: usize = 0;
    if (count > 0) {
        for (counts) |frequency| {
            const copies = @divTrunc(frequency, count);
            used += @as(usize, @intCast(copies));
        }
    }
    if (used > capacity or (used > 0 and output == null)) return -2;
    var output_offset: usize = 0;
    if (count > 0) {
        for (counts, 0..) |frequency, letter| {
            const copies = @divTrunc(frequency, count);
            for (0..@as(usize, @intCast(copies))) |_| {
                output[output_offset] = @intCast(97 + letter);
                output_offset += 1;
            }
        }
    }
    return @intCast(used);
}
