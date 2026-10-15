module infix_to_prefix;
const usz MAX = 256;
fn bool operand(long c) { return (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122); }
fn bool operation(long c) { return c == 43 || c == 45 || c == 42 || c == 47 || c == 94; }
fn long precedence(long c) { return c == 43 || c == 45 ? 1 : (c == 42 || c == 47 ? 2 : 3); }
fn bool valid(long* input, usz length) {
    char[MAX] stage; usz depth = 0; bool done = false;
    for (usz i = 0; i < length; i++) { long ch = input[i];
        if (depth == 0) { if (done) return false; if (operand(ch)) done = true; else if (ch == 40) stage[depth++] = 0; else return false; }
        else if (stage[depth - 1] == 0 || stage[depth - 1] == 2) { if (operand(ch)) stage[depth - 1] = stage[depth - 1] == 0 ? 1 : 3; else if (ch == 40 && depth < MAX) stage[depth++] = 0; else return false; }
        else if (stage[depth - 1] == 1) { if (!operation(ch)) return false; stage[depth - 1] = 2; }
        else { if (ch != 41) return false; depth--; if (depth == 0) done = true; else if (stage[depth - 1] == 0) stage[depth - 1] = 1; else if (stage[depth - 1] == 2) stage[depth - 1] = 3; else return false; }
    }
    return depth == 0 && done;
}
fn long infix_to_prefix(long* input, usz length, char* output, usz capacity) @export("infix_to_prefix") {
    if (length > MAX || (length > 0 && input == null)) return -1;
    if (length == 0) return 0;
    if (!valid(input, length)) return -1;
    char[MAX] stack; char[MAX] post; usz top = 0, count = 0;
    usz i = length;
    while (i > 0) { i--; long ch = input[i];
        if (operand(ch)) post[count++] = (char)ch;
        else if (ch == 41) stack[top++] = ')';
        else if (ch == 40) { while (top > 0 && stack[top - 1] != ')') post[count++] = stack[--top]; if (top > 0) top--; }
        else { while (top > 0 && stack[top - 1] != ')' && precedence(ch) < precedence(stack[top - 1])) post[count++] = stack[--top]; stack[top++] = (char)ch; }
    }
    while (top > 0) post[count++] = stack[--top];
    if (capacity < count || (count > 0 && output == null)) return -2;
    for (usz j = 0; j < count; j++) output[j] = post[count - 1 - j];
    return (long)count;
}
