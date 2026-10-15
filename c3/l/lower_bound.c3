module lower_bound;

fn long lower_bound_range(long* values, long target, long left, long right)
{
    if (right <= left) return left;
    long middle = (left + right) / 2;
    if (target == values[middle]) return middle;
    if (target < values[middle]) return lower_bound_range(values, target, left, middle);
    return lower_bound_range(values, target, middle + 1, right);
}

fn long lower_bound_impl(long* values, usz length, long target)
{
    if (length > 512 || target < -2147483648 || target > 2147483647) return -1;
    if (length > 0 && values == null) return -1;
    for (usz i = 0; i < length; i++) {
        if (values[i] < -2147483648 || values[i] > 2147483647) return -1;
        if (i > 0 && values[i - 1] > values[i]) return -1;
    }
    return lower_bound_range(values, target, 0, (long)length - 1);
}

fn long lower_bound(long* values, usz length, long target) @export("lower_bound")
{
    return lower_bound_impl(values, length, target);
}
