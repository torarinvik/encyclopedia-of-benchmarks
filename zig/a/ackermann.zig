fn ackermannValue(m: i64, n: i64) i64 {
    if (m == 0) return n + 1;
    if (n == 0) return ackermannValue(m - 1, 1);
    return ackermannValue(m - 1, ackermannValue(m, n - 1));
}

/// Bounded recursive Ackermann function A(m, n).
export fn ackermann(m: i64, n: i64) i64 {
    if (m < 0 or m > 3 or n < 0 or n > 8) return -1;
    return ackermannValue(m, n);
}
