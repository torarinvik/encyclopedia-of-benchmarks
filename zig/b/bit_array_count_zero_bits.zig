export fn bit_array_count_zero_bits(values: [*]const i64, length: usize) i64 {
    if (length > 4096) return -1;
    var zero_count: i64 = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value != 0 and value != 1) return -1;
        if (value == 0) zero_count += 1;
    }
    return zero_count;
}
