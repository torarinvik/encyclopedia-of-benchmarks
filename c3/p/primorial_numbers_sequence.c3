module primorial_numbers_sequence;

fn bool is_prime(long value) {
    if (value < 2) return false;
    for (long factor = 2; factor <= value / factor; factor += 1) {
        if (value % factor == 0) return false;
    }
    return true;
}

fn long primorial_numbers_sequence(long index) @export("primorial_numbers_sequence") {
    if (index < 0 || index > 15) return -1;
    long product = 1;
    long prime_count = 0;
    for (long candidate = 2; prime_count < index; candidate += 1) {
        if (is_prime(candidate)) {
            product *= candidate;
            prime_count += 1;
        }
    }
    return product;
}
