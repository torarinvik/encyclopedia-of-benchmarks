const MAX_VALUES = 256;

fn bubble_sort_recursive_impl(values: [*]i64, length: usize) void {
    if (length <= 1) return;
    var swapped = false;
    for (0..length - 1) |index| {
        if (values[index] > values[index + 1]) {
            const temporary = values[index];
            values[index] = values[index + 1];
            values[index + 1] = temporary;
            swapped = true;
        }
    }
    if (swapped) bubble_sort_recursive_impl(values, length - 1);
}

export fn bubble_sort_recursive(values: [*]i64, length: usize) void {
    if (length <= MAX_VALUES) bubble_sort_recursive_impl(values, length);
}
