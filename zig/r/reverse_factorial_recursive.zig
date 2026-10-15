const INVALID_RESULT: i64 = -1;

fn reverse_factorial_recursive_impl(value: i64, divisor: i64) i64 {
    if (value == 1) return if (divisor == 1) 1 else divisor - 1;
    if (@rem(value, divisor) != 0) return INVALID_RESULT;
    return reverse_factorial_recursive_impl(@divTrunc(value, divisor), divisor + 1);
}

export fn reverse_factorial_recursive(value: i64) i64 {
    if (value < 1) return INVALID_RESULT;
    return reverse_factorial_recursive_impl(value, 1);
}
