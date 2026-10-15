export fn min_value(a: i64, b: i64) i64 {
    if (a < -2147483648 or a > 2147483647 or b < -2147483648 or b > 2147483647) return -1;
    return if (a <= b) a else b;
}
