export fn duplicate_brackets(input_values: [*]const i64, length: usize) i64 {
    if (length < 1) return -1;
    const count = input_values[0];
    if (count < 0 or count > 256 or length != @as(usize, @intCast(count)) + 1) return -1;
    const bytes = input_values[1..length];
    var depth: i64 = 0;
    for (bytes) |ch| {
        if (ch < 32 or ch > 126) return -1;
        if (ch == 40) {
            depth += 1;
        } else if (ch == 41) {
            depth -= 1;
            if (depth < 0) return -1;
        }
    }
    if (depth != 0) return -1;
    var stack: [256]i64 = undefined;
    var top: usize = 0;
    for (bytes) |ch| {
        if (ch == 41) {
            if (top == 0 or stack[top - 1] == 40) return 1;
            while (top > 0 and stack[top - 1] != 40) top -= 1;
            if (top > 0) top -= 1;
        } else {
            stack[top] = ch;
            top += 1;
        }
    }
    return 0;
}
