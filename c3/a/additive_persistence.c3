module additive_persistence;

// Count repeated decimal digit-sum steps until one digit remains.
fn long additive_persistence(long input) @export("additive_persistence") {
    if (input < 0) return -1;
    long steps = 0;
    while (input >= 10) {
        long sum = 0;
        long remaining = input;
        while (remaining > 0) {
            sum += remaining % 10;
            remaining /= 10;
        }
        input = sum;
        steps++;
    }
    return steps;
}
