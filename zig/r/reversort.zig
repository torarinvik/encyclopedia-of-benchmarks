export fn reversort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    for (0..(length - 1)) |index| {
        var minimum = index;
        for (index + 1..length) |probe| {
            if (values[probe] < values[minimum]) minimum = probe;
        }
        var left = index;
        var right = minimum;
        while (left < right) : ({ left += 1; right -= 1; }) {
            const temporary = values[left];
            values[left] = values[right];
            values[right] = temporary;
        }
    }
}
