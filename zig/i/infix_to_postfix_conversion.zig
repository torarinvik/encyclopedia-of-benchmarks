/// Shunting-yard conversion with right-associative exponentiation.
const MAX_EXPRESSION: usize = 256;
const MAX_OUTPUT: usize = 512;

fn isOperand(ch: i64) bool {
    return (ch >= 48 and ch <= 57) or (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122);
}
fn isOperator(ch: i64) bool { return ch == 43 or ch == 45 or ch == 42 or ch == 47 or ch == 94; }
fn precedence(ch: i64) i64 {
    if (ch == 43 or ch == 45) return 1;
    if (ch == 42 or ch == 47) return 2;
    return 3;
}
fn emitToken(result: *[MAX_OUTPUT]u8, count: *usize, token: u8) void {
    if (count.* > 0) { result[count.*] = ' '; count.* += 1; }
    result[count.*] = token;
    count.* += 1;
}

export fn infix_to_postfix_conversion(input: [*]const i64, length: usize,
                                      output: [*]u8, output_capacity: usize) i64 {
    if (length < 1) return -1;
    const expression_length = input[0];
    if (expression_length < 0 or expression_length > MAX_EXPRESSION or
        length != 1 + @as(usize, @intCast(expression_length))) return -1;
    var stack: [MAX_EXPRESSION]u8 = @splat(0);
    var result: [MAX_OUTPUT]u8 = @splat(0);
    var top: usize = 0;
    var count: usize = 0;
    var expect_operand = true;
    for (0..@as(usize, @intCast(expression_length))) |i| {
        const ch = input[1 + i];
        if (isOperand(ch)) {
            if (!expect_operand) return -1;
            emitToken(&result, &count, @intCast(ch));
            expect_operand = false;
        } else if (ch == 40) {
            if (!expect_operand or top == MAX_EXPRESSION) return -1;
            stack[top] = '('; top += 1;
        } else if (ch == 41) {
            if (expect_operand) return -1;
            while (top > 0 and stack[top - 1] != '(') {
                top -= 1;
                emitToken(&result, &count, stack[top]);
            }
            if (top == 0) return -1;
            top -= 1;
            expect_operand = false;
        } else if (isOperator(ch)) {
            if (expect_operand) return -1;
            while (top > 0 and stack[top - 1] != '(' and
                (precedence(ch) < precedence(stack[top - 1]) or
                 (precedence(ch) == precedence(stack[top - 1]) and ch != 94))) {
                top -= 1;
                emitToken(&result, &count, stack[top]);
            }
            if (top == MAX_EXPRESSION) return -1;
            stack[top] = @intCast(ch); top += 1;
            expect_operand = true;
        } else return -1;
    }
    if (expression_length != 0 and expect_operand) return -1;
    while (top > 0) {
        top -= 1;
        if (stack[top] == '(') return -1;
        emitToken(&result, &count, stack[top]);
    }
    result[count] = 0; count += 1;
    if (output_capacity < count) return -2;
    for (0..count) |i| output[i] = result[i];
    return @intCast(count);
}
