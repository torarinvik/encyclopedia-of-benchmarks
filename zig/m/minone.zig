const MAX_LENGTH: usize = 64;
const MIN_VALUE: i64 = -1_000_000;
const MAX_VALUE: i64 = 1_000_000;

export fn minone(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_LENGTH) return -1;
    const values = input.?;
    var total: i64 = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < MIN_VALUE or value > MAX_VALUE) return -1;
        total += value * value;
    }
    return total;
}
