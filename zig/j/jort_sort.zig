const MAX_LENGTH: usize = 64;

export fn jort_sort(values: [*c]const i64, length: usize) i64 {
    if (length == 0) return 1;
    if (values == null or length > MAX_LENGTH) return -1;
    var copy: [MAX_LENGTH]i64 = @splat(0);
    for (0..length) |i| copy[i] = values[i];
    for (2..length) |i| {
        const key = copy[i];
        var position = i;
        while (position > 1 and copy[position - 1] > key) {
            copy[position] = copy[position - 1];
            position -= 1;
        }
        copy[position] = key;
    }
    for (0..length) |i| if (copy[i] != values[i]) return 0;
    return 1;
}
