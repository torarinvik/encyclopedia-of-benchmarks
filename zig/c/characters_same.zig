/// Return whether every bounded ASCII character value equals the first.
export fn characters_same(values: [*]const i64, length: usize) i64 {
    if (length > 256) return -1;
    for (0..length) |index| {
        if (values[index] < 0 or values[index] > 127) return -1;
    }
    if (length == 0) return 1;
    const first = values[0];
    for (1..length) |index| {
        if (values[index] != first) return 0;
    }
    return 1;
}
