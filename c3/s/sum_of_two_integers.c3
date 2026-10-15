module sum_of_two_integers;

fn long bitwise_add(long a, long b) {
    ulong left = (ulong)a, right = (ulong)b;
    while (right != 0) {
        ulong partial = left ^ right;
        right = (left & right) << 1;
        left = partial;
    }
    if (left <= 0x7fffffffffffffffUL) return (long)left;
    return -1 - (long)(~left);
}

fn long sum_of_two_integers(long* values, usz length) @export("sum_of_two_integers") {
    if (values == null || length != 2 || values[0] < -2147483648L || values[0] > 2147483647L ||
        values[1] < -2147483648L || values[1] > 2147483647L) return -1;
    return bitwise_add(values[0], values[1]);
}
