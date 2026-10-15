module check_factorial;

fn long check_factorial(long n) @export("check_factorial") {
    if (n <= 0) { return 0; }
    long value = n;
    long divisor = 2;
    while (value % divisor == 0) {
        value /= divisor;
        divisor += 1;
    }
    return value == 1 ? 1 : 0;
}
