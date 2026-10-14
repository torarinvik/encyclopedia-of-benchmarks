/// In-place selection sort for the shared sorting contract.
export fn selection_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    for (0..(length - 1)) |index| {
        var minimum = index;
        for (index + 1..length) |probe| {
            if (values[probe] < values[minimum]) minimum = probe;
        }
        if (minimum != index) {
            const temporary = values[index];
            values[index] = values[minimum];
            values[minimum] = temporary;
        }
    }
}
