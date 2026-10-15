module harshad_number;

// Return 1 when n is divisible by its base-10 digit sum, else 0.
fn long harshad_number(long n) @export("harshad_number") {
    if (n <= 0 || n > 2147483647) return -1;
    long remaining = n;
    long digit_sum = 0;
    while (remaining > 0) {
        digit_sum += remaining % 10;
        remaining /= 10;
    }
    return n % digit_sum == 0 ? 1 : 0;
}
