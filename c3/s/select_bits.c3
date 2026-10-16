module select_bits;

fn long select_bits(long* values, usz length) @export("select_bits") {
    if (values == null || length < 1 || length > 3) return -1;

    long number = values[0];
    if (number < 0 || number > 9007199254740991) return -1;

    long first = 1;
    long last = 53;
    if (length >= 2) first = values[1];
    if (length >= 3) last = values[2];
    if (first < 1 || first > 53 || last < 1 || last > 53) return -1;

    long modulus = 1L << last;
    return (number % modulus) >> (first - 1);
}
