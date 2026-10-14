fn partition(values: [*]i64, low: usize, high: usize) usize {
    const pivot = values[high - 1];
    var boundary = low;
    var scan = low;
    while (scan < high - 1) : (scan += 1) {
        if (values[scan] <= pivot) {
            const temporary = values[boundary];
            values[boundary] = values[scan];
            values[scan] = temporary;
            boundary += 1;
        }
    }
    const temporary = values[boundary];
    values[boundary] = values[high - 1];
    values[high - 1] = temporary;
    return boundary;
}

fn quick_sort_range(values: [*]i64, low_value: usize, high_value: usize) void {
    var low = low_value;
    var high = high_value;
    while (high - low > 1) {
        const pivot = partition(values, low, high);
        const right_start = pivot + 1;
        if (pivot - low < high - right_start) {
            quick_sort_range(values, low, pivot);
            low = right_start;
        } else {
            quick_sort_range(values, right_start, high);
            high = pivot;
        }
    }
}

/// Lomuto quicksort; recurse into the smaller partition to bound stack depth.
export fn quick_sort(values: [*]i64, length: usize) void {
    if (length > 1) quick_sort_range(values, 0, length);
}
