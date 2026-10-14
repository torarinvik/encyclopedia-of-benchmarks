module insertion_sort_recursive;

// Stable recursive insertion sort over signed 64-bit values.
fn void insertion_sort_prefix(long* values, usz length) {
    if (length <= 1) return;
    insertion_sort_prefix(values, length - 1);
    long key = values[length - 1];
    usz position = length - 1;
    while (position > 0 && values[position - 1] > key) {
        values[position] = values[position - 1];
        position--;
    }
    values[position] = key;
}

fn void insertion_sort_recursive(long* values, usz length) @export("insertion_sort_recursive") {
    insertion_sort_prefix(values, length);
}
