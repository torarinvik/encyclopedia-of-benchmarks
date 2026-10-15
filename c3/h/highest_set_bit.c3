module highest_set_bit;

fn long highest_set_bit(long value) @export("highest_set_bit") {
    if (value <= 0) return -1;
    long position = -1;
    while (value > 0) {
        position++;
        value >>= 1;
    }
    return position;
}
