const MAX_N: i64 = 16;
const MAX_INPUT: usize = 34;
const TABLE_SIZE: usize = 32;

fn gcdPositive(a_value: i32, b_value: i32) i32 {
    var a = a_value;
    var b = b_value;
    while (b != 0) { const remainder = @rem(a, b); a = b; b = remainder; }
    return a;
}

export fn max_points_on_a_line(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 1 or n_value > MAX_N or length != @as(usize, @intCast(1 + 2 * n_value))) return -1;
    const n: usize = @intCast(n_value);
    var x: [16]i32 = undefined;
    var y: [16]i32 = undefined;
    for (0..n) |i| {
        const xv = input[1 + 2 * i];
        const yv = input[2 + 2 * i];
        if (xv < -100 or xv > 100 or yv < -100 or yv > 100) return -1;
        x[i] = @intCast(xv); y[i] = @intCast(yv);
        for (0..i) |j| { if (x[i] == x[j] and y[i] == y[j]) return -1; }
    }
    if (n == 1) return 1;
    var answer: i64 = 2;
    for (0..n) |anchor| {
        var keys = [_]i32{-1} ** TABLE_SIZE;
        var counts = [_]i32{0} ** TABLE_SIZE;
        var best: i32 = 0;
        for (0..n) |other| {
            if (other == anchor) continue;
            var dx = x[other] - x[anchor];
            var dy = y[other] - y[anchor];
            const abs_dx: i32 = if (dx < 0) -dx else dx;
            const abs_dy: i32 = if (dy < 0) -dy else dy;
            const divisor = gcdPositive(abs_dx, abs_dy);
            dx = @divTrunc(dx, divisor);
            dy = @divTrunc(dy, divisor);
            if (dx < 0 or (dx == 0 and dy < 0)) { dx = -dx; dy = -dy; }
            const direction_key = dx * 401 + dy + 200;
            var slot: usize = @intCast(@mod(direction_key, @as(i32, @intCast(TABLE_SIZE))));
            while (keys[slot] != -1 and keys[slot] != direction_key) slot = (slot + 1) % TABLE_SIZE;
            if (keys[slot] == -1) keys[slot] = direction_key;
            counts[slot] += 1;
            best = @max(best, counts[slot]);
        }
        answer = @max(answer, @as(i64, best + 1));
    }
    return answer;
}
