module generate_parentheses;

fn usz generate(int pairs, int opened, int closed, char* buffer, char* output, usz cursor) {
    int position = opened + closed;
    if (position == 2 * pairs) {
        for (int index = 0; index < position; index++) output[cursor++] = buffer[index];
        return cursor;
    }
    if (opened < pairs) {
        buffer[position] = '(';
        cursor = generate(pairs, opened + 1, closed, buffer, output, cursor);
    }
    if (closed < opened) {
        buffer[position] = ')';
        cursor = generate(pairs, opened, closed + 1, buffer, output, cursor);
    }
    return cursor;
}

fn long generate_parentheses(long* input, usz length, char* output, usz capacity) @export("generate_parentheses") {
    if (input == null || length != 1 || input[0] < 1 || input[0] > 6) return -1;
    usz required = input[0] == 1 ? 2 : input[0] == 2 ? 8 : input[0] == 3 ? 30 : input[0] == 4 ? 112 : input[0] == 5 ? 420 : 1584;
    if (capacity < required || output == null) return -2;
    char[12] buffer;
    usz cursor = generate((int)input[0], 0, 0, buffer, output, 0);
    return (long)cursor;
}
