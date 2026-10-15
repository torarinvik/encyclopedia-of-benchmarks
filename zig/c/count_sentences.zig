/// Count non-overlapping PHP-style sentence-regex matches in bounded ASCII.
const MAX_TEXT_LENGTH: usize = 4096;

fn isTrimByte(value: u8) bool {
    return value == 0 or value == 9 or value == 10 or value == 11 or value == 13 or value == 32;
}
fn isRegexSpace(value: u8) bool {
    return (value >= 9 and value <= 13) or value == 32;
}
fn isWordByte(value: u8) bool {
    return (value >= 'A' and value <= 'Z') or (value >= 'a' and value <= 'z') or
        (value >= '0' and value <= '9') or value == '_';
}
fn isTerminator(value: u8) bool {
    return value == '.' or value == '!' or value == '?';
}
fn isEligiblePredecessor(value: u8) bool {
    return !isRegexSpace(value) and value != '|' and value != '^' and value != '.';
}

export fn count_sentences(raw_input: [*]const i64, length: usize) i64 {
    if (length < 1 or length > MAX_TEXT_LENGTH + 1) return -1;
    const input = raw_input[0..length];
    if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_TEXT_LENGTH)) or
        length != @as(usize, @intCast(input[0])) + 1) return -1;
    const text_length: usize = @intCast(input[0]);
    var text: [MAX_TEXT_LENGTH]u8 = @splat(0);
    for (0..text_length) |index| {
        if (input[index + 1] < 0 or input[index + 1] > 127) return -1;
        text[index] = @intCast(input[index + 1]);
    }

    var begin: usize = 0;
    var end = text_length;
    while (begin < end and isTrimByte(text[begin])) : (begin += 1) {}
    while (end > begin and isTrimByte(text[end - 1])) : (end -= 1) {}
    var cursor = begin;
    var count: i64 = 0;
    while (cursor + 1 < end) {
        var found = false;
        var index = cursor;
        while (index + 1 < end) : (index += 1) {
            if (isEligiblePredecessor(text[index]) and isTerminator(text[index + 1]) and
                (index + 2 == end or !isWordByte(text[index + 2]))) {
                count += 1;
                cursor = index + 2;
                found = true;
                break;
            }
        }
        if (!found) break;
    }
    return count;
}
