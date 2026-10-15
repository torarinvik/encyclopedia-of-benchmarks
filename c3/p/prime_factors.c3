module prime_factors;

fn usz decimal_length(long value) {
    usz length = 1;
    while (value >= 10) { value /= 10; length++; }
    return length;
}

fn usz required_length(long value) {
    usz length = 0;
    usz count = 0;
    long remaining = value;
    for (long divisor = 2; divisor <= remaining / divisor; divisor++) {
        while (remaining % divisor == 0) {
            length += decimal_length(divisor);
            if (count != 0) length++;
            count++;
            remaining /= divisor;
        }
    }
    if (remaining > 1) {
        length += decimal_length(remaining);
        if (count != 0) length++;
    }
    return length;
}

fn usz append_decimal(long value, char* output, usz position) {
    char[10] digits;
    usz count = 0;
    do { digits[count++] = (char)('0' + value % 10); value /= 10; } while (value > 0);
    while (count > 0) output[position++] = digits[--count];
    return position;
}

// Encode prime factors in ascending order, retaining multiplicity.
fn long prime_factors(long value, char* output, usz output_capacity) @export("prime_factors") {
    if (value < 1 || value > 2147483647) return -1;
    usz required = required_length(value);
    if (output == null || output_capacity < required) return -2;
    usz position = 0;
    usz count = 0;
    long remaining = value;
    for (long divisor = 2; divisor <= remaining / divisor; divisor++) {
        while (remaining % divisor == 0) {
            if (count != 0) output[position++] = ',';
            position = append_decimal(divisor, output, position);
            count++;
            remaining /= divisor;
        }
    }
    if (remaining > 1) {
        if (count != 0) output[position++] = ',';
        position = append_decimal(remaining, output, position);
    }
    return (long)position;
}
