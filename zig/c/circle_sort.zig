fn circle_pass(values: []i64) bool {
    const length = values.len;
    if (length < 2) return false;
    var swapped = false;
    var left: usize = 0;
    var right = length - 1;
    while (left < right) {
        if (values[left] > values[right]) {
            const temporary = values[left];
            values[left] = values[right];
            values[right] = temporary;
            swapped = true;
        }
        left += 1;
        right -= 1;
    }
    if (length % 2 != 0 and left == right and right + 1 < length and values[right + 1] < values[right]) {
        const temporary = values[right];
        values[right] = values[right + 1];
        values[right + 1] = temporary;
        swapped = true;
    }
    const split = length / 2 + length % 2;
    const left_swapped = circle_pass(values[0..split]);
    const right_swapped = circle_pass(values[split..]);
    return swapped or left_swapped or right_swapped;
}

fn circle_sort_range(values: []i64) void {
    while (values.len > 1 and circle_pass(values)) { }
}

/// Recursive circle sort for the shared signed 64-bit benchmark contract.
export fn circle_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    circle_sort_range(values[0..length]);
}
