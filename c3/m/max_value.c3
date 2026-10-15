module max_value;

fn long max_value(long a, long b) @export("max_value") {
    if (a < -2147483648L || a > 2147483647L || b < -2147483648L || b > 2147483647L) return -1;
    return a >= b ? a : b;
}
