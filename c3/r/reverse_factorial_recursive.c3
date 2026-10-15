module reverse_factorial_recursive;

fn long reverse_factorial_recursive_impl(long value, long divisor) {
    if (value == 1) return divisor == 1 ? 1 : divisor - 1;
    if (value % divisor != 0) return -1;
    return reverse_factorial_recursive_impl(value / divisor, divisor + 1);
}

fn long reverse_factorial_recursive(long value) @export("reverse_factorial_recursive") {
    if (value < 1) return -1;
    return reverse_factorial_recursive_impl(value, 1);
}
