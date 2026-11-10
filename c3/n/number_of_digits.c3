module number_of_digits;

// Count base-10 digits in the magnitude, including for i64 minimum.
fn long number_of_digits(long value) @export("number_of_digits") {
    ulong magnitude;
    if (value < 0) { magnitude = (ulong)(-(value + 1)) + 1ul; }
    else { magnitude = (ulong)value; }
    if (magnitude < 10ul) return 1;
    long digits = 1;
    while (magnitude >= 10000ul) {
        magnitude /= 10000ul;
        digits += 4;
    }
    if (magnitude < 10ul) return digits;
    if (magnitude < 100ul) return digits + 1;
    return digits + (magnitude < 1000ul ? 2 : 3);
}
