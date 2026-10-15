module integer_to_roman;

fn usz roman_digit_length(long digit) {
    if (digit == 4 || digit == 9) return 2;
    if (digit >= 5) return (usz)(digit - 4);
    return (usz)digit;
}

fn usz append_roman_digit(long digit, char one, char five, char ten, char* output, usz position) {
    if (digit == 9) { output[position++] = one; output[position++] = ten; return position; }
    if (digit >= 5) { output[position++] = five; digit -= 5; }
    if (digit == 4) { output[position++] = one; output[position++] = five; return position; }
    while (digit > 0) { output[position++] = one; digit--; }
    return position;
}

// Encode an integer in canonical uppercase Roman numerals.
fn long integer_to_roman(long value, char* output, usz output_capacity) @export("integer_to_roman") {
    if (value < 1 || value > 3999) return -1;
    usz width = (usz)(value / 1000) + roman_digit_length((value / 100) % 10) +
        roman_digit_length((value / 10) % 10) + roman_digit_length(value % 10);
    if (output == null || output_capacity < width) return -2;
    usz position = 0;
    for (long count = value / 1000; count > 0; count--) output[position++] = 'M';
    position = append_roman_digit((value / 100) % 10, 'C', 'D', 'M', output, position);
    position = append_roman_digit((value / 10) % 10, 'X', 'L', 'C', output, position);
    position = append_roman_digit(value % 10, 'I', 'V', 'X', output, position);
    return (long)position;
}
