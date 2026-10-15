module strong_number;

fn long strong_number(long number) @export("strong_number") {
    if (number < -2147483648 || number > 2147483647) return -1;
    if (number < 0) return 0;
    long remaining = number;
    long sum = 0;
    if (remaining == 0) sum = 1;
    while (remaining > 0) {
        long digit = remaining % 10;
        long factorial = 1;
        for (long factor = 2; factor <= digit; factor++) factorial *= factor;
        sum += factorial;
        remaining /= 10;
    }
    return sum == number ? 1 : 0;
}
