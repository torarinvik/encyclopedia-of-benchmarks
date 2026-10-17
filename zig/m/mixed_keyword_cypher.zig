const MAX_KEYWORD_LENGTH: usize = 64;
const MAX_PLAINTEXT_LENGTH: usize = 512;
const MAX_INPUT_LENGTH: usize = 2 + MAX_KEYWORD_LENGTH + MAX_PLAINTEXT_LENGTH;

export fn mixed_keyword_cypher(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];

    const raw_keyword_length = values[0];
    if (raw_keyword_length < 1 or raw_keyword_length > 64) return -1;
    const keyword_length: usize = @intCast(raw_keyword_length);
    const plaintext_length_index = 1 + keyword_length;
    if (plaintext_length_index >= length) return -1;

    const raw_plaintext_length = values[plaintext_length_index];
    if (raw_plaintext_length < 0 or raw_plaintext_length > 512) return -1;
    const plaintext_length: usize = @intCast(raw_plaintext_length);
    if (length != plaintext_length_index + 1 + plaintext_length) return -1;

    var unique_letters: [26]u8 = @splat(0);
    var seen: [26]bool = @splat(false);
    var unique_count: usize = 0;
    for (0..keyword_length) |index| {
        const raw = values[1 + index];
        if (raw < 0 or raw > 127) return -1;
        var letter: u8 = @intCast(raw);
        if (letter >= 'a' and letter <= 'z') letter -= 'a' - 'A';
        if (letter >= 'A' and letter <= 'Z') {
            const alphabet_index: usize = @intCast(letter - 'A');
            if (!seen[alphabet_index]) {
                seen[alphabet_index] = true;
                unique_letters[unique_count] = letter;
                unique_count += 1;
            }
        }
    }
    if (unique_count == 0) return -1;

    for (0..plaintext_length) |index| {
        const raw = values[plaintext_length_index + 1 + index];
        if (raw < 0 or raw > 127) return -1;
    }

    var shifted: [26]u8 = @splat(0);
    for (0..unique_count) |index| shifted[index] = unique_letters[index];
    var shifted_count = unique_count;
    for (0..26) |index| {
        if (!seen[index]) {
            shifted[shifted_count] = 'A' + @as(u8, @intCast(index));
            shifted_count += 1;
        }
    }

    var mapping: [26]u8 = @splat(0);
    var alphabet_index: usize = 0;
    for (0..unique_count) |column| {
        var row_start: usize = 0;
        while (row_start < 26) : (row_start += unique_count) {
            const shifted_index = row_start + column;
            if (shifted_index >= 26) break;
            mapping[alphabet_index] = shifted[shifted_index];
            alphabet_index += 1;
        }
    }

    var buffer: [MAX_PLAINTEXT_LENGTH]u8 = @splat(0);
    for (0..plaintext_length) |index| {
        var letter: u8 = @intCast(values[plaintext_length_index + 1 + index]);
        if (letter >= 'a' and letter <= 'z') letter -= 'a' - 'A';
        buffer[index] = if (letter >= 'A' and letter <= 'Z')
            mapping[@intCast(letter - 'A')]
        else
            letter;
    }

    if (output == null or capacity < plaintext_length) return -2;
    const result = output.?;
    for (0..plaintext_length) |index| result[index] = buffer[index];
    return @intCast(plaintext_length);
}
