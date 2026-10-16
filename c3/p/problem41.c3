module problem41;

const long MAX_DIGITS = 9;

fn bool is_prime(long number) {
    if (number < 2) return false;
    if (number < 4) return true;
    if (number % 2 == 0 || number % 3 == 0) return false;
    for (long divisor = 5; divisor <= number / divisor; divisor += 6) {
        if (number % divisor == 0 || number % (divisor + 2) == 0) return false;
    }
    return true;
}

fn long search(long digits, long depth, usz used, long value) {
    if (depth == digits) return is_prime(value) ? value : 0;
    long best = 0;
    for (long digit = 1; digit <= digits; digit++) {
        usz bit = (usz)1 << (usz)digit;
        if ((used & bit) != 0) continue;
        long candidate = search(digits, depth + 1, used | bit, value * 10 + digit);
        if (candidate > best) best = candidate;
    }
    return best;
}

fn long problem41(long digits) @export("problem41") {
    if (digits < 1 || digits > MAX_DIGITS) return -1;
    return search(digits, 0, 0, 0);
}
