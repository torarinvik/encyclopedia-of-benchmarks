const MAX_EGGS: usize = 32;
const MAX_MOVES: usize = 32;

fn solve(input: []const i64) i64 {
    if (input.len != 2) return -1;
    const eggs_raw = input[0];
    const moves_raw = input[1];
    if (eggs_raw < 0 or eggs_raw > MAX_EGGS or moves_raw < 0 or moves_raw > MAX_MOVES) return -1;
    const eggs: usize = @intCast(eggs_raw);
    const moves: usize = @intCast(moves_raw);
    var covered: [MAX_EGGS + 1]i64 = @splat(0);
    for (0..moves) |_| {
        var egg = eggs;
        while (egg > 0) {
            covered[egg] += covered[egg - 1] + 1;
            egg -= 1;
        }
    }
    return covered[eggs];
}

pub export fn egg_drop_max_floors_by_moves(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 2) return -1;
    return solve(input[0..length]);
}
