module simple_binary_search;

fn long simple_binary_search_range(long* values, usz low, usz high, long target)
{
    if (low >= high) return 0;

    usz middle = low + (high - low) / 2;
    if (values[middle] == target) return 1;
    if (target < values[middle]) {
        return simple_binary_search_range(values, low, middle, target);
    }
    return simple_binary_search_range(values, middle + 1, high, target);
}

fn long simple_binary_search(long* values, usz length, long target) @export("simple_binary_search")
{
    return simple_binary_search_range(values, 0, length, target);
}
