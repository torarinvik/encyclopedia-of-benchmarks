const MAX_VALUES = 1024;

export fn cocktail_selection_sort(values: [*]i64, length: usize) void {
    if (length > MAX_VALUES) return;
    var low: usize = 0;
    var high = length;
    while (high - low > 1) {
        var minimum_index = low;
        var maximum_index = low;
        for (low + 1..high) |index| {
            if (values[index] < values[minimum_index]) minimum_index = index;
            if (values[index] > values[maximum_index]) maximum_index = index;
        }
        const minimum = values[minimum_index];
        values[minimum_index] = values[low];
        values[low] = minimum;
        if (maximum_index == low) maximum_index = minimum_index;
        const maximum = values[maximum_index];
        values[maximum_index] = values[high - 1];
        values[high - 1] = maximum;
        low += 1;
        high -= 1;
    }
}
