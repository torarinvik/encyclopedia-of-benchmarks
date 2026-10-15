/// Check (), [], and {} nesting; ignore other character codes.
export fn balanced_parentheses(values: [*]const i64, length: usize) i64 {
    if (length > 4096) return -1;
    var stack: [4096]i64 = undefined;
    var top: usize = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value == 40 or value == 91 or value == 123) {
            stack[top] = value;
            top += 1;
        } else if (value == 41 or value == 93 or value == 125) {
            if (top == 0) return 0;
            top -= 1;
            const opener = stack[top];
            if ((value == 41 and opener != 40) or (value == 93 and opener != 91) or (value == 125 and opener != 123)) {
                return 0;
            }
        }
    }
    return if (top == 0) 1 else 0;
}
