module factors;

fn usz decimal_length(long value) {
    usz length = 1;
    while (value >= 10) { value /= 10; length++; }
    return length;
}

fn usz append_decimal(long value, char* output, usz position) {
    char[3] digits;
    usz count = 0;
    do { digits[count++] = (char)('0' + value % 10); value /= 10; } while (value > 0);
    while (count > 0) output[position++] = digits[--count];
    return position;
}

// List all positive divisors in ascending decimal order.
fn long factors(long value, char* output, usz output_capacity) @export("factors") {
    if (value < 1 || value > 256) return -1;
    usz required = 0;
    usz count = 0;
    for (long divisor = 1; divisor <= value; divisor++) {
        if (value % divisor == 0) { required += decimal_length(divisor); if (count != 0) required++; count++; }
    }
    if (output == null || output_capacity < required) return -2;
    usz position = 0;
    count = 0;
    for (long divisor = 1; divisor <= value; divisor++) {
        if (value % divisor == 0) {
            if (count != 0) output[position++] = ',';
            position = append_decimal(divisor, output, position);
            count++;
        }
    }
    return (long)position;
}
