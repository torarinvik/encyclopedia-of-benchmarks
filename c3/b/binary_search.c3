module binary_search;

// Local ascending-array binary search for the shared benchmark contract.
fn long binary_search_impl(long* values, usz length, long target)
{
    usz low = 0;
    usz high = length;

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

// Stable C ABI entry point used by the common benchmark runner.
fn long binary_search(long* values, usz length, long target) @export("binary_search")
{
    return binary_search_impl(values, length, target);
}
