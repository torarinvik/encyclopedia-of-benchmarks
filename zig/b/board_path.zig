export fn board_path(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 2) return -1;
    const start_value = input[0];
    const end_value = input[1];
    if (start_value < 0 or end_value < 0 or start_value > 30 or end_value > 30 or start_value > end_value) return -1;
    const start: usize = @intCast(start_value);
    const end: usize = @intCast(end_value);
    var ways = [_]i64{0} ** 31;
    ways[end] = 1;
    var i = end;
    while (i > start) {
        i -= 1;
        var die: usize = 1;
        while (die <= 6 and i + die <= end) : (die += 1) ways[i] += ways[i + die];
    }
    return ways[start];
}
