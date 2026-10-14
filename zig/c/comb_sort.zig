fn shrink_gap(gap: usize) usize {
    return (gap / 13) * 10 + ((gap % 13) * 10) / 13;
}

/// Comb sort with a rational 10/13 gap shrink factor.
export fn comb_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    var gap = length;
    var swapped = true;
    while (gap > 1 or swapped) {
        gap = @max(shrink_gap(gap), 1);
        swapped = false;
        var index: usize = 0;
        while (index < length - gap) : (index += 1) {
            if (values[index] > values[index + gap]) {
                const temporary = values[index];
                values[index] = values[index + gap];
                values[index + gap] = temporary;
                swapped = true;
            }
        }
    }
}
