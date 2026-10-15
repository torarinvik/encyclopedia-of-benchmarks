const REQUIRED_BYTES = [_]usize{ 0, 2, 8, 30, 112, 420, 1584 };

fn walk(pairs: usize, opened: usize, closed: usize, buffer: *[12]u8, output: []u8, cursor: usize) usize {
    const position = opened + closed;
    if (position == 2 * pairs) {
        @memcpy(output[cursor .. cursor + position], buffer[0..position]);
        return cursor + position;
    }
    var next = cursor;
    if (opened < pairs) {
        buffer[position] = '(';
        next = walk(pairs, opened + 1, closed, buffer, output, next);
    }
    if (closed < opened) {
        buffer[position] = ')';
        next = walk(pairs, opened, closed + 1, buffer, output, next);
    }
    return next;
}

pub export fn generate_parentheses(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 1 or input[0] < 1 or input[0] > 6) return -1;
    const pairs: usize = @intCast(input[0]);
    const required = REQUIRED_BYTES[pairs];
    if (capacity < required or output == null) return -2;
    var buffer = [_]u8{0} ** 12;
    const target = output[0..required];
    return @intCast(walk(pairs, 0, 0, &buffer, target, 0));
}
