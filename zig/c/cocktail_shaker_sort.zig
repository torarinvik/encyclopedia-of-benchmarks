/// Stable full-range bidirectional adjacent-swap sort.
export fn cocktail_shaker_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    while (true) {
        var swapped = false;
        for (0..(length - 1)) |index| {
            if (values[index] > values[index + 1]) {
                const temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = true;
            }
        }
        if (!swapped) break;
        swapped = false;
        var index = length - 1;
        while (index > 0) {
            if (values[index - 1] > values[index]) {
                const temporary = values[index - 1];
                values[index - 1] = values[index];
                values[index] = temporary;
                swapped = true;
            }
            index -= 1;
        }
        if (!swapped) break;
    }
}
