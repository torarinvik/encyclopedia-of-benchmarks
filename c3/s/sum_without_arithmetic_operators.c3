module sum_without_arithmetic_operators;

fn uint add_recursive(uint a, uint b) {
    if (b == 0) return a;
    return add_recursive(a ^ b, (a & b) << 1);
}

fn long sum_without_arithmetic_operators(long a, long b) @export("sum_without_arithmetic_operators") {
    if (a < -2147483648 || a > 2147483647 || b < -2147483648 || b > 2147483647) return -2147483649;
    uint bits = add_recursive((uint)a, (uint)b);
    return bits <= 2147483647 ? (long)bits : (long)bits - 4294967296;
}
