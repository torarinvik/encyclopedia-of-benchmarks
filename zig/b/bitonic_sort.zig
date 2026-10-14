fn bitonic_compare(values: [*]i64, left: usize, right: usize, ascending: bool) void {
    if ((ascending and values[left] > values[right]) or (!ascending and values[left] < values[right])) {
        const temporary = values[left];
        values[left] = values[right];
        values[right] = temporary;
    }
}

fn bitonic_merge(values: [*]i64, low: usize, length: usize, ascending: bool) void {
    if (length < 2) return;
    const half = length / 2;
    for (low..(low + half)) |index| bitonic_compare(values, index, index + half, ascending);
    bitonic_merge(values, low, half, ascending);
    bitonic_merge(values, low + half, half, ascending);
}

fn bitonic_sort_range(values: [*]i64, low: usize, length: usize, ascending: bool) void {
    if (length < 2) return;
    const half = length / 2;
    bitonic_sort_range(values, low, half, true);
    bitonic_sort_range(values, low + half, half, false);
    bitonic_merge(values, low, length, ascending);
}

/// Portable bitonic sorting network for power-of-two lengths.
export fn bitonic_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    bitonic_sort_range(values, 0, length, true);
}
