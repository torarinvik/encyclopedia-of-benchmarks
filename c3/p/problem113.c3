// Count non-bouncy positive integers with at most the requested digits.
module problem113;

const long MAX_DIGITS = 100;

fn long choose_integer(long n, long r) {
    long result = 1;
    for (long i = 1; i <= r; i++) result = result * (n + 1 - i) / i;
    return result;
}

fn long non_bouncy_exact(long digits) {
    return choose_integer(8 + digits, digits) + choose_integer(9 + digits, digits) - 10;
}

fn long problem113(long num_digits) @export("problem113") {
    if (num_digits > MAX_DIGITS) return -1;
    long total = 0;
    for (long digits = 1; digits <= num_digits; digits++) total += non_bouncy_exact(digits);
    return total;
}
