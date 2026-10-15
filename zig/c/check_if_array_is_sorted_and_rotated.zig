export fn check_if_array_is_sorted_and_rotated(values: [*]const i64, length: usize) i64 {
    if (length > 256) return -1;
    if (length == 0) return 1;
    var descents: usize = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < -2147483648 or value > 2147483647) return -1;
        const next = (index + 1) % length;
        if (value > values[next]) {
            descents += 1;
            if (descents > 1) return 0;
        }
    }
    return 1;
}
