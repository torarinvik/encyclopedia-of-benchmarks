module min_value;

fn long min_value(long a, long b) @export("min_value") {
    if (a < -2147483648L || a > 2147483647L || b < -2147483648L || b > 2147483647L) return -1;
    return a <= b ? a : b;
}
