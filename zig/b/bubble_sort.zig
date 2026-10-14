/// Stable bubble sort for the shared mutable in-place sorting contract.
export fn bubble_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    var end_index = length;
    while (end_index > 1) {
        var swapped = false;
        var index: usize = 0;
        while (index + 1 < end_index) : (index += 1) {
            if (values[index] > values[index + 1]) {
                const temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = true;
            }
        }
        if (!swapped) break;
        end_index -= 1;
    }
}
