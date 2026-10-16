module celebrity_finder;

fn long celebrity_finder(long* input, usz length) @export("celebrity_finder") {
    if (input == null || length < 2 || input[0] < 1 || input[0] > 64) return -2;
    int n = (int)input[0];
    if (length != 1 + (usz)n * (usz)n) return -2;
    for (usz i = 1; i < length; i++) if (input[i] != 0 && input[i] != 1) return -2;
    int[64] stack;
    int top = 0;
    for (int i = 0; i < n; i++) stack[top++] = i;
    while (top > 1) {
        int person1 = stack[--top];
        int person2 = stack[--top];
        stack[top++] = input[1 + (usz)person1 * (usz)n + (usz)person2] == 1 ? person2 : person1;
    }
    int candidate = stack[0];
    for (int i = 0; i < n; i++) {
        if (i != candidate && (input[1 + (usz)candidate * (usz)n + (usz)i] == 1 || input[1 + (usz)i * (usz)n + (usz)candidate] == 0)) return -1;
    }
    return candidate;
}
