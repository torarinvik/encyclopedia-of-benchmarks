fn recursive_bubble_sort_range(values: []i64) void {
    if (values.len < 2) return;
    for (0..values.len - 1) |index| {
        if (values[index] > values[index + 1]) {
            const temporary = values[index];
            values[index] = values[index + 1];
            values[index + 1] = temporary;
        }
    }
    recursive_bubble_sort_range(values[0 .. values.len - 1]);
}

/// Recursive bubble sort for the shared signed 64-bit benchmark contract.
export fn recursive_bubble_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    recursive_bubble_sort_range(values[0..length]);
}
