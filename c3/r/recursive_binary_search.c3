module recursive_binary_search;

fn long recursive_binary_search_range(long* values, usz low, usz high, long target)
{
    if (low >= high) return -1;

    usz middle = low + (high - low) / 2;
    if (values[middle] == target) return (long)middle;
    if (target < values[middle]) {
        return recursive_binary_search_range(values, low, middle, target);
    }
    return recursive_binary_search_range(values, middle + 1, high, target);
}

fn long recursive_binary_search(long* values, usz length, long target) @export("recursive_binary_search")
{
    return recursive_binary_search_range(values, 0, length, target);
}
