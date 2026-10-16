/// Go Problem17: sum byte lengths after splitting on ASCII space.
export fn word_length_sum(values: [*]const i64, length: usize) i64 {
    if (length > 4096) return -1;
    var total: i64 = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < 0 or value > 255) return -1;
        if (value != 32) total += 1;
    }
    return total;
}
