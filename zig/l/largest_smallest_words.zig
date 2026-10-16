fn isStrippedPunctuation(value: u8) bool {
    return value == '.' or value == ',' or value == '!' or value == '?' or value == '(' or
        value == ')' or value == '[' or value == ']' or value == '{' or value == '}';
}

fn putU32(output: [*c]u8, offset: usize, value: u32) void {
    output[offset] = @truncate(value);
    output[offset + 1] = @truncate(value >> 8);
    output[offset + 2] = @truncate(value >> 16);
    output[offset + 3] = @truncate(value >> 24);
}

pub export fn largest_smallest_words(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or length > 515) return -1;
    if (values[0] < 1 or values[0] > 512 or length != 1 + @as(usize, @intCast(values[0]))) return -1;
    const text_length: usize = @intCast(values[0]);
    var text: [512]u8 = undefined;
    for (0..text_length) |index| {
        const value = values[index + 1];
        if (value < 32 or value > 126) return -1;
        text[index] = @intCast(value);
    }
    var small_start: usize = 0;
    var large_start: usize = 0;
    var small_length: usize = 513;
    var large_length: usize = 0;
    var word_count: usize = 0;
    var pos: usize = 0;
    while (pos < text_length) {
        while (pos < text_length and text[pos] == ' ') : (pos += 1) {}
        if (pos == text_length) break;
        const token_start = pos;
        while (pos < text_length and text[pos] != ' ') : (pos += 1) {}
        var first = token_start;
        var last = pos;
        while (first < last and isStrippedPunctuation(text[first])) : (first += 1) {}
        while (last > first and isStrippedPunctuation(text[last - 1])) : (last -= 1) {}
        const word_length = last - first;
        if (word_length < small_length) { small_start = first; small_length = word_length; }
        if (word_length > large_length) { large_start = first; large_length = word_length; }
        word_count += 1;
    }
    if (word_count == 0) return -1;
    const output_length = 8 + small_length + large_length;
    if (output_capacity < output_length or output == null) return -2;
    putU32(output, 0, @intCast(small_length));
    for (0..small_length) |index| output[4 + index] = text[small_start + index];
    const large_header = 4 + small_length;
    putU32(output, large_header, @intCast(large_length));
    for (0..large_length) |index| output[large_header + 4 + index] = text[large_start + index];
    return @intCast(output_length);
}
