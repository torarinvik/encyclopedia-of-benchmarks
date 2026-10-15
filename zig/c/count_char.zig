export fn count_char(values: [*]const i64, length: usize) i64 {
    if (length > 4096) return -1;
    const input = values[0..length];
    var count: i64 = 0;
    for (input) |code| {
        if (code < 0 or code > 127) return -1;
        if (code != 9 and code != 10 and code != 11 and code != 12 and code != 13 and code != 32) {
            count += 1;
        }
    }
    return count;
}
