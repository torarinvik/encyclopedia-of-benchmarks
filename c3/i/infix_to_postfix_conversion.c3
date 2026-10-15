module infix_to_postfix_conversion;

const long MAX_EXPRESSION = 256;
const long MAX_OUTPUT = 512;

fn bool is_operand(long ch) {
    return (ch >= '0' && ch <= '9') || (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z');
}
fn bool is_operator(long ch) { return ch == '+' || ch == '-' || ch == '*' || ch == '/' || ch == '^'; }
fn long precedence(long ch) { return ch == '+' || ch == '-' ? 1 : (ch == '*' || ch == '/' ? 2 : 3); }
fn void emit_token(char* result, usz* count, char token) {
    if (*count > 0) result[(*count)++] = ' ';
    result[(*count)++] = token;
}

fn long infix_to_postfix_conversion(long* input, usz length, char* output, usz output_capacity) @export("infix_to_postfix_conversion") {
    if (input == null || length < 1) return -1;
    long expression_length = input[0];
    if (expression_length < 0 || expression_length > MAX_EXPRESSION || length != 1 + (usz)expression_length) return -1;
    char[MAX_EXPRESSION] stack;
    char[MAX_OUTPUT] result;
    usz top = 0, count = 0;
    bool expect_operand = true;
    for (usz i = 0; i < (usz)expression_length; i++) {
        long ch = input[1 + i];
        if (is_operand(ch)) {
            if (!expect_operand) return -1;
            emit_token(result, &count, (char)ch);
            expect_operand = false;
        } else if (ch == '(') {
            if (!expect_operand || top == MAX_EXPRESSION) return -1;
            stack[top++] = '(';
        } else if (ch == ')') {
            if (expect_operand) return -1;
            while (top > 0 && stack[top - 1] != '(') emit_token(result, &count, stack[--top]);
            if (top == 0) return -1;
            top--;
            expect_operand = false;
        } else if (is_operator(ch)) {
            if (expect_operand) return -1;
            while (top > 0 && stack[top - 1] != '(' &&
                   (precedence(ch) < precedence(stack[top - 1]) ||
                    (precedence(ch) == precedence(stack[top - 1]) && ch != '^'))) {
                emit_token(result, &count, stack[--top]);
            }
            if (top == MAX_EXPRESSION) return -1;
            stack[top++] = (char)ch;
            expect_operand = true;
        } else return -1;
    }
    if (expression_length != 0 && expect_operand) return -1;
    while (top > 0) {
        if (stack[top - 1] == '(') return -1;
        emit_token(result, &count, stack[--top]);
    }
    result[count++] = 0;
    if (output == null || output_capacity < count) return -2;
    for (usz i = 0; i < count; i++) output[i] = result[i];
    return (long)count;
}
