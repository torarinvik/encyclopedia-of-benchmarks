module perfect_totient_number;

fn long totient(long value) {
    long result = value;
    long remaining = value;
    for (long factor = 2; factor <= remaining / factor; factor++) {
        if (remaining % factor == 0) {
            while (remaining % factor == 0) remaining /= factor;
            result -= result / factor;
        }
    }
    if (remaining > 1) result -= result / remaining;
    return result;
}

fn long perfect_totient_number(long n) @export("perfect_totient_number") {
    if (n < 3 || n > 65535) return -1;
    long value = n;
    long sum = 0;
    while (value > 1) {
        value = totient(value);
        sum += value;
    }
    return sum == n ? 1 : 0;
}
