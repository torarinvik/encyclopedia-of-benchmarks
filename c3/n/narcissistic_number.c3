module narcissistic_number;

// Enumerate narcissistic numbers below limit, memoizing digit powers.
fn long narcissistic_number(long limit, char* output, usz output_capacity) @export("narcissistic_number") {
    if (limit > 100000) return -1;
    if (limit <= 0) return 0;
    long numbers[32];
    long powers[60];
    bool cached[60];
    for (usz key = 0; key < 60; key++) cached[key] = false;
    usz count = 0;
    for (long number = 0; number < limit; number++) {
        usz digits = 1;
        for (long remaining = number; remaining >= 10; remaining /= 10) digits++;
        long sum = 0;
        for (long remaining = number; remaining > 0; remaining /= 10) {
            usz digit = (usz)(remaining % 10);
            usz key = digits * 10 + digit;
            if (!cached[key]) {
                long power = 1;
                for (usz exponent = 0; exponent < digits; exponent++) power *= (long)digit;
                powers[key] = power;
                cached[key] = true;
            }
            sum += powers[key];
        }
        if (sum == number) {
            if (count == 32) return -1;
            numbers[count++] = number;
        }
    }
    usz required = count * 8;
    if (required == 0) return 0;
    if (output == null || output_capacity < required) return -2;
    for (usz item = 0; item < count; item++) {
        ulong value = (ulong)numbers[item];
        for (usz byte = 0; byte < 8; byte++) {
            usz shift = (7 - byte) * 8;
            output[item * 8 + byte] = (char)(value >> shift);
        }
    }
    return (long)required;
}
