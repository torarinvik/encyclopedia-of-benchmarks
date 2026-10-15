module balanced_parentheses;

// Check (), [], and {} nesting; ignore other character codes.
fn long balanced_parentheses(long* values, usz length) @export("balanced_parentheses") {
    if (length > 4096) return -1;
    long stack[4096];
    usz top = 0;
    for (usz index = 0; index < length; index++) {
        long value = values[index];
        if (value == 40 || value == 91 || value == 123) {
            stack[top++] = value;
        } else if (value == 41 || value == 93 || value == 125) {
            if (top == 0) return 0;
            top--;
            long opener = stack[top];
            if ((value == 41 && opener != 40) ||
                (value == 93 && opener != 91) ||
                (value == 125 && opener != 123)) return 0;
        }
    }
    return top == 0 ? 1 : 0;
}
