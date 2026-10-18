module get_primes_between;

const usz MAX_PRIME_COUNT = 256;

fn bool is_prime_candidate(long value) {
    if (value < 2) return false;
    for (long divisor = 2; divisor <= value / divisor; divisor++) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn usz decimal_length(long value) {
    if (value >= 100) return 3;
    if (value >= 10) return 2;
    return 1;
}

fn usz write_decimal(char* output, usz offset, long value) {
    if (value >= 100) {
        output[offset++] = (char)(48 + value / 100);
        value = value % 100;
    }
    if (value >= 10) {
        output[offset++] = (char)(48 + value / 10);
        value = value % 10;
    }
    output[offset++] = (char)(48 + value);
    return offset;
}

fn long get_primes_between(long* values, usz length, char* output, usz output_capacity)
    @export("get_primes_between") {
    if (values == null || length != 2) return -1;
    long p1 = values[0];
    long p2 = values[1];
    if (p1 < 2 || p1 > 997 || p2 < 2 || p2 > 997 || p1 >= p2 ||
        !is_prime_candidate(p1) || !is_prime_candidate(p2)) return -1;

    long[MAX_PRIME_COUNT] primes;
    usz count = 0;
    for (long candidate = p1 + 1; candidate < p2; candidate++) {
        if (is_prime_candidate(candidate)) primes[count++] = candidate;
    }
    if (count == 0) return -1;

    usz required = count - 1;
    for (usz i = 0; i < count; i++) required += decimal_length(primes[i]);
    if (output == null || output_capacity < required) return -2;

    usz written = 0;
    for (usz i = 0; i < count; i++) {
        if (i != 0) output[written++] = ',';
        written = write_decimal(output, written, primes[i]);
    }
    return (long)written;
}
