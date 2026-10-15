const WordEntry = struct { start: usize, length: usize, count: usize };

fn lowerByte(input: [*c]const i64, index: usize) u8 {
    const byte: u8 = @intCast(input[index]);
    return if (byte >= 'A' and byte <= 'Z') byte + ('a' - 'A') else byte;
}
fn isWordByte(byte: u8) bool {
    return (byte >= 'a' and byte <= 'z') or (byte >= '0' and byte <= '9') or byte == '_';
}
fn compareWord(input: [*c]const i64, start: usize, length: usize, entry: WordEntry) i32 {
    const shared = @min(length, entry.length);
    for (0..shared) |offset| {
        const left = lowerByte(input, start + offset);
        const right = lowerByte(input, entry.start + offset);
        if (left < right) return -1;
        if (left > right) return 1;
    }
    if (length < entry.length) return -1;
    if (length > entry.length) return 1;
    return 0;
}
fn writeCount(output: [*c]u8, position: *usize, count: usize) void {
    var digits: [4]u8 = undefined;
    var digit_count: usize = 0;
    var remaining = count;
    while (true) {
        digits[digit_count] = '0' + @as(u8, @intCast(remaining % 10));
        digit_count += 1;
        remaining /= 10;
        if (remaining == 0) break;
    }
    output[position.*] = '=';
    position.* += 1;
    while (digit_count > 0) {
        digit_count -= 1;
        output[position.*] = digits[digit_count];
        position.* += 1;
    }
    output[position.*] = '\n';
    position.* += 1;
}

export fn word_count_julia(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (length > 1000 or (length != 0 and input == null)) return -1;
    for (0..length) |index| if (input[index] < 0 or input[index] > 127) return -1;
    var entries: [1000]WordEntry = undefined;
    var unique_count: usize = 0;
    var index: usize = 0;
    while (index < length) {
        if (!isWordByte(lowerByte(input, index))) { index += 1; continue; }
        const start = index;
        while (index < length and isWordByte(lowerByte(input, index))) : (index += 1) {}
        var token_length = index - start;
        if (index + 1 < length and input[index] == '\'' and isWordByte(lowerByte(input, index + 1))) {
            token_length += 2;
            index += 2;
        }
        var position: usize = 0;
        while (position < unique_count and compareWord(input, start, token_length, entries[position]) > 0) : (position += 1) {}
        if (position < unique_count and compareWord(input, start, token_length, entries[position]) == 0) {
            entries[position].count += 1;
        } else {
            var move = unique_count;
            while (move > position) : (move -= 1) entries[move] = entries[move - 1];
            entries[position] = .{ .start = start, .length = token_length, .count = 1 };
            unique_count += 1;
        }
    }
    var required: usize = 0;
    for (entries[0..unique_count]) |entry| {
        var digits: usize = 1;
        var value = entry.count;
        while (value >= 10) : (value /= 10) digits += 1;
        required += entry.length + digits + 2;
    }
    if (output_capacity < required or (required != 0 and output == null)) return -2;
    var written: usize = 0;
    for (entries[0..unique_count]) |entry| {
        for (0..entry.length) |offset| {
            output[written] = lowerByte(input, entry.start + offset);
            written += 1;
        }
        writeCount(output, &written, entry.count);
    }
    return @intCast(written);
}
