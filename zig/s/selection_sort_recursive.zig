fn minimum_index(values: []i64, start: usize, end: usize) usize {
    if (start + 1 >= end) return start;
    const minimum = minimum_index(values, start + 1, end);
    return if (values[start] < values[minimum]) start else minimum;
}

fn selection_sort_range(values: []i64, start: usize, length: usize) void {
    if (start + 1 >= length) return;
    const minimum = minimum_index(values, start, length);
    if (minimum != start) {
        const temporary = values[start];
        values[start] = values[minimum];
        values[minimum] = temporary;
    }
    selection_sort_range(values, start + 1, length);
}

/// Recursive selection sort for the shared signed 64-bit benchmark contract.
export fn selection_sort_recursive(values: [*]i64, length: usize) void {
    selection_sort_range(values[0..length], 0, length);
}
