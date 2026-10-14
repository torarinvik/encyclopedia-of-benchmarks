module exponential_search;

// Local exponential search over ascending values for the shared contract.
fn long binary_search_range(long* values, usz low, usz high, long target)
{
    while (low < high)
    {
        usz middle = low + (high - low) / 2;
        long value = values[middle];
        if (value == target) return (long)middle;
        if (value < target) low = middle + 1;
        else high = middle;
    }
    return -1;
}

fn long exponential_search_impl(long* values, usz length, long target)
{
    if (length == 0) return -1;
    usz upper = 1;
    while (upper < length && values[upper] <= target)
    {
        upper = upper > length / 2 ? length : upper * 2;
    }
    return binary_search_range(values, upper / 2, upper, target);
}

// Stable C ABI entry point used by the common benchmark runner.
fn long exponential_search(long* values, usz length, long target) @export("exponential_search")
{
    return exponential_search_impl(values, length, target);
}
