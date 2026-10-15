module clear_lowest_set_bit;

fn long clear_lowest_set_bit(long value) @export("clear_lowest_set_bit")
{
    if (value < 0 || value > 2147483647) return -1;
    return value & (value - 1);
}
