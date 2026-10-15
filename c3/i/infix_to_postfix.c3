module infix_to_postfix;

const usz MAX_EXPRESSION = 24;
const usz MAX_STACK = 10;

fn bool infix_is_operand(long ch) {
    return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122);
}
fn bool infix_is_operator(long ch) { return ch == 43 || ch == 45 || ch == 42 || ch == 47 || ch == 94; }
fn long infix_precedence(long ch) { return ch == 43 || ch == 45 ? 1 : (ch == 42 || ch == 47 ? 2 : 3); }

fn long infix_to_postfix(long* input, usz length, char* output, usz output_capacity) @export("infix_to_postfix") {
    if (input == null || length == 0 || length > MAX_EXPRESSION) return -1;
    char[MAX_STACK] stack;
    char[MAX_EXPRESSION + 1] result;
    usz top = 0, count = 0;
    bool expect_operand = true;
    for (usz i = 0; i < length; i++) {
        long ch = input[i];
        if (infix_is_operand(ch)) {
            if (!expect_operand) return -1;
            result[count++] = (char)ch;
            expect_operand = false;
        } else if (ch == 40) {
            if (!expect_operand || top == MAX_STACK) return -1;
            stack[top++] = (char)ch;
        } else if (ch == 41) {
            while (top > 0 && stack[top - 1] != '(') result[count++] = stack[--top];
            if (top > 0) --top;
            expect_operand = false;
        } else if (infix_is_operator(ch)) {
            if (expect_operand) return -1;
            while (top > 0 && stack[top - 1] != '(' && infix_precedence(ch) <= infix_precedence(stack[top - 1]))
                result[count++] = stack[--top];
            if (top == MAX_STACK) return -1;
            stack[top++] = (char)ch;
            expect_operand = true;
        } else return -1;
    }
    if (expect_operand) return -1;
    while (top > 0) {
        if (stack[top - 1] == '(') return -1;
        result[count++] = stack[--top];
    }
    result[count++] = 0;
    if (output == null || output_capacity < count) return -2;
    for (usz i = 0; i < count; i++) output[i] = result[i];
    return (long)count;
}
