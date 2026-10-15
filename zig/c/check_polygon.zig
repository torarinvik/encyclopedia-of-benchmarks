/// Return one when positive side lengths can form a polygon, otherwise zero.
export fn check_polygon(values: [*c]const i64, length: usize, output: [*c]u8,
    output_capacity: usize) i64 {
    _ = output;
    _ = output_capacity;
    if (length < 3 or length > 256 or values == null) return -1;

    var total: i64 = 0;
    var largest: i64 = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < 1 or value > 1_000_000_000) return -1;
        total += value;
        if (value > largest) largest = value;
    }
    return if (largest < total - largest) 1 else 0;
}
