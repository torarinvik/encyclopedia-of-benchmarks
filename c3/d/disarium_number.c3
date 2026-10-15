module disarium_number;

fn long disarium_number(long number) @export("disarium_number") {
    if (number < 1 || number > 99999999) return -1;
    long digits = 0;
    for (long remaining = number; remaining > 0; remaining /= 10) digits++;
    long position = digits;
    long remaining = number;
    long sum = 0;
    while (remaining > 0) {
        long digit = remaining % 10;
        long power = 1;
        for (long exponent = 0; exponent < position; exponent++) power *= digit;
        sum += power;
        position--;
        remaining /= 10;
    }
    return sum == number ? 1 : 0;
}
