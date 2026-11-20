/// Greedy minimum subfamily covering a half-open target interval.
export fn interval_cover(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > 36) return -2;
    const input = input_opt.?;
    const target_left = input[0];
    const target_right = input[1];
    const count_value = input[2];
    if (target_left < 0 or target_left > target_right or target_right > 32
        or count_value < 0 or count_value > 16) return -2;
    const count: usize = @intCast(count_value);
    if (length != 3 + 2 * count) return -2;
    for (0..count) |index| {
        const left = input[3 + 2 * index];
        const right = input[4 + 2 * index];
        if (left < 0 or left >= right or right > 32) return -2;
    }
    if (target_left == target_right) return 0;

    var frontier = target_left;
    var selected: i64 = 0;
    while (frontier < target_right) {
        var farthest = frontier;
        for (0..count) |index| {
            const left = input[3 + 2 * index];
            const right = input[4 + 2 * index];
            if (left <= frontier and right > farthest) farthest = right;
        }
        if (farthest == frontier) return -1;
        frontier = farthest;
        selected += 1;
    }
    return selected;
}
