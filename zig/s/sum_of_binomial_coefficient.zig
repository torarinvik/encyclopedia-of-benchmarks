/// Sum of a full binomial row, computed as 2^n.
export fn sum_of_binomial_coefficient(n: i64) i64 {
    if (n < 0 or n > 30) return -1;
    return @as(i64, 1) << @intCast(n);
}
