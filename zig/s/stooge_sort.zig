fn stooge_sort_range(values: [*]i64, low: usize, high: usize) void {
    const length = high - low;
    if (length < 2) return;
    if (values[low] > values[high - 1]) {
        const temporary = values[low];
        values[low] = values[high - 1];
        values[high - 1] = temporary;
    }
    if (length > 2) {
        const third = length / 3;
        stooge_sort_range(values, low, high - third);
        stooge_sort_range(values, low + third, high);
        stooge_sort_range(values, low, high - third);
    }
}

/// Stooge sort using half-open ranges.
export fn stooge_sort(values: [*]i64, length: usize) void {
    if (length > 1) stooge_sort_range(values, 0, length);
}
