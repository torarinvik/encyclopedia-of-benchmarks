module valid_parentheses;

// Check bracket nesting with a bounded stack.
fn long valid_parentheses(long* input, usz length) @export("valid_parentheses") {
    if (length > 256 || (length != 0 && input == null)) return -1;
    for (usz index = 0; index < length; index++) {
        long value = input[index];
        if (value != 40 && value != 41 && value != 91 && value != 93 && value != 123 && value != 125) return -1;
    }
    char[256] stack;
    usz top = 0;
    for (usz index = 0; index < length; index++) {
        char value = (char)input[index];
        if (value == '(' || value == '[' || value == '{') {
            stack[top++] = value;
        } else {
            if (top == 0) return 0;
            char expected = value == ')' ? '(' : value == ']' ? '[' : '{';
            if (stack[--top] != expected) return 0;
        }
    }
    return top == 0 ? 1 : 0;
}
