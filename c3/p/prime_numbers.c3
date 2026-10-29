module prime_numbers;

fn bool is_prime(long value) {
    if (value < 2) return false;
    long divisor = 2;
    long quotient = value / divisor;
    while (divisor <= quotient) {
        if (value - quotient * divisor == 0) return false;
        divisor++;
        quotient = value / divisor;
    }
    return true;
}

fn usz decimal_length(long value) {
    usz length = 1;
    while (value >= 10) { value /= 10; length++; }
    return length;
}

fn usz required_length(long limit) {
    usz length = 0;
    usz count = 0;
    for (long value = 2; value <= limit; value++) {
        if (!is_prime(value)) continue;
        length += decimal_length(value);
        if (count != 0) length++;
        count++;
    }
    return length;
}

fn usz append_decimal(long value, char* output, usz position) {
    char[3] digits;
    usz count = 0;
    do { digits[count++] = (char)('0' + value % 10); value /= 10; } while (value > 0);
    while (count > 0) output[position++] = digits[--count];
    return position;
}

// Encode all primes through an inclusive limit as comma-separated decimal bytes.
fn long prime_numbers(long limit, char* output, usz output_capacity) @export("prime_numbers") {
    if (limit < 0 || limit > 80) return -1;
    usz required = required_length(limit);
    if (output == null || output_capacity < required) return -2;
    usz position = 0;
    usz count = 0;
    for (long value = 2; value <= limit; value++) {
        if (!is_prime(value)) continue;
        if (count != 0) output[position++] = ',';
        position = append_decimal(value, output, position);
        count++;
    }
    return (long)position;
}
