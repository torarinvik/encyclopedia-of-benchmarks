/// Return twice the statistical median using a local insertion-sorted copy.
export fn median(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 1024) return 0;
    var ordered: [1024]i64 = undefined;
    for (0..length) |index| ordered[index] = values[index];
    for (1..length) |index| {
        const value = ordered[index];
        var cursor = index;
        while (cursor > 0 and ordered[cursor - 1] > value) {
            ordered[cursor] = ordered[cursor - 1];
            cursor -= 1;
        }
        ordered[cursor] = value;
    }
    if (length % 2 != 0) return ordered[length / 2] * 2;
    return ordered[length / 2 - 1] + ordered[length / 2];
}
