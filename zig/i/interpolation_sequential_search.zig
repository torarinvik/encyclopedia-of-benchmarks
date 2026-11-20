const MAX_N: usize = 64;
const MIN_VALUE: i64 = -1_000_000;
const MAX_VALUE: i64 = 1_000_000;

export fn interpolation_sequential_search(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > MAX_N + 3) return -1;
    const values = input.?;
    const count_value = values[0];
    const target = values[1];
    if (count_value < 0 or count_value > MAX_N or length != @as(usize, @intCast(count_value)) + 2
        or target < MIN_VALUE or target > MAX_VALUE) return -1;
    const count: usize = @intCast(count_value);
    for (0..count) |i| {
        const value = values[i + 2];
        if (value < MIN_VALUE or value > MAX_VALUE or (i > 0 and values[i + 1] >= value)) return -1;
    }
    if (count == 0) return -1;
    const first = values[2];
    const last = values[count + 1];
    if (target < first or target > last) return -1;
    if (count == 1) return if (first == target) 0 else -1;

    const position: usize = @intCast(((target - first) * @as(i64, @intCast(count - 1))) / (last - first));
    const estimated = values[position + 2];
    if (estimated == target) return @intCast(position);
    if (estimated < target) {
        var i = position + 1;
        while (i < count) : (i += 1) {
            const value = values[i + 2];
            if (value >= target) return if (value == target) @as(i64, @intCast(i)) else -1;
        }
    } else {
        var i = position;
        while (i > 0) {
            i -= 1;
            const value = values[i + 2];
            if (value <= target) return if (value == target) @as(i64, @intCast(i)) else -1;
        }
    }
    return -1;
}
