module maximum_subarray;

// Kadane's maximum nonempty contiguous-subarray sum.
fn long maximum_subarray(long* values, usz length) @export("maximum_subarray")
{
    if (length == 0 || length > 1024) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < -2147483648 || values[index] > 2147483647) return -1;
    }
    long current = values[0];
    long best = current;
    for (usz index = 1; index < length; index++) {
        current = current > 0 ? current + values[index] : values[index];
        if (current > best) best = current;
    }
    return best;
}
