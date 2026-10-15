module number_persistence;

// Multiplicative persistence for nonnegative Java int inputs.
fn long number_persistence(long input) @export("number_persistence") {
    if (input < 0 || input > 2147483647) return -1;
    long steps = 0;
    while (input >= 10) {
        long product = 1;
        long remaining = input;
        while (remaining > 0) {
            product *= remaining % 10;
            remaining /= 10;
        }
        input = product;
        steps++;
    }
    return steps;
}
