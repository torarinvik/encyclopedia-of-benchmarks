module count_set_bits;

const long MAX_INPUT = 67108863L;

fn int highest_power_position(long value) {
    int position = 0;
    long power = 1L;
    while (power <= value / 2L) {
        power *= 2L;
        position++;
    }
    return position;
}

fn long count_set_bits_recursive(long value) {
    if (value == 0L) return 0L;
    int position = highest_power_position(value);
    long power = 1L << position;
    long bits_at_position = position == 0 ? 0L : (long)position * (power >> 1);
    long remaining_numbers = value - power + 1L;
    return bits_at_position + remaining_numbers + count_set_bits_recursive(value - power);
}

// Total set bits in every integer from 1 through value, inclusive.
fn long count_set_bits(long value) @export("count_set_bits") {
    if (value < 0L || value > MAX_INPUT) return -1L;
    return count_set_bits_recursive(value);
}
