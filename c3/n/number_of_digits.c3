module number_of_digits;

// Count base-10 digits in the magnitude, including for i64 minimum.
fn long number_of_digits(long value) @export("number_of_digits") {
    ulong magnitude;
    if (value < 0) { magnitude = (ulong)(-(value + 1)) + 1ul; }
    else { magnitude = (ulong)value; }
    long digits = 1;
    while (magnitude >= 10ul) {
        magnitude /= 10ul;
        digits++;
    }
    return digits;
}
