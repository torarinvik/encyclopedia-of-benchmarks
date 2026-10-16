module trial_division_factorizer;

fn long trial_division_factorizer(long input) @export("trial_division_factorizer") {
    if (input < -2147483648 || input > 2147483647 || input == 0 || input == -2147483648) return -1;
    long number = input < 0 ? -input : input;
    for (long divisor = 2; divisor <= number / divisor; divisor++) {
        if (number % divisor == 0) return divisor;
    }
    return 0;
}
