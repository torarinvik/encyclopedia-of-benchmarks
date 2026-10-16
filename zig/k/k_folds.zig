export fn k_folds(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 2) return -1;
    const values = input;
    const sample_count = values[0];
    const fold_count = values[1];
    if (sample_count < 1 or sample_count > 12 or fold_count < 1 or fold_count > 12) return -1;
    const width = @divTrunc(sample_count + fold_count - 1, fold_count);
    var packed: u64 = @as(u64, @intCast(sample_count)) << 48;
    for (0..@intCast(sample_count)) |index| {
        const fold: u64 = @intCast(@divTrunc(@as(i64, @intCast(index)) + width, width));
        packed |= fold << @intCast(4 * index);
    }
    return @intCast(packed);
}
