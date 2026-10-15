module ackermann;

fn long ackermann_value(long m, long n) {
    if (m == 0) return n + 1;
    if (n == 0) return ackermann_value(m - 1, 1);
    return ackermann_value(m - 1, ackermann_value(m, n - 1));
}

fn long ackermann(long m, long n) @export("ackermann") {
    if (m < 0 || m > 3 || n < 0 || n > 5) return -1;
    return ackermann_value(m, n);
}
