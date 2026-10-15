const MAX_LENGTH: usize = 64;
const UNREACHABLE: i64 = 1_000_000_000_000;

export fn min_number_of_jumps(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 1 or length > MAX_LENGTH) return -1;
    for (0..length) |i| {
        if (values[i] < 0 or values[i] > 64) return -1;
    }
    var jumps: [MAX_LENGTH]i64 = @splat(UNREACHABLE);
    jumps[0] = 0;
    for (1..length) |i| {
        for (0..i) |j| {
            if (values[j] + @as(i64, @intCast(j)) >= @as(i64, @intCast(i)) and jumps[j] + 1 < jumps[i]) {
                jumps[i] = jumps[j] + 1;
            }
        }
    }
    return jumps[length - 1];
}
