module problem10_ruby_prefix;

fn bool is_prime_value(long number) {
    if (number > 1 && number < 4) return true;
    if (number < 2 || number % 2 == 0 || number % 3 == 0) return false;
    for (long divisor = 5; divisor * divisor <= number; divisor += 6) {
        if (number % divisor == 0 || number % (divisor + 2) == 0) return false;
    }
    return true;
}

// Preserve Ruby's seed of 1 and strict cumulative-total boundary.
fn long problem10_ruby_prefix(long max_total) @export("problem10_ruby_prefix") {
    if (max_total < 0 || max_total > 2000000) return -1;
    long sum = 1, value = 1;
    for (long number = 2; number < max_total && value < max_total; number++) {
        if (is_prime_value(number)) {
            value += number;
            if (value < max_total) sum = value;
        }
    }
    return sum;
}
