module problem40;

fn long digit_at_position(long position) {
    long digits = 1;
    long block_count = 9;
    long first_number = 1;
    while (position > digits * block_count) {
        position -= digits * block_count;
        digits++;
        block_count *= 10;
        first_number *= 10;
    }
    long number = first_number + (position - 1) / digits;
    long offset = (position - 1) % digits;
    long divisor = 1;
    for (long power = 0; power < digits - offset - 1; power++) divisor *= 10;
    return (number / divisor) % 10;
}

fn long problem40(long ignored) @export("problem40") {
    if (ignored != 0) return -1;
    return digit_at_position(1) * digit_at_position(10) * digit_at_position(100) *
           digit_at_position(1000) * digit_at_position(10000) *
           digit_at_position(100000) * digit_at_position(1000000);
}
