export fn valid_parentheses(input: [*]const i64, length: usize) i64 {
    if (length > 256) return -1;
    for (0..length) |index| {
        const value = input[index];
        if (value != 40 and value != 41 and value != 91 and value != 93 and value != 123 and value != 125) return -1;
    }
    var stack: [256]u8 = @splat(0);
    var top: usize = 0;
    for (0..length) |index| {
        const value: u8 = @intCast(input[index]);
        if (value == '(' or value == '[' or value == '{') {
            stack[top] = value;
            top += 1;
        } else {
            if (top == 0) return 0;
            top -= 1;
            const expected: u8 = if (value == ')') '(' else if (value == ']') '[' else '{';
            if (stack[top] != expected) return 0;
        }
    }
    return if (top == 0) 1 else 0;
}
