const MAX_LENGTH: usize = 4096;
fn punctuation(value: i64) bool { return (value >= 33 and value <= 47) or (value >= 58 and value <= 64) or (value >= 91 and value <= 96) or (value >= 123 and value <= 126); }
fn fold(value: i64) i64 { return if (value >= 65 and value <= 90) value + 32 else value; }
export fn findpalindrome(input: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (length > MAX_LENGTH) return -1;
    for (0..length) |i| { if (input[i] < 32 or input[i] > 126) return -1; }
    var written: usize = 0; var found = false; var segment: usize = 0;
    for (0..length + 1) |end| {
        if (end < length and input[end] != 32) continue;
        var token_length: usize = 0;
        for (segment..end) |i| { if (!punctuation(input[i])) token_length += 1; }
        var left = segment; var right = end; var matched = true;
        while (left < right) {
            while (left < right and punctuation(input[left])) left += 1;
            while (left < right and punctuation(input[right - 1])) right -= 1;
            if (left < right) { if (fold(input[left]) != fold(input[right - 1])) { matched = false; break; } left += 1; right -= 1; }
        }
        if (token_length > 1 and matched) {
            const needed = token_length + @as(usize, if (found) 1 else 0);
            if (written + needed > output_capacity) return -2;
            if (found) { output[written] = 0; written += 1; }
            for (segment..end) |i| { if (!punctuation(input[i])) { output[written] = @intCast(input[i]); written += 1; } }
            found = true;
        }
        segment = end + 1;
    }
    return @intCast(written);
}
