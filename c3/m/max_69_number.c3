module max_69_number;

fn long max_69_number(long value) @export("max_69_number")
{
    if (value < 1 || value > 999999999999999999L) return -1L;
    long place = 1L;
    while (place <= value / 10L) place *= 10L;
    while (place > 0L) {
        long digit = (value / place) % 10L;
        if (digit == 6L) return value + 3L * place;
        if (digit != 9L) return -1L;
        place /= 10L;
    }
    return -1L;
}
