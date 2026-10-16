module modular_inverse_simple;

fn ulong gcd_u64(ulong left, ulong right) {
    while (right != 0) {
        ulong remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long modular_inverse_simple(long x_input, long y_input) @export("modular_inverse_simple") {
    if (x_input < 1 || x_input > 999 || y_input < 2 || y_input > 1000) return -1;
    ulong x = (ulong)x_input, y = (ulong)y_input;
    if (gcd_u64(x, y) != 1) return -1;

    ulong auxiliary = 0, iteration = 0;
    do {
        auxiliary = y * iteration + 1;
        iteration++;
    } while (auxiliary % x != 0);
    return (long)(auxiliary / x);
}
