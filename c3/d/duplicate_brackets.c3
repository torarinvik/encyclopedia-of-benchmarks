module duplicate_brackets;

fn long duplicate_brackets(long* packed, usz length) @export("duplicate_brackets")
{
    if (length < 1) return -1;
    long count = packed[0];
    if (count < 0 || count > 256 || length != (usz)count + 1) return -1;
    long depth = 0;
    for (long index = 0; index < count; index++) {
        long ch = packed[index + 1];
        if (ch < 32 || ch > 126) return -1;
        if (ch == '(') depth++;
        else if (ch == ')') {
            depth--;
            if (depth < 0) return -1;
        }
    }
    if (depth != 0) return -1;
    long[256] stack;
    usz top = 0;
    for (long index = 0; index < count; index++) {
        long ch = packed[index + 1];
        if (ch == ')') {
            if (top == 0 || stack[top - 1] == '(') return 1;
            while (top > 0 && stack[top - 1] != '(') top--;
            if (top > 0) top--;
        } else {
            stack[top] = ch;
            top++;
        }
    }
    return 0;
}
