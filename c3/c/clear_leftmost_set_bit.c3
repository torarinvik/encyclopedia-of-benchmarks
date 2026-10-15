module clear_leftmost_set_bit;

fn long clear_leftmost_set_bit(long value) @export("clear_leftmost_set_bit")
{
    if (value < 0 || value > 2147483647) return -1;
    if (value == 0) return 0;
    long temp = value;
    long position = 0;
    while (temp > 0) {
        temp >>= 1;
        position += 1;
    }
    long mask = ~(((long)1) << (position - 1));
    return value & mask;
}
