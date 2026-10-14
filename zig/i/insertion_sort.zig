/// Stable insertion sort for the shared mutable in-place sorting contract.
export fn insertion_sort(values: [*]i64, length: usize) void {
    var index: usize = 1;
    while (index < length) : (index += 1) {
        const key = values[index];
        var position = index;
        while (position > 0 and values[position - 1] > key) : (position -= 1) {
            values[position] = values[position - 1];
        }
        values[position] = key;
    }
}
