/// Stable bidirectional bubble sort for signed 64-bit values.
export fn cocktail_sort(values: [*]i64, length: usize) void {
    var start: usize = 0;
    var end = length;
    while (start < end) {
        var swapped = false;
        var index = start;
        while (index + 1 < end) : (index += 1) {
            if (values[index] > values[index + 1]) {
                const temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = true;
            }
        }
        if (!swapped) break;
        end -= 1;
        swapped = false;
        index = end;
        while (index > start) {
            if (values[index - 1] > values[index]) {
                const temporary = values[index - 1];
                values[index - 1] = values[index];
                values[index] = temporary;
                swapped = true;
            }
            index -= 1;
        }
        start += 1;
        if (!swapped) break;
    }
}
