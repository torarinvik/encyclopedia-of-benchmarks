module rightmost_set_bit;

fn long rightmost_set_bit(long value) @export("rightmost_set_bit") {
    if (value <= 0 || value > 2147483647) return -1;
    uint lowest = (uint)value & (0u - (uint)value);
    long position = 1;
    while ((lowest & 1u) == 0u) {
        lowest >>= 1;
        position++;
    }
    return position;
}
