module proth_number;

// Preserve the source's factor-of-two reduction for Proth membership.
fn long is_proth_number(long input) @export("is_proth_number")
{
    if (input <= 0) return -1;
    if (input == 1) return 0;

    long remainder = input - 1;
    uint exponent = 0;
    while (remainder % 2 == 0) {
        ++exponent;
        remainder /= 2;
    }
    return remainder < (1L << exponent) ? 1 : 0;
}
