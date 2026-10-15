module print_multiplication_table;

fn usz decimal_length(long value) {
    usz length = 1;
    if (value < 0) { length++; value = -value; }
    while (value >= 10) { value /= 10; length++; }
    return length;
}

fn usz append_decimal(char* output, usz position, long value) {
    if (value < 0) { output[position++] = '-'; value = -value; }
    char[20] reversed;
    usz count = 0;
    do { reversed[count++] = (char)('0' + value % 10); value /= 10; } while (value > 0);
    while (count > 0) output[position++] = reversed[--count];
    return position;
}

// Format rows exactly as `number * multiplier = product`, separated by LF.
fn long print_multiplication_table(long* input, usz length, char* output, usz output_capacity)
    @export("print_multiplication_table") {
    if (input == null || length != 2) return -1;
    long number = input[0];
    long terms = input[1];
    if (number < -1000000 || number > 1000000 || terms < -20 || terms > 20) return -1;
    usz required = terms > 0 ? (usz)terms - 1 : 0;
    for (long multiplier = 1; multiplier <= terms; multiplier++) {
        long product = number * multiplier;
        required += decimal_length(number) + 3 + decimal_length(multiplier) + 3 + decimal_length(product);
    }
    if (output_capacity < required || (required != 0 && output == null)) return -2;
    usz position = 0;
    for (long multiplier = 1; multiplier <= terms; multiplier++) {
        if (multiplier > 1) output[position++] = '\n';
        position = append_decimal(output, position, number);
        output[position++] = ' '; output[position++] = '*'; output[position++] = ' ';
        position = append_decimal(output, position, multiplier);
        output[position++] = ' '; output[position++] = '='; output[position++] = ' ';
        position = append_decimal(output, position, number * multiplier);
    }
    return (long)position;
}
