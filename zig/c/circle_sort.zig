fn circleSortRange(values: [*]i64, left_value: usize, right_value: usize) bool {
    if (left_value >= right_value) return false;

    var low = left_value;
    var high = right_value;
    var swapped = false;
    while (low < high) {
        if (values[low] > values[high]) {
            const temporary = values[low];
            values[low] = values[high];
            values[high] = temporary;
            swapped = true;
        }
        low += 1;
        high -= 1;
    }
    if (low == high and values[low] > values[high + 1]) {
        const temporary = values[low];
        values[low] = values[high + 1];
        values[high + 1] = temporary;
        swapped = true;
    }

    const middle = left_value + (right_value - left_value) / 2;
    const left_swapped = circleSortRange(values, left_value, middle);
    const right_swapped = circleSortRange(values, middle + 1, right_value);
    return swapped or left_swapped or right_swapped;
}

/// Recursively compares mirrored pairs until each pass makes no swaps.
export fn circle_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    while (circleSortRange(values, 0, length - 1)) {}
}
