/// Stable recursive insertion sort over signed 64-bit values.
fn insertion_sort_prefix(values: []i64) void {
    if (values.len <= 1) return;
    insertion_sort_prefix(values[0 .. values.len - 1]);
    const key = values[values.len - 1];
    var position = values.len - 1;
    while (position > 0 and values[position - 1] > key) {
        values[position] = values[position - 1];
        position -= 1;
    }
    values[position] = key;
}

export fn insertion_sort_recursive(values: [*]i64, length: usize) void {
    insertion_sort_prefix(values[0..length]);
}
