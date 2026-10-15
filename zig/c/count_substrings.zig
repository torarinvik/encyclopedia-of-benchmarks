const MAX_LENGTH: i64 = 4096;

fn findNext(values: []const i64, textLength: usize, patternLength: usize, patternStart: usize, start: usize) ?usize {
    if (start > textLength or patternLength > textLength - start) return null;
    const last = textLength - patternLength;
    var position = start;
    while (position <= last) : (position += 1) {
        var offset: usize = 0;
        while (offset < patternLength and values[2 + position + offset] == values[patternStart + offset]) : (offset += 1) {}
        if (offset == patternLength) return position;
    }
    return null;
}

pub export fn count_substrings(raw_values: [*]const i64, length: usize) i64 {
    if (length < 2 or raw_values[0] < 0 or raw_values[0] > MAX_LENGTH or raw_values[1] < 0 or raw_values[1] > MAX_LENGTH) return -1;
    const values = raw_values[0..length];
    const textLength: usize = @intCast(values[0]);
    const patternLength: usize = @intCast(values[1]);
    if (length != 2 + textLength + patternLength) return -1;
    for (values[2..]) |value| if (value < 0 or value > 127) return -1;
    if (patternLength == 0) return @as(i64, @intCast(textLength)) + 1;
    const patternStart = 2 + textLength;
    var count: i64 = 0;
    var start: usize = 0;
    while (findNext(values, textLength, patternLength, patternStart, start)) |position| {
        count += 1;
        start = position + 1;
    }
    return count;
}
