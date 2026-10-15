module count_leading_zeros;

fn long count_leading_zeros(long value) @export("count_leading_zeros")
{
    if (value < -2147483648 || value > 2147483647) return -1;
    if (value == 0) return 32;
    long mask = 2147483648;
    long count = 0;
    while ((mask & value) == 0) {
        count += 1;
        mask >>= 1;
    }
    return count;
}
