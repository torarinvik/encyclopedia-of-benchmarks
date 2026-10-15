const MAX_WORDS: usize = 16;
const MAX_WORD_LENGTH: usize = 16;

fn isAnagram(input: []const i64, query_length: usize, word_offset: usize, word_length: usize) bool {
    if (query_length != word_length) return false;
    var counts = [_]i32{0} ** 26;
    for (0..query_length) |index| {
        counts[@intCast(input[2 + index] - 97)] += 1;
        counts[@intCast(input[word_offset + index] - 97)] -= 1;
    }
    for (counts) |count| if (count != 0) return false;
    return true;
}

fn putByte(output: []u8, output_length: *usize, value: u8) bool {
    if (output_length.* >= output.len) return false;
    output[output_length.*] = value;
    output_length.* += 1;
    return true;
}

export fn anagram_dictionary_search(input_ptr: [*c]const i64, length: usize,
                                    output_ptr: [*c]u8, capacity: usize) i64 {
    if (input_ptr == null or length < 2) return -1;
    const input = input_ptr[0..length];
    if (input[0] < 0 or input[0] > MAX_WORDS or input[1] < 0 or input[1] > MAX_WORD_LENGTH) return -1;
    const word_count: usize = @intCast(input[0]);
    const query_length: usize = @intCast(input[1]);
    if (2 + query_length > length) return -1;
    for (input[2 .. 2 + query_length]) |value| if (value < 97 or value > 122) return -1;
    if (output_ptr == null) return -2;
    const output = output_ptr[0..capacity];
    var offset = 2 + query_length;
    var output_length: usize = 0;
    for (0..word_count) |_| {
        if (offset >= length or input[offset] < 1 or input[offset] > MAX_WORD_LENGTH) return -1;
        const word_length: usize = @intCast(input[offset]);
        offset += 1;
        if (offset + word_length > length) return -1;
        for (input[offset .. offset + word_length]) |value| if (value < 97 or value > 122) return -1;
        if (isAnagram(input, query_length, offset, word_length)) {
            for (input[offset .. offset + word_length]) |value| if (!putByte(output, &output_length, @intCast(value))) return -2;
            if (!putByte(output, &output_length, '\n')) return -2;
        }
        offset += word_length;
    }
    if (offset != length) return -1;
    if (!putByte(output, &output_length, 0)) return -2;
    return @intCast(output_length);
}
