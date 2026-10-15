/// Convert a bounded ASCII infix expression with the source's operator stack.
const MAX_EXPRESSION: usize = 24;
const MAX_STACK: usize = 10;
fn isOperand(ch: i64) bool { return (ch >= 48 and ch <= 57) or (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122); }
fn isOperator(ch: i64) bool { return ch == 43 or ch == 45 or ch == 42 or ch == 47 or ch == 37; }
fn precedence(ch: i64) i64 { return if (ch == 42 or ch == 47 or ch == 37) 1 else 0; }

export fn infix_to_postfix2(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length == 0 or length > MAX_EXPRESSION) return -1;
    var stack: [MAX_STACK]u8 = @splat(0);
    var result: [MAX_EXPRESSION + 1]u8 = @splat(0);
    var top: usize = 0;
    var count: usize = 0;
    var expect_operand = true;
    for (0..length) |index| {
        const ch = input[index];
        if (isOperand(ch)) {
            if (!expect_operand) return -1;
            result[count] = @intCast(ch); count += 1; expect_operand = false;
        } else if (ch == 40) {
            if (!expect_operand or top == MAX_STACK) return -1;
            stack[top] = '('; top += 1;
        } else if (ch == 41) {
            if (expect_operand) return -1;
            while (top > 0 and stack[top - 1] != '(') { top -= 1; result[count] = stack[top]; count += 1; }
            if (top == 0) return -1;
            top -= 1; expect_operand = false;
        } else if (isOperator(ch)) {
            if (expect_operand) return -1;
            while (top > 0 and stack[top - 1] != '(' and precedence(ch) <= precedence(stack[top - 1])) {
                top -= 1; result[count] = stack[top]; count += 1;
            }
            if (top == MAX_STACK) return -1;
            stack[top] = @intCast(ch); top += 1; expect_operand = true;
        } else return -1;
    }
    if (expect_operand) return -1;
    while (top > 0) {
        top -= 1;
        if (stack[top] == '(') return -1;
        result[count] = stack[top]; count += 1;
    }
    result[count] = 0; count += 1;
    if (output == null or capacity < count) return -2;
    for (0..count) |index| output[index] = result[index];
    return @intCast(count);
}
