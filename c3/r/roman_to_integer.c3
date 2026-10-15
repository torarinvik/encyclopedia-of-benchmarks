module roman_to_integer;

fn long decode_digit(long* symbols, usz length, usz position, long one, long five, long ten) {
    if (position >= length) return 0;
    if (symbols[position] == one) {
        if (position + 1 < length) {
            if (symbols[position + 1] == ten) return 9 * 16 + 2;
            if (symbols[position + 1] == five) return 4 * 16 + 2;
        }
        usz count = 0;
        while (position + count < length && symbols[position + count] == one && count < 3) count++;
        if (position + count < length && symbols[position + count] == one) return -1;
        return (long)(count * 16 + count);
    }
    if (symbols[position] == five) {
        usz count = 0;
        while (position + 1 + count < length && symbols[position + 1 + count] == one && count < 3) count++;
        if (position + 1 + count < length && symbols[position + 1 + count] == one) return -1;
        return (long)((5 + count) * 16 + 1 + count);
    }
    return 0;
}

// Decode canonical uppercase Roman numerals in the range 1 through 3,999.
fn long roman_to_integer(long* symbols, usz length) @export("roman_to_integer") {
    if (length == 0 || length > 15) return -1;
    for (usz index = 0; index < length; index++) {
        long symbol = symbols[index];
        if (symbol != 'I' && symbol != 'V' && symbol != 'X' && symbol != 'L' &&
            symbol != 'C' && symbol != 'D' && symbol != 'M') return -1;
    }
    usz position = 0;
    usz thousands = 0;
    while (position < length && symbols[position] == 'M' && thousands < 3) {
        position++;
        thousands++;
    }
    if (position < length && symbols[position] == 'M') return -1;
    long hundreds = decode_digit(symbols, length, position, 'C', 'D', 'M');
    if (hundreds < 0) return -1;
    position += (usz)(hundreds & 15);
    long tens = decode_digit(symbols, length, position, 'X', 'L', 'C');
    if (tens < 0) return -1;
    position += (usz)(tens & 15);
    long ones = decode_digit(symbols, length, position, 'I', 'V', 'X');
    if (ones < 0) return -1;
    position += (usz)(ones & 15);
    if (position != length) return -1;
    long value = (long)thousands * 1000 + (hundreds >> 4) * 100 + (tens >> 4) * 10 + (ones >> 4);
    return value >= 1 && value <= 3999 ? value : -1;
}
