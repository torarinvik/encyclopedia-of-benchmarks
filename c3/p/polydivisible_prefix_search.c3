module polydivisible_prefix_search;

fn long extend_prefix(long prefix, long digits, long base, long max_digits) {
    long count = 1;
    if (digits == max_digits) return count;
    long next_length = digits + 1;
    for (long digit = 0; digit < base; digit++) {
        long candidate = prefix * base + digit;
        if (candidate % next_length == 0)
            count += extend_prefix(candidate, next_length, base, max_digits);
    }
    return count;
}

fn long polydivisible_prefix_search(long* input, usz length) @export("polydivisible_prefix_search") {
    if (input == null || length != 2) return -1;
    long base = input[0];
    long max_digits = input[1];
    if (base < 2 || base > 10 || max_digits < 1 || max_digits > 6) return -1;
    long count = 0;
    for (long first_digit = 1; first_digit < base; first_digit++)
        count += extend_prefix(first_digit, 1, base, max_digits);
    return count;
}
