/// Stable odd-even transposition sort for the shared sorting contract.
export fn odd_even_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    var swapped = true;
    while (swapped) {
        swapped = false;
        var index: usize = 0;
        while (index + 1 < length) : (index += 2) {
            if (values[index] > values[index + 1]) {
                const temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = true;
            }
        }
        index = 1;
        while (index + 1 < length) : (index += 2) {
            if (values[index] > values[index + 1]) {
                const temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = true;
            }
        }
    }
}
