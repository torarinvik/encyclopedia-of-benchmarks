module weight_conversions;

const long MAX_AMOUNT = 1000000;

fn usz append_text(char* buffer, usz position, const char* text) {
    for (usz index = 0; text[index] != 0; index++) buffer[position++] = text[index];
    return position;
}

fn usz append_i64(char* buffer, usz position, long value) {
    char[24] digits;
    usz count = 0;
    ulong magnitude;
    if (value < 0) { buffer[position++] = '-'; magnitude = (ulong)(-(value + 1)) + 1; }
    else { magnitude = (ulong)value; }
    do { digits[count++] = (char)('0' + magnitude % 10); magnitude /= 10; } while (magnitude != 0);
    while (count > 0) { count--; buffer[position++] = digits[count]; }
    return position;
}

fn usz append_fixed(char* buffer, usz position, double value) {
    double scaled = value * 100.0;
    long cents = value < 0.0 ? -(long)(-scaled + 0.5) : (long)(scaled + 0.5);
    if (value > 0.0 && ((double)cents + 0.5) / 100.0 <= value) cents++;
    else if (value < 0.0 && ((double)cents - 0.5) / 100.0 >= value) cents--;
    if (cents < 0) { buffer[position++] = '-'; cents = -cents; }
    position = append_i64(buffer, position, cents / 100);
    long fraction = cents % 100;
    buffer[position++] = '.';
    if (fraction == 0) { buffer[position++] = '0'; }
    else if (fraction % 10 == 0) { buffer[position++] = (char)('0' + fraction / 10); }
    else { buffer[position++] = (char)('0' + fraction / 10); buffer[position++] = (char)('0' + fraction % 10); }
    return position;
}

fn long weight_conversions(long* input, usz length, char* output, usz output_capacity)
        @export("weight_conversions") {
    if (input == null || length != 2 || input[0] < 0 || input[0] > 5 ||
        input[1] < -MAX_AMOUNT || input[1] > MAX_AMOUNT) return -1;
    long operation = input[0], amount = input[1], converted = 0;
    char[64] buffer;
    usz position = 0;
    if (operation == 0) {
        position = append_i64(&buffer[0], position, amount);
        position = append_text(&buffer[0], position, " kg = ");
        position = append_i64(&buffer[0], position, amount * 1000);
        position = append_text(&buffer[0], position, " g");
    } else if (operation == 1) {
        converted = amount >= 0 ? amount / 1000 : -((-amount + 999) / 1000);
        position = append_i64(&buffer[0], position, amount);
        position = append_text(&buffer[0], position, " g = ");
        position = append_i64(&buffer[0], position, converted);
        position = append_text(&buffer[0], position, " kg");
    } else if (operation == 2) {
        position = append_i64(&buffer[0], position, amount);
        position = append_text(&buffer[0], position, " lb = ");
        position = append_i64(&buffer[0], position, amount * 16);
        position = append_text(&buffer[0], position, " oz");
    } else if (operation == 3) {
        converted = amount >= 0 ? amount / 16 : -((-amount + 15) / 16);
        position = append_i64(&buffer[0], position, amount);
        position = append_text(&buffer[0], position, " oz = ");
        position = append_i64(&buffer[0], position, converted);
        position = append_text(&buffer[0], position, " lb");
    } else if (operation == 4) {
        position = append_i64(&buffer[0], position, amount);
        position = append_text(&buffer[0], position, " kg = ");
        position = append_fixed(&buffer[0], position, (double)amount * 2.205);
        position = append_text(&buffer[0], position, " lb");
    } else {
        position = append_i64(&buffer[0], position, amount);
        position = append_text(&buffer[0], position, " lb = ");
        position = append_fixed(&buffer[0], position, (double)amount / 2.205);
        position = append_text(&buffer[0], position, " kg");
    }
    buffer[position] = 0;
    if (output == null || output_capacity < position + 1) return -2;
    for (usz index = 0; index <= position; index++) output[index] = buffer[index];
    return (long)position;
}
