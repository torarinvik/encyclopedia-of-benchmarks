module parity_check;

fn long parity_check(long value) @export("parity_check") {
    if (value < -2147483648L || value > 2147483647L) return -1;
    int number = (int)value;
    int parity = 0;
    while (number > 0) {
        parity ^= number & 1;
        number >>= 1;
    }
    return parity == 0 ? 1 : 0;
}
