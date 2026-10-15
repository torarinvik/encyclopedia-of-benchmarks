module first_n_primes;

fn bool is_prime(long value) {
    if (value < 2) return false;
    for (long divisor = 2; divisor <= value / divisor; divisor++) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn usz decimal_length(long value) {
    usz length = 1;
    while (value >= 10) { value /= 10; length++; }
    return length;
}

fn usz required_length(long number_of_primes) {
    usz length = 0;
    usz count = 0;
    for (long value = 2; count < (usz)number_of_primes; value++) {
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

// Encode the first n primes in ascending order as comma-separated decimal bytes.
fn long first_n_primes(long number_of_primes, char* output, usz output_capacity) @export("first_n_primes") {
    if (number_of_primes < 0 || number_of_primes > 20) return -1;
    usz required = required_length(number_of_primes);
    if (output == null || output_capacity < required) return -2;
    usz position = 0;
    usz count = 0;
    for (long value = 2; count < (usz)number_of_primes; value++) {
        if (!is_prime(value)) continue;
        if (count != 0) output[position++] = ',';
        position = append_decimal(value, output, position);
        count++;
    }
    return (long)position;
}
