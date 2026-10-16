module upper_bound;

fn long upper_bound_range(long* values, long target, long left, long right)
{
    if (right <= left) return left;
    long middle = (left + right) / 2;
    if (target < values[middle + 1]) return upper_bound_range(values, target, left, middle);
    return upper_bound_range(values, target, middle + 1, right);
}

fn long upper_bound_impl(long* values, usz length)
{
    if (values == null || length == 0 || length > 513) return -1;
    long target = values[0];
    if (target < -2147483648 || target > 2147483647) return -1;
    usz array_length = length - 1;
    for (usz i = 0; i < array_length; i++) {
        long value = values[i + 1];
        if (value < -2147483648 || value > 2147483647) return -1;
        if (i != 0 && values[i] > value) return -1;
    }
    return upper_bound_range(values, target, 0, (long)array_length - 1);
}

fn long upper_bound(long* values, usz length) @export("upper_bound")
{
    return upper_bound_impl(values, length);
}
