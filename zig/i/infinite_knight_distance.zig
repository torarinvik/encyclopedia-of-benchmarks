const MAX_COORDINATE: i64 = 1_000_000_000;

fn solve(input: []const i64) i64 {
    if (input.len != 2) return -1;
    const dx = input[0];
    const dy = input[1];
    if (dx < -MAX_COORDINATE or dx > MAX_COORDINATE
        or dy < -MAX_COORDINATE or dy > MAX_COORDINATE) return -1;
    const abs_x = if (dx < 0) -dx else dx;
    const abs_y = if (dy < 0) -dy else dy;
    const large = @max(abs_x, abs_y);
    const small = @min(abs_x, abs_y);
    if (large == 1 and small == 0) return 3;
    if (large == 2 and small == 2) return 4;
    var distance = @divTrunc(large + 1, 2);
    const diagonal_bound = @divTrunc(large + small + 2, 3);
    if (diagonal_bound > distance) distance = diagonal_bound;
    if (@mod(large + small - distance, 2) != 0) distance += 1;
    return distance;
}

pub export fn infinite_knight_distance(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 2) return -1;
    return solve(input[0..length]);
}
