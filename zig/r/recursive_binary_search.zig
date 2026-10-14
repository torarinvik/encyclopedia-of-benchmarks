fn recursive_binary_search_range(values: []const i64, low: usize, high: usize, target: i64) i64 {
    if (low >= high) return -1;

    const middle = low + (high - low) / 2;
    if (values[middle] == target) return @intCast(middle);
    if (target < values[middle]) {
        return recursive_binary_search_range(values, low, middle, target);
    }
    return recursive_binary_search_range(values, middle + 1, high, target);
}

/// Recursive binary search for the shared C ABI benchmark contract.
export fn recursive_binary_search(values: [*]const i64, length: usize, target: i64) i64 {
    return recursive_binary_search_range(values[0..length], 0, length, target);
}
