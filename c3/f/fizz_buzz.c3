module fizz_buzz;

fn usz token_length(long value) {
    if (value % 15 == 0) return 8;
    if (value % 3 == 0 || value % 5 == 0) return 4;
    if (value >= 100) return 3;
    if (value >= 10) return 2;
    return 1;
}

fn usz append_number(long value, char* output, usz position) {
    if (value >= 100) {
        output[position++] = (char)('0' + value / 100);
        value %= 100;
        output[position++] = (char)('0' + value / 10);
        output[position++] = (char)('0' + value % 10);
    } else if (value >= 10) {
        output[position++] = (char)('0' + value / 10);
        output[position++] = (char)('0' + value % 10);
    } else {
        output[position++] = (char)('0' + value);
    }
    return position;
}

fn long fizz_buzz(long value, char* output, usz output_capacity) @export("fizz_buzz") {
    if (value < 1 || value > 512) return -1;
    usz width = 0;
    for (long current = 1; current <= value; current++) width += token_length(current) + 1;
    if (output == null || output_capacity < width) return -2;
    usz position = 0;
    for (long current = 1; current <= value; current++) {
        if (current % 15 == 0) {
            output[position++] = 'F'; output[position++] = 'i'; output[position++] = 'z'; output[position++] = 'z';
            output[position++] = 'B'; output[position++] = 'u'; output[position++] = 'z'; output[position++] = 'z';
        } else if (current % 3 == 0) {
            output[position++] = 'F'; output[position++] = 'i'; output[position++] = 'z'; output[position++] = 'z';
        } else if (current % 5 == 0) {
            output[position++] = 'B'; output[position++] = 'u'; output[position++] = 'z'; output[position++] = 'z';
        } else {
            position = append_number(current, output, position);
        }
        output[position++] = ' ';
    }
    return (long)position;
}
