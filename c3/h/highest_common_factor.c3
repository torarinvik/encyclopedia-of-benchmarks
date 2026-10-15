module highest_common_factor;

fn ulong highest_common_factor_impl(ulong x, ulong y) {
    if (x == 0) return y;
    if (y == 0) return x;
    if (x == y) return x;
    if (y > x) return highest_common_factor_impl(y - x, x);
    return highest_common_factor_impl(x - y, y);
}

fn long highest_common_factor(ulong x, ulong y) @export("highest_common_factor") {
    return (long)highest_common_factor_impl(x, y);
}
