/// Compute a bounded single-heap subtraction game's Sprague-Grundy number.
fn calculate_grundy(position: usize, memo: *[65]i64, moves: []const i64) i64 {
    if (memo[position] != -1) return memo[position];
    if (position == 0) {
        memo[0] = 0;
        return 0;
    }

    var reachable = [_]bool{false} ** 33;
    for (moves) |move_size| {
        const move = @as(usize, @intCast(move_size));
        if (move <= position) {
            const child = calculate_grundy(position - move, memo, moves);
            reachable[@intCast(child)] = true;
        }
    }
    var mex: usize = 0;
    while (mex <= 32 and reachable[mex]) : (mex += 1) {}
    memo[position] = @intCast(mex);
    return @intCast(mex);
}

pub export fn sprague_grundy_theorem(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 34) return -1;
    const position_value = values[0];
    const move_count_value = values[1];
    if (position_value < 0 or position_value > 64 or move_count_value < 0 or move_count_value > 32) return -1;
    const move_count: usize = @intCast(move_count_value);
    if (length != 2 + move_count) return -1;

    var moves: [32]i64 = undefined;
    for (0..move_count) |index| {
        const move = values[2 + index];
        if (move < 1 or move > 32) return -1;
        moves[index] = move;
    }
    var memo = [_]i64{-1} ** 65;
    return calculate_grundy(@intCast(position_value), &memo, moves[0..move_count]);
}
